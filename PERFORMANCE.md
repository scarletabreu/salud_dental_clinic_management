# Rendimiento

Presupuestos de rendimiento de la app, cómo medirlos y qué se hizo para
llegar a ellos. Nace de **SD-132**, que partía de un problema concreto: la
lentitud en APK, web y escritorio estaba reportada pero no cuantificada, así
que no se podía saber si una entrega la mejoraba o la empeoraba.

La regla de fondo: **un presupuesto que no se mide no existe**. Cada número de
este documento tiene debajo un comando que lo comprueba.

---

## 1. Presupuestos

Dos columnas distintas y no hay que confundirlas. El **trinquete** es lo que
el script exige hoy: existe para que nadie empeore lo que hay. La **meta** es
adonde queremos llegar. Un presupuesto puesto en la meta pondría CI en rojo
desde el primer día y dejaría de leerse.

| Métrica | Medido en SD-132 | Trinquete | Meta | Cómo se comprueba |
|---|---|---|---|---|
| `main.dart.js` (web, sin comprimir) | 5556 KiB (bootstrap HFX-CLIN-000) | ≤ 5700 | ≤ 3400 | `tool/perf/medir_artefactos.sh web` |
| `main.dart.js` servido con brotli | 1095 KiB ✅ | — | ≤ 1200 | ver §4 |
| `build/web` completo | 45912 KiB (bootstrap HFX-CLIN-000) | ≤ 46500 | ≤ 32000 | `tool/perf/medir_artefactos.sh web` |
| APK universal de release | 67344 KiB | ≤ 68000 | — (no se distribuye) | `tool/perf/medir_artefactos.sh apk` |
| APK `arm64-v8a` (lo que se descarga) | 23264 KiB ✅ | ≤ 25500 | ≤ 20000 | `tool/perf/medir_artefactos.sh apk-abi` |
| Primer pintado web, CPU 4x | 3608 ms ✅ | ≤ 4500 ms | ≤ 2500 ms | `tool/perf/medir_web_cpu_limitada.ts` |
| Primer frame (perfil, Android gama baja) | sin medir ⚠️ | — | ≤ 2500 ms | `tool/perf/medir_arranque.sh` |
| Primer frame (perfil, Windows de recepción) | sin medir ⚠️ | — | ≤ 2500 ms | `tool/perf/medir_arranque.sh` |
| Animaciones en bucle sin motivo | 0 ✅ | **0** | 0 | `test/features/inicio/inicio_responsive_test.dart` |
| Pantallas construidas al arrancar | 1 ✅ | **1** | 1 | `test/shell/lazy_destination_stack_test.dart` |
| Pantallas vivas a la vez | 4 ✅ | ≤ 4 | ≤ 4 | idem |
| Capas de repintado del odontograma | 1 por pieza ✅ | 1 por pieza | — | `test/features/odontograma/aislamiento_repintado_test.dart` |
| Peticiones de catálogo por pantalla | 1 ✅ | 1 cada 2 min | — | `test/core/cache_catalogo_test.dart` |
| `print` / `debugPrint` en `lib/` | 0 ✅ | **0** | 0 | `flutter analyze` (`avoid_print`) |

