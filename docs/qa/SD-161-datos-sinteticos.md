# Registros sintéticos en `lib/` — SD-161

Auditoría del patrón «si la consulta falla o viene vacía, devuelve datos
inventados» en toda la capa de datos, hecha al cerrar SD-161.

## Corregido en este ticket

| Ubicación | Qué hacía | Resolución |
| --- | --- | --- |
| `features/cita/data/datasources/cita_remote_datasources.dart` | `fetchCitas` devolvía `_citasPrueba` (20 citas de mayo 2026 con doctores `d1`–`d3` y pacientes `p1`–`p6`) en tres casos: consulta vacía, ensamblado vacío y **excepción capturada**. Un corte de red, un error de RLS o una tabla mal nombrada se veían como una agenda llena. | Borrados `_citasPrueba`, `_cita`, `_doc`, `_pac`, `_empty` y las constantes de doctores/pacientes. `fetchCitas` ya no captura: el error sube al `runGuarded` del repositorio y llega a la UI como `Failure` tipado. |
| `features/cita/data/datasources/cita_remote_datasources.dart` (`fetchEstadoCita`) | Devolvía `null` para ids que no son UUID, y el repositorio se saltaba la validación de transiciones al recibirlo. | Devuelve `EstadoCita` no nulo y lanza `ServerFailure` si el id no existe. `CitaRepositoryImpl` volvió a validar siempre la transición. |
| `features/medicina/data/repositories/medicina_memory_repository.dart` | Catálogo en memoria con `med-001`/`med-002` y sus contraindicaciones, más `Future.delayed` simulando latencia. | **Eliminado.** Era código muerto: el service locator registra `MedicinaRepositoryImpl` (`core/di/service_locator.dart:307`) y ninguna otra referencia lo instanciaba. |

## Pendiente — mismo defecto, ticket aparte

### `features/paciente/data/datasources/paciente_remote_datasource.dart`

Es el mismo patrón y hoy el único que queda en `lib/`:

- Línea 31 — `getPacientes()`: `if (lista.isEmpty) lista.addAll(_pacientesPrueba);`
- Línea 36 — `_pacientesPrueba`: 6 pacientes inventados (`p1`…`p6`, ~200 líneas)
  con cédulas, teléfonos y direcciones falsas. Son **los mismos ids** que usaban
  las citas de prueba borradas aquí.
- Líneas 394 y 424 — `getPacienteById` y `getOrCreateByPersonaId` resuelven ids
  no-UUID contra esa lista local.

Es menos grave que el de citas (no se activa al fallar la consulta, solo cuando
la tabla viene vacía), pero tiene un radio de daño mayor porque hay código de
producción construido **encima** de esos ids falsos:

- `features/paciente/presentation/widgets/condiciones_medicas_card.dart:17-22`
  detecta ids no-UUID y pinta `_AvisoPacientePrueba` en lugar del expediente.
- `features/plan_tratamiento/presentation/widgets/planes_tratamiento_card.dart:21-25`
  oculta la tarjeta entera si el id no es UUID.
- `features/consulta/data/repositories/consulta_repository_impl.dart:50-55`
  lanza «No se puede crear una consulta para un paciente de prueba», y
  `features/consulta/presentation/cubit/consulta_cubit.dart:887-889` reconoce ese
  mensaje **por string** como caso especial.
- `features/paciente/presentation/cubit/paciente_cubit.dart:81` degrada el
  historial a lista vacía citando explícitamente los pacientes de prueba.

Quitar `_pacientesPrueba` obliga a desmontar esas cuatro adaptaciones, así que
no cabe en SD-161 sin desbordar su alcance. Debe abrirse su propio ticket.

## Sin hallazgos

Barrido de `catch` que devuelven listas/mapas literales en `lib/**/data/**`: los
únicos `return null` en bloques de captura (`usuario_repository_impl.dart:24`,
`cuenta_model.dart:99/115/124`, `paciente_remote_datasource.dart:558`) son
parseos opcionales, no sustituciones de datos. Ningún otro datasource inventa
registros.

## Datos de demo

No se movió ninguna cita de ejemplo a `supabase/seed.sql`. El seed actual
(SD-119) monta un día de caja y declara explícitamente que no toca `pacientes`;
sembrar citas exigiría crear antes personas, pacientes y doctores falsos, que es
justo el problema que este ticket elimina. Si más adelante hace falta una agenda
de demostración, el sitio es `supabase/seed.sql` y debe apoyarse en datos reales
de la instancia, nunca en `lib/`.
