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

## Rutinas

Cada programa es un archivo JSON dentro de `routines/` y la app solo ofrece los que aparecen en
`routines` dentro de `config.json` (`routine` marca el predeterminado). El `id` de la rutina
y el de cada ejercicio son la clave del registro: cambiarlos después deja huérfanas las series
ya anotadas.

### Generar una rutina con otra IA

1. Abre una conversación con una IA que ya conozca tu rutina (o adjúntala: hoja de cálculo,
   PDF, foto o texto).
2. Pega el prompt de abajo tal cual.
3. Revisa la sección *Supuestos* de la respuesta y guarda el JSON en `routines/` con el nombre
   que quieras. Si otra rutina ya usa el mismo `id`, cámbialo: compartirían el registro.
4. Añade su ruta a `routines` en `config.json`, sube `version` y, para la app iOS, ejecuta
   `pnpm run sync`.

````text
<rol>
Conviertes rutinas de entrenamiento de fuerza al formato JSON de la app "Train". La app es
estricta: un valor fuera de las listas permitidas o un id repetido hace que la rutina no cargue
o que se mezclen los registros de ejercicios distintos.
</rol>

<tarea>
Toma la rutina de entrenamiento del usuario que ya tienes en contexto (esta conversación,
archivos adjuntos o memoria) y genera el archivo JSON que la describe.
- Si no tienes ninguna rutina en contexto, no inventes una: pídela al usuario y detente.
- Si falta un dato, no preguntes: aplica las reglas por defecto y anótalo en "Supuestos".
- Conserva el idioma de la rutina original en name, label y notes.
</tarea>

<formato_de_salida>
1. Un único bloque de código json con el archivo completo. JSON estricto: comillas dobles,
   sin comentarios, sin comas finales, sin claves fuera del esquema.
2. Debajo, "Supuestos": como máximo 8 viñetas con lo que inferiste, adaptaste u omitiste.
   Si no hubo ninguno, escribe "Supuestos: ninguno".
No escribas nada más.
</formato_de_salida>

<esquema>
type Rutina = {
  id: string;                // slug de name, ≤ 64, ver <reglas_ids>
  name: string;              // ≤ 120. Objetivo + división, p. ej. "Hipertrofia · Torso / Pierna"
  weeks: number;             // entero 1–104: duración del programa. Por defecto 4
  days: Dia[];               // ≥ 1, solo días de entrenamiento, en el orden en que se hacen
};
type Dia = {
  id: string;                // slug único en el archivo, ≤ 64
  name: string;              // ≤ 80, p. ej. "Tren inferior", "Push", "Full body A"
  blocks: Bloque[];          // ≥ 1, en orden de ejecución
};
type Bloque = {
  label: string;             // ≤ 60, ver <reglas_estructura>
  ex: [Ejercicio] | [Ejercicio, Ejercicio];   // 1 = ejercicio suelto, 2 = biserie
};
type Ejercicio = {
  id: string;                // slug único en TODO el archivo, ≤ 48
  name: string;              // ≤ 120
  series: number;            // entero 1–20
  reps: string;              // ≤ 40: "8", "10-12", "6 x lado", "30 s"
  equip: "bar" | "db1" | "db2" | "p1" | "p2" | "p4" | "bw100" | "bw75" | "bw50" | "bw25";
  unit: "kg" | "lb";
  peso?: string;             // ver <reglas_peso>
  tempo?: string;            // "N:N" en segundos, copiado tal cual de la rutina
  notes?: string;            // ≤ 200, ver <reglas_estructura>
};
</esquema>

<reglas_equip>
- bar: barra libre, máquina Smith, trap bar y máquinas de discos (prensa, hack, etc.).
- db1: una sola mancuerna o kettlebell (goblet, ejercicios a una mano).
- db2: dos mancuernas o kettlebells a la vez.
- p1: máquinas de pila de placas (selectorizadas) y poleas de cable directo.
- p2: polea con polipasto 2:1 (la carga real es la mitad de la pila).
- p4: polea con polipasto 4:1 (la carga real es un cuarto de la pila).
- bw100 / bw75 / bw50 / bw25: peso corporal; elige la fracción del cuerpo que se mueve.
  · bw100: dominadas, fondos, sentadilla y desplantes sin carga.
  · bw75: lagartijas en el suelo, superman.
  · bw50: lagartijas inclinadas, remo invertido.
  · bw25: lagartijas en pared, isométricos de core ligeros.
- Lastre o bandas sobre peso corporal: usa el bw* del movimiento y describe el lastre o la banda en notes.
- Si no puedes deducir el equipo: bar, y anótalo en Supuestos.
</reglas_equip>

<reglas_peso>
- Solo el número, sin unidad, con punto decimal: "20", "17.5". Nunca "20 kg".
- bar, db1, p1, p2, p4: la carga que el usuario lee y anota (en poleas, el número de la pila;
  la app aplica la proporción).
