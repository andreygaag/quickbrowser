

# QuickBrowser

Un selector de navegadores minimalista para macOS. Intercepta enlaces http/https y los abre en un navegador elegido o los encamina automáticamente según patrones de URL.

<p align="center">
  <img src="screenshots/picker.png" alt="Browser picker overlay" width="380"><br>
  <sub>Superposición del selector de navegadores</sub>
</p>

## Características

- **Superposición del selector** — diseño pensado para el teclado, elige un navegador con las teclas `1`–`9`
- **Encaminamiento basado en patrones** — las URLs que coinciden con un patrón se abren en el navegador asignado sin pedir confirmación
- **Aprendizaje automático** — después de elegir el mismo navegador para un dominio 5 veces, QuickBrowser te ofrece recordar la elección (o la guarda silenciosamente si `autolearn=true`)
- **Estadísticas de uso** — consulta la frecuencia de uso de cada navegador (manual vs. automático)
- **Editor de configuración en SwiftUI** — gestiona navegadores y patrones desde la barra de menú
- **Cero dependencias** — un único binario pequeño en Swift

## Requisitos del sistema

- **macOS 13.0 (Ventura)** o posterior
- **Apple Silicon o Intel** — binario universal
- **~2 MB** de espacio en disco
- **Sin dependencias externas**

## Comparación

QuickBrowser es intencionadamente específico: se centra en el encaminamiento rápido de enlaces http/https con una aplicación nativa minúscula, configuración editable y automatización que reduce las elecciones repetidas con el tiempo.

- **Pequeña y nativa** — una aplicación en Swift sin runtime de Electron ni dependencias incorporadas
- **Configuración que es tuya** — reglas en texto plano fáciles de comparar, buscar, respaldar o controlar mediante versiones
- **Aprende tus hábitos** — las elecciones repetidas de dominio pueden convertirse automáticamente en reglas de encaminamiento
- **Uso transparente** — las estadísticas integradas muestran qué navegadores se usan manualmente frente a automáticamente
- **Gratuita y de código abierto** — con licencia MIT, fácil de inspeccionar o modificar