> **Por qué la web sigue lejos de su meta.** No es una regresión de SD-132: es
> la medida honesta del punto de partida, que antes no existía. Bajar
> `main.dart.js` de 5 MB exige carga diferida por módulo (`deferred as`), que
> es un refactor propio y no cabía aquí. Lo que **sí** cumple hoy es lo que el
> navegador descarga de verdad (§4): 1095 KiB con brotli.
>
> **Recalibración del bootstrap clínico.** Al integrar HFX-CLIN-000 se midieron
> 5556 KiB para `main.dart.js` y 45912 KiB para `build/web`. El `dev` de partida
> ya medía 5552/45908 KiB y fallaba los techos anteriores; el hotfix añadió
> únicamente 4 KiB. Los trinquetes se recalibraron a 5700/46500 KiB para que CI
> vuelva a detectar crecimiento nuevo sin atribuirle al hotfix una deuda ya
> integrada. Las metas de 3400/32000 KiB no cambian.
>
> **Qué falta por medir.** De los tres entornos del ticket, el navegador con
> CPU limitada ya está cubierto y automatizado (§3). Siguen sin medir el
> Android de gama baja y el Windows de recepción, que necesitan el hardware
> delante. **SD-154 no pudo cerrarlos**: en el entorno de desarrollo no hay
> ningún Android conectado (`adb devices` vacío, `flutter devices` solo ofrece
> Linux de escritorio y Chromium) ni acceso a un Windows. Lo que sí hizo SD-154
> fue ejecutar el script por primera vez y arreglar lo que estaba roto (§3), de
> modo que la próxima persona que tenga el hardware delante obtenga un número
> válido en vez de uno inventado.
>
> **No rellenar estas dos filas con la máquina de desarrollo.** El primer frame
> en el portátil de desarrollo mide 161 ms; el presupuesto es 2500 ms. Copiar
> ese número aquí daría dos filas verdes y ninguna información: es hardware que
> ningún usuario de la clínica tiene. Una fila «sin medir» es honesta; una fila
> medida en el sitio equivocado es peor que no tenerla.
>
> **Al reducir un artefacto, baja también su trinquete** en
> `tool/perf/medir_artefactos.sh`. Un trinquete que no se aprieta deja de
> proteger.

---

## 2. Qué corre en CI y qué es manual

**En CI** (`.github/workflows/ci.yml`, en cada PR a `dev` o `main`):

- `flutter analyze lib` — cero errores. Se gatea `lib/` y no todo el repo
  porque `test/` arrastra 4 errores heredados de `dev`.
- `dart run tool/ci/verificar_pruebas.dart` — compara la suite con
  `tool/ci/pruebas_conocidas_rojas.txt`. Falla si aparece un fallo nuevo **y
  también** si uno conocido empieza a pasar sin quitarlo de la lista: si no,
  esa prueba dejaría de estar protegida al volver a romperse.
- `tool/perf/medir_artefactos.sh web` — presupuesto de tamaño.

El APK se vigila una vez por semana (`presupuestos-semanales.yml`): tarda ~4
min de Gradle y su tamaño no cambia en un PR normal.

**Corre en CI, sin dispositivo** (`flutter test` + `medir_artefactos.sh`):
tamaño de artefactos, número de pantallas construidas al arrancar, capas de
repintado, reutilización de catálogos, ausencia de logs. Son *proxies
deterministas* de la lentitud: no miden milisegundos, miden la causa —cuánto
trabajo se hace de más—, y por eso no parpadean.

**Necesita un dispositivo** (`medir_arranque.sh` + DevTools): arranque y frames
lentos. Dependen del hardware; medirlos en el portátil del desarrollador no dice
nada sobre el teléfono de la recepción. El tope de pantallas vivas se sacó de
aquí en SD-154 y vive en la suite (§3): no dependía del hardware.

Dos reglas para no medir humo:

- **Nunca en debug.** Un build de debug interpreta el código Dart y va entre 3
  y 10 veces más lento. Se mide en `--profile`; `--release` no admite las
  herramientas de traza.
- **El primer arranque no cuenta.** Descarta la primera ejecución tras
  instalar: incluye trabajo de instalación que el usuario no repite.

---

## 3. Cómo medir

### Artefactos (web y APK)

```bash
tool/perf/medir_artefactos.sh          # web + apk
tool/perf/medir_artefactos.sh web      # solo web
tool/perf/medir_artefactos.sh --json   # salida para CI
```

Sale con código 1 si algún artefacto pasa su techo.

### Arranque en un dispositivo real

Antes de medir hacen falta tres cosas, y la primera es la que más tiempo hace
perder porque no está en el repo:

1. **`dart_define.json`.** Está en `.gitignore`, así que no viene al clonar:
   `cp dart_define.example.json dart_define.json` y rellenar las credenciales de
   Supabase (ver README). Sin él la app no arranca y el script aborta.
2. **El dispositivo en modo depuración** y aceptada la huella del PC, de forma
   que aparezca en `flutter devices` y en `adb devices`.