- db2: "2 × N", donde N es el peso de CADA mancuerna (p. ej. "2 × 10"); la app muestra
  2 × 10 = 20 y registra el total combinado.
- bw*: omite peso.
- Rango de pesos: usa el valor inferior y escribe el rango en notes.
- Peso desconocido: omite peso (el usuario lo anota en la app).
- unit: la unidad que usa la rutina para ese ejercicio; si no la indica, "kg". Inclúyela siempre,
  también en bw* (es la unidad del peso corporal).
</reglas_peso>

<reglas_ids>
- Slug: minúsculas ASCII sin acentos (á→a, ñ→n), solo a-z, 0-9 y guiones simples, sin guiones
  al inicio o al final. Deriva el id del name: "Press de banca c/mancuerna" → "press-de-banca-c-mancuerna".
- El id de la rutina es el slug de su name: "Hipertrofia · Torso / Pierna" → "hipertrofia-torso-pierna".
- Los ids de ejercicio no se repiten en todo el archivo. Si el mismo ejercicio aparece en varios
  días, añade "-2", "-3"… según el orden de aparición. Un id repetido mezcla las series de ambos días.
- Los ids de día tampoco se repiten; usa el mismo sufijo si dos días se llaman igual.
</reglas_ids>

<reglas_estructura>
- Dos ejercicios encadenados sin descanso (superserie, biserie, par agonista/antagonista) van
  en el mismo bloque. Un bloque nunca tiene más de 2 ejercicios.
- Triseries, series gigantes o circuitos: divídelos en bloques consecutivos de 1–2 ejercicios
  conservando el orden, y en notes del primero indica con qué ejercicios se encadena.
- label: "Ejercicio principal" para un ejercicio suelto; "1ra Biserie", "2da Biserie",
  "3ra Biserie", "4ta Biserie"… para las biseries de cada día, numeradas desde 1 en cada día.
- Calentamiento, cardio, movilidad y estiramientos: omítelos salvo que tengan series y
  repeticiones prescritas; lista lo omitido en Supuestos.
- Ejercicios unilaterales: reps con "x lado" ("10 x lado").
- La rutina tiene una sola prescripción para todas las semanas. Si la original progresa por
  semana, usa los valores de la semana 1 y resume la progresión en notes.
- Lo que no tiene campo propio (RIR/RPE objetivo, descanso entre series, ajustes de máquina,
  agarre, indicaciones técnicas) va resumido en notes: "RIR 2 · Descanso 90 s · Asiento 4".
  La app precarga esas notas en el ejercicio.
- No inventes ejercicios, series ni pesos que la rutina no indique.
</reglas_estructura>

<ejemplo>
{
  "id": "hipertrofia-torso-pierna",
  "name": "Hipertrofia · Torso / Pierna",
  "weeks": 6,
  "days": [
    {
      "id": "torso-a",
      "name": "Torso A",
      "blocks": [
        {
          "label": "Ejercicio principal",
          "ex": [
            { "id": "press-de-banca", "name": "Press de banca", "series": 4, "reps": "6-8",
              "equip": "bar", "unit": "kg", "peso": "60", "tempo": "3:1", "notes": "RIR 2 · Descanso 2 min" }
          ]
        },
        {
          "label": "1ra Biserie",
          "ex": [
            { "id": "remo-en-polea-baja", "name": "Remo en polea baja", "series": 3, "reps": "10-12",
              "equip": "p1", "unit": "lb", "peso": "90" },
            { "id": "lagartijas", "name": "Lagartijas", "series": 3, "reps": "12",
              "equip": "bw75", "unit": "kg" }
          ]
        },
        {
          "label": "2da Biserie",
          "ex": [
            { "id": "curl-de-biceps-c-mancuerna", "name": "Curl de bíceps c/mancuerna", "series": 3,
              "reps": "12", "equip": "db2", "unit": "kg", "peso": "2 × 8" },
            { "id": "extension-de-triceps-en-polea", "name": "Extensión de tríceps en polea", "series": 3,
              "reps": "12", "equip": "p2", "unit": "kg", "peso": "25" }
          ]
        }
      ]
    }
  ]
}
</ejemplo>

<verificacion>
Antes de responder, comprueba y corrige:
1. El JSON es válido y estricto, y "id" es el slug de name.
2. Todos los ids de ejercicio son únicos en el archivo y los de día también.
3. Cada bloque tiene 1 o 2 ejercicios.
4. series es entero 1–20 y weeks entero 1–104.
5. equip y unit están en sus listas; peso solo contiene números (o "2 × N" con db2) y no existe en bw*.
6. Ningún texto supera su límite y no hay claves fuera del esquema.
7. Cada ejercicio, serie y peso sale de la rutina del usuario o está listado en Supuestos.
</verificacion>
````

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