| | QuickBrowser | [Browserosaurus](https://github.com/will-stone/browserosaurus) | [OpenIn](https://loshadki.app/openin4/) | [Choosy](https://choosy.app/) |
|---|---|---|---|---|
| **Licencia** | **MIT** | MIT (archivado) | Propietaria | Propietaria |
| **Precio** | **Gratuita** | Gratuita | $9.99 / Setapp | $10 pago único |
| **Mantenida** | **Sí** | No (archivada en 2025) | Sí | Sí |
| **Tecnología** | **Swift nativo** | Electron | Nativa | Nativa |
| **Tamaño de la app** | **~2 MB** | ~150 MB | — | — |
| **Notarizada** | No | Sí | Sí | Sí |
| **Configuración** | **Texto plano + GUI** | GUI | GUI | GUI |
| **Reglas de patrones URL** | Sí | Sí | Sí | Sí (avanzadas) |
| **Aprendizaje automático** | **Sí** | No | No | No |
| **Reglas por app de origen** | No | No | Sí | Sí |
| **Perfiles de navegador** | No | No | Sí | Sí |
| **Reglas por hora del día** | No | No | No | Sí |
| **mailto / archivos** | No | No | Sí | No |
| **Estadísticas de uso** | **Sí** | No | No | No |
| **Selector por teclado (1-9)** | Sí | Sí | Sí | Sí |

QuickBrowser es la mejor opción cuando buscas un encaminador de navegador predeterminado ligero y auditable que se mantenga al margen después de aprender tus dominios habituales. Si necesitas reglas por aplicación de origen, perfiles de navegador o encaminamiento de mailto/archivos, OpenIn o Choosy se ajustarán mejor.

## Instalación

### Opción A — Homebrew

QuickBrowser se puede instalar desde el tap de Homebrew:

```bash
brew tap andreygaag/quickbrowser
brew install --cask quickbrowser
```

QuickBrowser aún no está notarizada. Si macOS bloquea el primer lanzamiento con "Apple could not verify QuickBrowser.app is free of malware", permítelo una vez:

```bash
xattr -dr com.apple.quarantine /Applications/QuickBrowser.app
open /Applications/QuickBrowser.app
```

También puedes permitirlo desde **Ajustes del Sistema** → **Privacidad y Seguridad** → **Abrir de todos modos**.

Luego, establece QuickBrowser como navegador predeterminado:

1. Abre **Ajustes del Sistema** → **Escritorio y Dock**
2. Desplázate hasta **Navegador web predeterminado**
3. Selecciona **QuickBrowser**

Para desinstalar:

```bash
brew uninstall --cask quickbrowser
```

### Opción B — Compilar manualmente

#### 1. Compilación

Abre el proyecto en Xcode:

```bash
open QuickBrowser/QuickBrowser.xcodeproj
```

Selecciona el esquema **QuickBrowser** con **My Mac** como destino, luego `Producto` → `Compilar` (⌘B), o compila un artefacto de Release desde la terminal:

```bash
cd QuickBrowser
xcodebuild -project QuickBrowser.xcodeproj \
           -scheme QuickBrowser \
           -configuration Release \
           clean build
```

La compilación de Release se coloca en:

```
~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Release/QuickBrowser.app
```

#### 2. Copiar a Aplicaciones

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Release/QuickBrowser.app \
      /Applications/
```

O arrastra `QuickBrowser.app` manualmente a `/Applications`. La instalación en `/Applications` es obligatoria; macOS solo registra manejadores de URL para aplicaciones colocadas allí.

#### 3. Establecer como navegador predeterminado

**Opción A — Ajustes del Sistema (recomendada)**

1. Abre **Ajustes del Sistema** → **Escritorio y Dock**
2. Desplázate hasta **Navegador web predeterminado**
3. Selecciona **QuickBrowser**

**Opción B — Lanzar una vez**

```bash
open /Applications/QuickBrowser.app
```

macOS lo registrará como un manejador de URL. Luego establécelo como predeterminado en Ajustes del Sistema.

#### 4. Verificar

```bash
open -a /Applications/QuickBrowser.app "https://github.com"
```

Se debería abrir el navegador configurado (o la superposición del selector si no hay ningún patrón que coincida).

## Configuración

Crea `~/.config/quickbrowser`:

```
# Settings
autolearn=true

# Browsers — format: key=path
1=/Applications/Safari.app
2=/Applications/Firefox.app
3=/Applications/Google Chrome.app

# Patterns — format: pattern browser_key
github.com 2
openai.com 1
stackoverflow 2
```

También puedes editar la configuración desde la barra de menú: haz clic en el icono del globo → **Editar configuración**.

### Reglas de configuración

- Las líneas que comienzan con `#` son comentarios
- Las líneas vacías se ignoran
- `autolearn=true` guarda los patrones aprendidos silenciosamente; de lo contrario, QuickBrowser solicita confirmación
- Las claves de los navegadores deben ser dígitos (`1`–`9`)
- Las rutas de los navegadores deben existir
- Los patrones se evalúan en el orden del archivo; la **primera** coincidencia tiene prioridad

## Uso

Después de la instalación, QuickBrowser intercepta cada clic en enlaces http/https:

- **La URL coincide con un patrón** → se abre automáticamente en el navegador asignado
- **Sin coincidencia** → aparece la superposición; presiona `1`–`9` para elegir, `Esc` para cancelar
- **El mismo dominio elegido 5 veces seguidas** → QuickBrowser te ofrece agregar un patrón (o lo agrega automáticamente con `autolearn=true`)

## Coincidencia de patrones

Los patrones se comparan tanto con el host de la URL como con la cadena completa de la URL:

| Patrón | Coincide con |
|---------|---------|
| `github.com` | `https://github.com/...`, `https://api.github.com/...` |
| `api.example.com` | solo el subdominio `api` |
| `stackoverflow` | cualquier URL que contenga `stackoverflow` |

## Barra de menú

Haz clic en el icono del globo en la barra de menú:

- **Editar configuración** — abre el editor SwiftUI para navegadores y patrones
- **Estadísticas** — muestra los conteos de uso (manual vs. automático) por navegador
- **Acerca de** — versión y resumen de características
- **Salir** — cierra QuickBrowser

## Solución de problemas

**Los enlaces no se abren en QuickBrowser**
- Confirma que `QuickBrowser.app` esté en `/Applications` (no en Descargas o Escritorio)
- Vuelve a seleccionar QuickBrowser como navegador predeterminado en Ajustes del Sistema
- Si macOS almacena en caché una versión anterior, cambia el ID del paquete y vuelve a compilar

**"Configuration not found"**
- Crea `~/.config/quickbrowser` con al menos una línea de navegador, por ejemplo `1=/Applications/Safari.app`

**"Browser not found"**
- Verifica que la ruta en la configuración sea correcta y que el `.app` exista

## Versión

**v1.5.0** — Encaminamiento basado en patrones, aprendizaje automático, estadísticas de uso, editor de configuración en SwiftUI