3. **Un shell con `bash`.** En Windows, **Git Bash** (viene con Git para
   Windows); PowerShell no ejecuta `.sh`. No hace falta Python: el script usa
   solo `bash`, `awk`, `sort` y `mktemp`, que Git Bash ya trae.

```bash
flutter devices                  # localiza el dispositivo
tool/perf/medir_arranque.sh <id>

REPETICIONES_ARRANQUE=7 tool/perf/medir_arranque.sh <id>      # más muestras
PRESUPUESTO_ARRANQUE_MS=3200 tool/perf/medir_arranque.sh <id> # otro techo
```

En Windows el `<id>` del propio PC es `windows`; en Android es el que sale en
`adb devices`. El script no necesita más argumentos: compila en `--profile`,
mide, descarta el calentamiento y escribe al final la línea que hay que copiar
a la tabla de §1.

Usa `--profile --trace-startup` y lee
`timeToFirstFrameRasterizedMicros` de `build/start_up_info.json`: el instante
en que el usuario ve algo dibujado, no en el que arrancó el proceso.

Ejecuta **6 veces**: descarta la primera —que incluye trabajo de instalación
que el usuario no repite— y reporta la **mediana** de las otras cinco. No es
ceremonia: en SD-154, en la misma máquina y sin cambiar nada, la primera medida
dio 409 ms y las siguientes 119-209 ms. Con una sola ejecución, el número de
referencia lo fija el ruido.

Al terminar imprime el trinquete sugerido (mediana + 15 %). **El trinquete se
pone sobre lo medido, nunca sobre la meta**: si el arranque real queda muy por
encima de los 2500 ms, no se baja la meta —se abre el ticket de carga diferida
y se deja constancia de la distancia.

Anota siempre **modelo, RAM y versión de sistema** junto al número. El script
los obtiene por `adb` cuando el dispositivo es un Android; en escritorio avisa
de que hay que anotarlos a mano. Un arranque sin el hardware al lado no
significa nada: 2500 ms es excelente en un gama baja y malo en un buque
insignia. Y el dispositivo debe ser el **peor caso real** de la clínica, no un
tope de gama.

**Dos trampas que el script ya corta** (ambas encontradas en SD-154 al
ejecutarlo por primera vez; hasta entonces solo se había revisado su lógica de
parseo):

- **Sin `--dart-define-from-file` no se mide la app.** El arranque aborta con
  «Falta APP_ENVIRONMENT», pero el motor pinta la pantalla de error igual de
  rápido y el trazado reporta un primer frame de 125 ms. El script pasaba el
  presupuesto midiendo un cartel de error. Ahora exige `dart_define.json` y
  aborta si detecta un fallo de bootstrap en la salida.
- **Un `start_up_info.json` viejo se cuela.** El archivo se borra antes de cada
  ejecución, no una sola vez al principio: si una ejecución falla, la medida
  anterior pasaría por nueva.

### Frames lentos y memoria

```bash
flutter run --profile -d <id>
```

y en DevTools:

- **Performance** → activar *Track widget builds*. Lo que se busca son barras
  por encima de 16 ms (60 fps) y, sobre todo, *qué* widget las causa.
- **Memory** → tomar una instantánea, navegar por cinco pantallas, volver, y
  comprobar que el número de pantallas vivas no crece sin parar. El shell
  retiene 4 como máximo (§5).

  Esta comprobación **ya no hace falta a mano**: la cubre
  `test/shell/lazy_destination_stack_test.dart` («con el tope por defecto, cinco
  pantallas se estabilizan en 4»), que recorre cinco destinos, vuelve sobre lo
  visitado y exige que queden 4 vivas. Se automatizó en SD-154 porque el tope es
  una propiedad del código y no del dispositivo: lo que el teléfono añade es
  ruido, no información. Antes ninguna prueba fijaba el tope *por defecto* —las
  que había pasaban 3 y 2 explícitos—, así que subir el default a 6 dejaba la
  suite verde y la fila «Pantallas vivas a la vez ≤ 4» sin protección real.

Los flujos que hay que recorrer, por ser los más caros: **inicio** (gráfico),
**odontograma de una consulta** (32-52 piezas dibujadas a mano) y **listado de
pacientes** con varios cientos de filas.

