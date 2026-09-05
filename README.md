# Train

Registro de entrenamiento personal. Una sola página HTML, sin dependencias en tiempo de
ejecución, que se publica en GitHub Pages y también se empaqueta como app iOS con Capacitor.

**En vivo:** https://gerryatsxf.github.io/train/

## Qué hace

- Rutina de 4 días fija (tren inferior y superior, días A y B) con series, repeticiones,
  tempo y peso objetivo tomados de la hoja de cálculo original.
- Captura por serie: peso, repeticiones, tiempo de descanso, escala de Borg y notas.
- Vista por semana con navegación y copia de la semana anterior.
- Temporizador de descanso con avisos a los 30 s, 10 s y al finalizar.
- Mini gráfica de consistencia del descanso por ejercicio.
- Todo se guarda en `localStorage`; no hay servidor ni cuentas.

## Estructura

| Ruta | Qué es |
|---|---|
| `index.html` | La aplicación completa: markup, estilos y lógica |
| `config.json` | Valores por defecto y número de versión para invalidar caché |
| `ios/` | Proyecto Xcode generado por Capacitor, con los plugins nativos |
| `www/` | Copia generada para el bundle nativo (ignorada por git) |

## Configuración

`config.json` define los valores por defecto de la experiencia. Solo aplican en dispositivos
donde el usuario no haya cambiado ese ajuste; lo que se toca en Ajustes tiene prioridad.

```json
{
  "version": "2026-09-04.12",
  "theme": "dark",
  "autoTimer": true,
  "restSeconds": 60,
  "restEndPopup": true,
  "sounds": true,
  "tickSound": false,
  "lockedAlarm": true
}
```

**Sube `version` en cada despliegue.** La app pide `config.json` sin caché y, si la versión
no coincide con la de la URL, recarga apuntando a la nueva. Sin eso GitHub Pages sirve el
HTML cacheado hasta 10 minutos, o indefinidamente en una app instalada.

## Desarrollo web

No hay build. Abre `index.html` en el navegador, o publica en GitHub Pages con un push a
`main`. Con `file://` la carga de `config.json` falla y se usan los valores por defecto
embebidos, que son idénticos.

## App iOS

Requiere macOS con Xcode y una cuenta de Apple. Con un Apple ID gratuito la firma caduca a
los 7 días y hay que reinstalar.

```bash
pnpm install
pnpm run ios      # copia a www/, sincroniza Capacitor y abre Xcode
```

En Xcode: target **App** → *Signing & Capabilities* → elige tu equipo → Run.
Tras cada cambio en `index.html`, vuelve a ejecutar `pnpm run sync`.

### Código nativo

Vive en `ios/App/App/` y se registra en el bridge desde `MainViewController.swift`.

- **`NativeSound.swift`** — sintetiza los avisos con `AVAudioEngine` y produce las
  vibraciones con Core Haptics. Los sonidos salen del WebView a propósito: cuando WebKit
  reproduce audio se apodera de la sesión y obliga a elegir entre sonar en modo silencio o
  convivir con la música de otras apps. Con audio nativo se obtienen ambas.
  La receta sonora sigue viviendo en el HTML y se envía como parámetros, para no duplicarla.
- **`LiveActivity.swift`** y **`RestAttributes.swift`** — Live Activity del descanso en
  pantalla bloqueada e Isla Dinámica. La vista está en el target `TrainWidget`;
  `RestAttributes.swift` debe pertenecer a ambos targets.
- La alarma con la pantalla bloqueada usa notificaciones locales, no audio: iOS congela el
  JavaScript al bloquear y solo el sistema puede despertar al usuario de forma fiable.
