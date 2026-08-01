# Handoff · Plan de corrección QA del 1 ago 2026

Plan de origen: `docs/QA-2026-08-01-plan-correccion.md`.
Ejecutadas las seis fases (F0–F5). Todo commiteado en local; **nada empujado ni
mergeado, y nada aplicado en producción**.

---

## Estado

| Fase | Rama | Commit | Estado |
|---|---|---|---|
| F0 · Esquema | `HFX-QA-100-esquema` | `34379dc` | Completa y aplicada en producción |
| F1 · Pantallas bloqueadas | `HFX-QA-101-pantallas` | `4e7c040` | Completa |
| F2 · Visibilidad clínica | `HFX-QA-102-visibilidad-clinica` | `d23f418` | Completa y aplicada en producción |
| F3 · Matriz de permisos | `HFX-QA-103-permisos-roles` | `f790a28` | Completa y aplicada en producción |
| F4 · Funcionalidad y navegación | `HFX-QA-104-funcionalidad` | `e1da4e4` | Completa |
| F5 · E2E | `HFX-QA-105-e2e` | `5e63db4` | Completa, con huecos de cobertura documentados |

**Ancestría:** las ramas están **encadenadas**, no salen todas de `dev`. F1
necesita la vista `directorio_pacientes` que crea F0, F3 necesita las
capacidades de F1, y así sucesivamente. El plan pedía «una por fase desde
`dev`», pero eso habría dejado cada rama sin poder compilar ni probarse sola.
Se integran en orden: F0 → F1 → F2 → F3 → F4 → F5.

**Validación al cierre:** 781 pruebas Dart en verde (0 rojas), `flutter analyze`
sin errores ni advertencias, 15 pruebas SQL en verde, 2 jornadas de interfaz
headless superadas, 14 controles negativos por API rechazados como debe, y
**gate de deriva limpio contra producción**.

**Listo para desplegar.** `dev` contiene las seis fases y el esquema de
producción coincide con el que describe el repositorio.

---

## Lo que cambió, por fase

### F0 · El gate del plan no servía

El plan cerraba la fase con `supabase db diff --linked` vacío. **Ese comando da
un falso negativo**: devolvió «No schema changes found» mientras producción
tenía tres tablas, cuatro vistas, cinco funciones, diez triggers y catorce
policies que la base local no tenía. Borrar su caché no lo arregla. Se sustituye
por `tool/produccion/deriva_esquema.sh`, que vuelca las dos bases y compara
conjuntos de sentencias.

Con un gate que sí mira, la deriva resultó mayor que la del diagnóstico. Dos
hallazgos cambian la lectura del problema:

1. **El repositorio estaba atrasado, no sólo producción derivada.** El cliente
   ya leía `cantidad_realizada`, `tipo_ejecucion`, `sesiones_planificadas` y
   `codigo_receta`, y ninguna existía en una base levantada con
   `supabase db reset`. Cualquier entorno de desarrollo corría contra un
   esquema incompleto. Lo mismo con `hfx_base_recibir_compra`, donde producción
   iba por delante.

2. **La causa directa de D2 era una FK duplicada.** Producción tenía dos
   restricciones sobre `admins.id` hacia `doctores.id`: la versionada de
   HFX-CLIN-000 y el nombre de la línea base repuntado a mano en el Studio.
   PostgREST ve dos caminos y responde «more than one relationship was found».
   Se retira la redundante; no cambia ninguna garantía de datos.

Además: `directorio_pacientes`, la vista mínima (id, nombre, apellido) que
permite poner nombre a un paciente cuya ficha el rol no puede abrir.

### F1 · Los errores rojos

`getCuotasDeCuenta` ejecutaba una RPC de escritura antes de leer, así que el
Detalle de Cuenta moría para el doctor. Se desacopla y la consolidación pasa al
flujo de cobro. Se añade `PermisoDenegadoFailure` para no tener que reconocer un
`42501` por su texto.

En Perfiles, además del hint de restricción, cada lectura y cada fila se aíslan.
Apareció un defecto que nadie había visto: un perfil sin datos de persona **no
fallaba**, se pintaba como alguien llamado «nombre apellido» nacido hoy. Eso es
peor que un error, así que ahora la fila se rechaza y se muestra como aviso.

### F2 · El odontodiagrama nunca pintó nada

`ExpedientePdfBuilder` convertía las entidades a mapas por duck-typing y leía
`oMap['dientes']`. `OdontogramaModel.toJson()` no emite `dientes` y
`HistorialPiezas` no tiene `toJson`: las 52 piezas evaluaban a vacío **siempre**,
desde el primer día. Al ser todo `dynamic`, ni el compilador ni ningún test lo
delataban. Ahora se lee por campos tipados, con pruebas diferenciales que fallan
si el diagrama vuelve a quedar en blanco.

Sobre D6b se tomó una decisión que se aparta del plan: **no** se cae en la clave
«Otro» lo que no encaja. Las claves del formulario afirman hechos clínicos, y
estampar `pulpectomia_pulpotomia` sobre un diagnóstico de pulpitis diría que se
hizo una endodoncia que nadie hizo. Se mapea sólo lo cierto y la migración
informa lo que queda sin clave.

