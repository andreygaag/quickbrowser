#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/QuickBrowser/QuickBrowser/App/Info.plist"
CASK_FILE="$ROOT_DIR/Casks/quickbrowser.rb"
WORKFLOW_FILE="release.yml"
TAP_NAME="andreygaag/quickbrowser"
TAP_REPO="$(brew --repository "$TAP_NAME")"
TAP_CASK_FILE="$TAP_REPO/Casks/quickbrowser.rb"

VERSION="${1:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")}"
TAG="v$VERSION"
ZIP_NAME="QuickBrowser-$VERSION.zip"
SHA_NAME="$ZIP_NAME.sha256"
COMMIT_AND_PUSH="${COMMIT_AND_PUSH:-0}"

cd "$ROOT_DIR"

require_clean_repo() {
  local repo="$1"
  local name="$2"

  if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "$name has uncommitted changes. Commit or stash them first:" >&2
    git -C "$repo" status --short >&2
    exit 1
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd brew
require_cmd gh
require_cmd git
require_cmd rg
require_cmd ruby

require_clean_repo "$ROOT_DIR" "quickbrowser repo"
require_clean_repo "$TAP_REPO" "homebrew tap repo"

plist_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
if [ "$plist_version" != "$VERSION" ]; then
  echo "Info.plist version is $plist_version, but requested release is $VERSION" >&2
  exit 1
fi

if ! rg -q "\\*\\*v$VERSION\\*\\*" "$ROOT_DIR/README.md"; then
  echo "README.md does not mention **v$VERSION** in the Version section." >&2
  exit 1
fi

if ! git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Pushing existing local tag $TAG"
    git push origin "$TAG"
  else
    echo "Creating and pushing tag $TAG"
    git tag "$TAG"
    git push origin "$TAG"
  fi
  run_event="push"
  run_branch="$TAG"
else
  echo "Remote tag $TAG already exists"
  echo "Starting release workflow for existing $TAG"
  gh workflow run "$WORKFLOW_FILE" -f "release_tag=$TAG"
  run_event="workflow_dispatch"
  run_branch="main"
fi

echo "Waiting for workflow to appear"
sleep 10
run_id="$(gh run list \
  --workflow="$WORKFLOW_FILE" \
  --limit 20 \
  --json databaseId,event,headBranch \
  --jq "map(select(.event == \"$run_event\" and .headBranch == \"$run_branch\")) | .[0].databaseId")"
if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
  echo "Could not find workflow_dispatch run for $WORKFLOW_FILE" >&2
  exit 1
fi

echo "Watching run $run_id"
gh run watch "$run_id" --exit-status

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading $SHA_NAME from GitHub release $TAG"
gh release download "$TAG" --pattern "$SHA_NAME" --dir "$tmp_dir" --clobber
sha256="$(awk '{print $1}' "$tmp_dir/$SHA_NAME")"

if ! [[ "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Invalid sha256 in $SHA_NAME: $sha256" >&2
  exit 1
fi

echo "Updating cask version and sha256"
ruby -0777 -i -pe "gsub(/version \"[^\"]+\"/, 'version \"$VERSION\"'); gsub(/sha256 \"[0-9a-f]{64}\"/, 'sha256 \"$sha256\"')" "$CASK_FILE"
ruby -c "$CASK_FILE"

mkdir -p "$(dirname "$TAP_CASK_FILE")"
cp "$CASK_FILE" "$TAP_CASK_FILE"

echo "Validating tap cask"
brew style --cask "$TAP_CASK_FILE"
brew audit --cask quickbrowser

echo "Cask updated with sha256 $sha256"

if [ "$COMMIT_AND_PUSH" = "1" ]; then
  git add "$CASK_FILE"
  git commit -m "Update QuickBrowser cask to $VERSION"
  git push origin main

  git -C "$TAP_REPO" add Casks/quickbrowser.rb
  git -C "$TAP_REPO" commit -m "Update QuickBrowser to $VERSION"
  git -C "$TAP_REPO" push origin main
else
  echo
  echo "Review and commit:"
  echo "  git add Casks/quickbrowser.rb && git commit -m 'Update QuickBrowser cask to $VERSION' && git push origin main"
  echo "  cd '$TAP_REPO' && git add Casks/quickbrowser.rb && git commit -m 'Update QuickBrowser to $VERSION' && git push origin main"
  echo
  echo "Set COMMIT_AND_PUSH=1 to let this script commit and push both repositories."
fi
