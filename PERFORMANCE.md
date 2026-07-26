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
| `main.dart.js` (web, sin comprimir) | 5115 KiB | ≤ 5250 | ≤ 3400 | `tool/perf/medir_artefactos.sh web` |
| `main.dart.js` servido con brotli | 1095 KiB ✅ | — | ≤ 1200 | ver §4 |
| `build/web` completo | 44300 KiB | ≤ 45000 | ≤ 32000 | `tool/perf/medir_artefactos.sh web` |
| APK universal de release | ver §3 | ≤ 65000 | ≤ 32000 | `tool/perf/medir_artefactos.sh apk` |
| Primer frame (perfil, gama baja) | sin medir ⚠️ | — | ≤ 2500 ms | `tool/perf/medir_arranque.sh` |
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
> **Por qué el arranque está sin medir.** Requiere un Android de gama baja y
> un Windows conectados, que no había disponibles al cerrar el ticket. El
> procedimiento y el script quedan listos (§3); falta ejecutarlos sobre el
> hardware real y anotar aquí el número.
>
> **Al reducir un artefacto, baja también su trinquete** en
> `tool/perf/medir_artefactos.sh`. Un trinquete que no se aprieta deja de
> proteger.

---

## 2. Qué se puede medir sin dispositivo y qué no

Esta separación importa porque marca qué corre en CI y qué es manual.

**Corre en CI, sin dispositivo** (`flutter test` + `medir_artefactos.sh`):
tamaño de artefactos, número de pantallas construidas al arrancar, capas de
repintado, reutilización de catálogos, ausencia de logs. Son *proxies
deterministas* de la lentitud: no miden milisegundos, miden la causa —cuánto
trabajo se hace de más—, y por eso no parpadean.

**Necesita un dispositivo** (`medir_arranque.sh` + DevTools): arranque, frames
lentos y memoria. Dependen del hardware; medirlos en el portátil del
desarrollador no dice nada sobre el teléfono de la recepción.

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

```bash
flutter devices                  # localiza el dispositivo
tool/perf/medir_arranque.sh <id>
```

Usa `--profile --trace-startup` y lee
`timeToFirstFrameRasterizedMicros` de `build/start_up_info.json`: el instante
en que el usuario ve algo dibujado, no en el que arrancó el proceso.

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

Los flujos que hay que recorrer, por ser los más caros: **inicio** (gráfico),
**odontograma de una consulta** (32-52 piezas dibujadas a mano) y **listado de
pacientes** con varios cientos de filas.

### Navegador con CPU limitada

Chrome DevTools → *Performance* → **CPU: 4x/6x slowdown**, y *Network* →
**Slow 4G**. Es la aproximación más cercana a la máquina de recepción sin
tenerla delante.

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
6. **Antes de dar por terminada una entrega que toque UI**, correr
   `flutter test` y `tool/perf/medir_artefactos.sh`.