Para cada flujo se anota una línea por frame que pase de 16 ms: flujo, gesto que
lo provocó, duración y widget culpable. Ese registro es el punto de partida del
siguiente trabajo de rendimiento; sin el widget culpable, un frame lento es un
dato que no se puede accionar.

> **Pendiente.** SD-154 no pudo levantar este registro: DevTools en `--profile`
> necesita el dispositivo delante y en el entorno de desarrollo no había ninguno
> de los dos objetivos (ni Android por `adb`, ni Windows). Queda como lo único
> del ticket que sigue abierto junto con las dos filas «sin medir» de §1, y se
> hace en la misma sesión con el hardware: primero `medir_arranque.sh`, después
> los tres flujos con la app ya instalada.

### Navegador con CPU limitada — automatizado

```bash
flutter build web --release
deno run -A tool/perf/medir_web_cpu_limitada.ts             # freno 4x
deno run -A tool/perf/medir_web_cpu_limitada.ts --cpu 6     # más severo
```

Sirve `build/web`, abre Chromium sin interfaz con el freno de CPU puesto
*antes* de navegar y cronometra hasta el primer pintado con contenido (FCP).
Reporta la **mediana** de varias repeticiones, para que un pico de ruido de la
máquina no mueva el número. Sale con código 1 si se pasa del presupuesto.

Medido en SD-132: **3608 ms** con freno 4x (mejor 3065, peor 3648). Es el
coste de descargar y compilar `main.dart.js` más arrancar el motor — de ahí
que la meta de 2500 ms dependa de la carga diferida (§1).

Para inspeccionar a mano: Chrome DevTools → *Performance* → **CPU: 4x/6x
slowdown**, y *Network* → **Slow 4G**.

---

## 3.bis El APK universal no es lo que hay que distribuir

Medido en SD-132, el APK universal de release pesa **67 MB**, y el desglose no
deja lugar a dudas:

| Contenido | Tamaño | Del total |
|---|---|---|
| `lib/x86_64` | 23,6 MB | 35 % |
| `lib/arm64-v8a` | 22,1 MB | 33 % |
| `lib/armeabi-v7a` | 20,4 MB | 30 % |
| Todo lo demás (código Dart compilado aparte, recursos, assets) | ~1,7 MB | 2 % |

El 97 % son librerías nativas de **tres** arquitecturas, de las que cada
teléfono usa exactamente una. `x86_64` además solo sirve para emuladores: no
hay ningún dispositivo de clínica que la necesite.

```bash
flutter build apk --release --split-per-abi   # uno por arquitectura
flutter build appbundle --release             # preferible si se publica en Play
```

Para un teléfono de gama baja esto es la diferencia entre descargar 67 MB y
~23 MB. Si la distribución es por Play Store, el App Bundle hace la selección
solo; si los APK se reparten a mano —que es lo habitual en una clínica—, hay
que repartir el de `arm64-v8a` y no el universal.

**Pendiente evaluado y no aplicado:** activar R8 (`isMinifyEnabled`,
`isShrinkResources`) en `android/app/build.gradle.kts`. Afectaría solo al
código Java/Kotlin de los plugins —el Dart ya va compilado a AOT—, así que la
ganancia es modesta, y R8 puede romper plugins que usen reflexión sin reglas
`keep`. No se activó porque no había un Android para verificar el APK
resultante en ejecución, y un fallo de este tipo no aparece al compilar sino
en el dispositivo. Requiere una prueba manual antes de entrar.

---

## 4. Servir la web comprimida

El mayor factor de arranque en web no es el tamaño en disco sino el
transferido. Medido sobre `main.dart.js` de este proyecto:

| | Tamaño | Frente a crudo |
|---|---|---|
| Sin comprimir | 5115 KiB | — |
| gzip -9 | 1494 KiB | −71 % |
| brotli -q 11 | 1095 KiB | **−79 %** |

Servir con brotli no es una optimización opcional: es la diferencia entre
descargar 5 MB y 1 MB en cada primera visita. Debe estar activo en el servidor
o el CDN que sirva `build/web`.


### Dónde se despliega, y por qué importa para el rendimiento