### F3 · La matriz, impuesta por la base

La matriz de estados se impone con un **trigger**, no con el `WITH CHECK` de la
policy: `WITH CHECK` sólo ve la fila nueva, así que no distingue «cambió el
estado» de «se editó la hora», y negaría cualquier edición de una cita que ya
estuviera en un estado no permitido como destino. El trigger no es
`security definer` a propósito: así `current_user` delata si la escritura viene
de una RPC clínica o de la API.

`reprogramada` no existe como estado —reprogramar es mover la fecha—, así que se
retiró de la matriz del plan.

### F4 · Lo que faltaba

El bug SD-124 que el plan atribuía a `InventarioPage` **ya estaba resuelto**: la
página provee `SuplidorCubit`. Sólo hizo falta retirar el destino duplicado.

### F5 · Qué se probó y qué no

`docs/qa/e2e-ui/RESUMEN-HFX-QA-105.md` tiene la tabla defecto por defecto. Lo
importante de leer es la lista de lo NO cubierto.

---

## Problemas encontrados y cómo se resolvieron

1. **`db diff --linked` miente.** → Gate propio por volcado. Documentado en
   `supabase/README.md` con un aviso destacado.
2. **Regresiones en pruebas al endurecer RLS** (`hfx_clin_005`, `sd_146`): una
   asistente sin asignación ya no alcanza esa agenda. Se actualizaron las
   pruebas para expresar el contrato nuevo, no para esquivarlo.
3. **29 pruebas de widget rotas** al gatear por sesión: montar esas pantallas
   ahora exige un `AuthCubit`. Se añadió `test/support/sesion_de_prueba.dart` y
   cada prueba declara con qué rol se monta.
4. **Desbordamiento de 2-5 px** al mostrar el estado de la cita también al
   doctor. Se corrigió el layout, no la prueba.
5. **La segunda jornada E2E nunca veía el login**: `app.main()` no reinicia la
   sesión y Supabase la persiste. Cada jornada va en su propio target.

---

## Lo que queda pendiente, y qué decisión requiere

### 1. Producción — TODO APLICADO

Las seis fases están en producción (1 ago 2026). Detalle y verificación en
`docs/HFX-QA-100-estado.md`.

**El gate de deriva sale limpio**: `tool/produccion/deriva_esquema.sh` →
«Sin deriva: local y producción describen el mismo esquema». Es la primera vez
desde que existe el gate.

Queda **una decisión administrativa**, no técnica: `isaacpena` es asistente y
no tiene ninguna fila en `doctor_asistentes`. Con la regla D12 ya aplicada, su
agenda sale vacía. No es una rotura —la pantalla lo explica con «Todavía no
tienes odontólogos asignados. Pide a administración que te asigne al menos
uno»— pero alguien tiene que decidir a qué odontólogo asiste. No se asignó
desde aquí porque eso es negocio, no migración.

### 2. Claves de odontograma (D6b) — leído y cerrado

El informe de `20260812090000` listó 9 tratamientos sin clave. Ocho quedan fuera
con razón: flúor, limpieza, blanqueamiento y raspado son de arcada o cuadrante;
brackets, implante y prótesis no caben en el vocabulario cerrado del formulario;
«Tratamiento Prueba» es un dato de prueba. El noveno sí era un hueco real —
«Reconstrucción dental» es trabajo restaurador sobre una pieza y el patrón
buscaba `restaurac`, no `reconstrucc`—, y lo cierra `20260814090000`.

Los diagnósticos mapearon todos.

Justamente para esto se escribió el informe: para que un hueco así se vea al
aplicar, en vez de descubrirse meses después por un odontodiagrama vacío.

### 3. Revisar dos decisiones marcadas

- **`consulta_select` y `puede_ver_consulta` son TEMPORALES** (decisión D11).
  Están marcadas en el SQL, en el comentario de la policy y en la prueba de
  `hfx_clin_005`. Las tres se revierten juntas.
- **`consumibles_update` incluye `es_doctor()`** en producción. Se versionó tal
  cual para no cambiar producción en F0, pero no forma parte de la matriz de QA
  y parece deriva accidental: un doctor actualizando inventario. Pendiente de
  decisión de negocio.

### 4. Integración — HECHA

Las seis ramas se integraron por PR a `dev` en orden: #128, #129, #130, #131,
#132, #133. Todas se conservan, local y remotamente.

`dev` había avanzado mientras tanto: alguien arregló D9 en paralelo agrupando
`cuentasPorCobrar` bajo `puedeGestionarCaja`. El auto-merge de git dejó un
`case` **duplicado** —código que no compila— pese a fusionar «limpio». Se
resolvió conservando la capacidad propia `verCuentasPorCobrar`, que hoy resuelve
al mismo conjunto de roles y además dice por qué. Vale la pena recordarlo: un
merge sin conflictos no garantiza que el resultado compile.

Estado de `dev` tras integrar: 781 pruebas aprobadas, `flutter analyze` sin
errores ni advertencias.