El destino es Azure. Para el rendimiento web la elección concreta del servicio
no es un detalle: decide si el usuario descarga 1 MB o 5 MB.

| Servicio de Azure | ¿Comprime? | Veredicto |
|---|---|---|
| **Static Web Apps** | brotli y gzip automáticos en su CDN | **Es el adecuado.** Pensado para SPAs, capa gratuita, HTTPS y dominio propio incluidos, y se despliega desde GitHub Actions |
| Blob Storage (static website) | **no** | Sirve los 5 MB en crudo salvo que se pre-compriman los ficheros a mano y se fije `Content-Encoding`. Necesita Front Door delante para comprimir |
| App Service | gzip; brotli requiere trabajo extra | Pensado para servidores de aplicación; para ficheros estáticos es pagar de más por menos |

Por eso el repo trae `staticwebapp.config.json` y
`.github/workflows/deploy-web-azure.yml`: van con Static Web Apps.

La configuración no es solo compresión. `navigationFallback` hace que las
rutas profundas no den 404; el MIME de `.wasm` es obligatorio para que
CanvasKit cargue; y el `Cache-Control` distingue lo que puede cachearse para
siempre (`/assets`, `/canvaskit`, con hash en el nombre) de lo que nunca debe
cachearse (`index.html`, el service worker), que es lo que permite que un
despliegue nuevo se vea de inmediato sin que el usuario vacíe la caché.

**Verificar después de desplegar** —la compresión es justo el ajuste que se da
por hecho y nadie comprueba:

```bash
tool/perf/verificar_brotli.sh https://<tu-app>.azurestaticapps.net
```

### Escritorio y móvil no son «hosting»

Windows y Android no se sirven: se distribuyen como artefactos de una versión.
Ponerlos en Blob Storage funciona, pero para un repositorio público de GitHub
**GitHub Releases** sale gratis, versiona solo y no necesita cuenta de Azure.
Lo que sí importa es repartir el APK **por arquitectura** y no el universal
(§3.bis).

---

## 5. Qué se cambió en SD-132 y por qué

### El shell construía o destruía de más

`lib/shell/lazy_destination_stack.dart`.

El shell había pasado por dos extremos, ambos costosos. Con un `IndexedStack`
sobre todos los destinos, entrar a la app construía las doce pantallas de un
admin de golpe: doce cubits y doce consultas a Supabase antes de tocar nada.
Con un `KeyedSubtree` sobre el destino seleccionado ocurría lo contrario: salir
de una pantalla la destruía junto a su cubit, así que volver recargaba todo
desde la red —la «recarga al navegar» del reporte original.

Ahora la pantalla se construye la primera vez que se pide y se conserva viva,
con un tope de **4** simultáneas. El tope es deliberado: conservarlo todo para
siempre convierte un problema de CPU en uno de memoria, que en un teléfono de
gama baja acaba en muerte por el *low-memory killer*. Al pasarse, se descarta
la usada hace más tiempo.

Las pantallas retenidas pero ocultas quedan con `TickerMode` apagado. Sin eso,
cada `AnimatedContainer` o spinner de una pantalla que nadie ve seguiría
pidiendo frames.

### El odontograma repintaba la boca entera

`odontodiagrama_widget.dart`, `odontogram_widget.dart`, `tooth_geometry.dart`.

Medido antes del arreglo: **52 piezas compartían una sola capa de repintado**.
Pasar el ratón por un molar invalidaba esa capa y redibujaba las 52, con sus
contornos, tinciones y símbolos, en cada frame del hover. Cada pieza tiene
ahora su propia frontera.

Además, `buildToothPath` y `buildGroovePath` se llamaban dentro del bucle de
`paint`: ~64 `Path` transformados y descartados por repintado. El parseo del
SVG ya estaba memorizado; ahora también lo está el ajuste al tamaño.

### El `MaterialApp` se reconstruía por cualquier ajuste

`lib/main.dart`, `settings_cubit.dart`.

`SettingsState` no implementaba igualdad por valor, así que cada `emit`
producía un objeto distinto y bloc reconstruía el `MaterialApp` —la raíz de
todo el árbol— aunque el tema no hubiera cambiado. Cambiar el idioma repintaba
la aplicación entera. Ahora es `Equatable` y `main.dart` selecciona solo
`themeMode`.

### Los catálogos se bajaban una vez por pantalla

`lib/core/data/cache_catalogo.dart`.

El catálogo de medicinas y el inventario se pedían a la red cada vez que se
montaba su sección de la consulta. Abrir tres consultas seguidas bajaba tres
veces la misma lista. La caché vive detrás del repositorio —no en los
widgets—, tiene vigencia corta (2 min), agrupa las peticiones simultáneas en
una sola y se invalida en cada escritura, para que el stock nunca se sirva
viejo.

### Una animación que no paraba nunca

`dashboard_alert_center.dart`.

El indicador de alertas críticas arrancaba su `AnimationController` con
`repeat(reverse: true)` en `initState`, **sin condición**. El punto solo se
dibuja si hay alertas críticas, pero el controlador seguía pidiendo un frame
cada 16 ms durante toda la sesión, hubiera alertas o no, con el inicio abierto
o retenido en segundo plano: gasto de CPU y batería por un dibujo que nadie
estaba viendo.

Ahora el pulso arranca y se detiene según haga falta, y el punto vive en su
propio `RepaintBoundary` para que sus 60 repintados por segundo no arrastren a
la cabecera de la tarjeta.

Efecto secundario que delató el problema: al no cesar nunca, `pumpAndSettle`
no terminaba y las once pruebas responsive del inicio no podían llegar a sus
aserciones. Una animación en bucle perpetuo hace la pantalla no comprobable,
además de cara.

### Logs en rutas calientes

33 `print`/`debugPrint` en citas, pacientes, consultas y expedientes,
incluido uno dentro del `build` de un item de lista. En release la llamada
desaparece pero **la interpolación del mensaje no**: `debugPrint('… $lista')`
sigue construyendo el string. Todo pasa ahora por `AppLog`
(`lib/core/util/app_log.dart`), que recibe el mensaje como *callback* y se
compila fuera del binario. El lint `avoid_print` impide que vuelvan.

### Un `<script>` bloqueante en el arranque web

`web/index.html` cargaba de forma **síncrona** el bundle de passkeys de
Corbado desde `github.com`, en el `<head>` y sin `defer`. El navegador detenía
el parseo del documento hasta descargarlo, antes de que Flutter empezara a
cargar; y si el host fallaba, la app no arrancaba. No se usaba:
`passkeys_platform_interface` entra como dependencia transitiva de
`supabase_flutter`, pero esta app autentica con `signInWithPassword`. Se
retiró y se añadió `preconnect` a Supabase.

### Código muerto

`pacientes_page.dart` contenía una copia completa y sin usar de
`DashboardShell` (373 líneas) que arrastraba 19 imports —medio grafo de
módulos— al módulo de pacientes.

---

## 6. Reglas para no perder lo ganado

1. **Una pantalla nueva en el shell no construye nada hasta que se visita.**
   Si necesita datos, los pide su cubit al crearse, no antes.
2. **Todo `CustomPaint` que repinte por interacción va dentro de un
   `RepaintBoundary`,** y su `shouldRepaint` compara por valor (`listEquals`,
   `mapEquals`), nunca por identidad.
3. **Nada de `print` ni `debugPrint`.** `AppLog`, y solo para lo que sirva a
   diagnosticar.
4. **Un estado que escuche el `MaterialApp` o un shell es `Equatable`.** Sin
   igualdad por valor, cada `emit` repinta el árbol entero.
5. **Los catálogos se piden al repositorio,** que ya los comparte. Un
   `FutureBuilder` que llame al datasource desde un widget vuelve a introducir
   el problema.
6. **Ninguna animación en bucle perpetuo.** Un `repeat()` se arranca solo
   cuando su dibujo está en pantalla y se detiene cuando deja de estarlo. Si
   `pumpAndSettle` se queda colgado en una prueba, es que hay una.
7. **Antes de dar por terminada una entrega que toque UI**, correr
   `flutter test` y `tool/perf/medir_artefactos.sh`.
