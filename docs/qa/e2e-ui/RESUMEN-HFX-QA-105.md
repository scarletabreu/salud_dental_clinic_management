# HFX-QA-105 · Qué valida cada paso, y qué NO

Fase 5 del plan `docs/QA-2026-08-01-plan-correccion.md`. Ejecutado el 1 ago 2026
contra el stack local, headless.

```bash
tool/e2e/jornada_ui.sh            # dos jornadas de interfaz + comprobación en BD
tool/e2e/controles_negativos.sh   # 14 intentos por API con el token de cada rol
```

## Cobertura por defecto

| # | Defecto | Dónde queda validado | Estado |
|---|---|---|---|
| D1 | Detalle de Cuenta muere con «Capacidad de caja requerida» | `test/features/cuota/cuota_repository_impl_test.dart` (3 pruebas) + control negativo «el doctor no ejecuta marcar_cuotas_vencidas» | ✅ |
| D2 | Perfiles: embed ambiguo + error de sección | `test/features/personal/perfiles_fallo_parcial_test.dart` (4) + jornada admin abre Perfiles | ✅ |
| D3 | Pacientes no cargan (`pacientes_seguro`) | Jornada doctora: Pacientes lista sin el error; `hfx_qa_100_esquema_produccion_test.sql` OK 7 | ✅ |
| D4 | Consultas muestran `Paciente #uuid` | Jornada doctora + `consultas_nombres_directorio_test.dart` (3) | ✅ |
| D5 | Registros sin pieza invisibles | `expediente_pdf_test.dart` «lo registrado sin pieza aparece en el expediente» | ✅ |
| D6a | Odontodiagrama del PDF vacío | `expediente_pdf_test.dart`, dos pruebas diferenciales | ✅ |
| D6b | Catálogo sin `clave_odontograma` | Migración `20260812090000`, que informa lo que queda sin clave al aplicarse | ⚠️ ver abajo |
| D6c | Detalle proyecta la evaluación cruda | Cambio de una línea a `evaluacionProyectada` | ⚠️ sin prueba propia |
| D7 | «Error al terminar consulta (sale como completada)» | `ConsultaCerradaFailure` tratado igual en ambos caminos | ⚠️ sin prueba propia |
| D8 | Doctor edita catálogos y ve precios | Jornada doctora (sin «Nuevo servicio», sin «PRECIO BASE») + jornada admin (control positivo) + 4 controles negativos + `hfx_qa_103` OK 1-2 | ✅ |
| D9 | Doctor ve Cuentas por Cobrar | Jornada doctora + `responsive_shell_test.dart` | ✅ |
| D10 | Doctor no agenda cita normal | `acciones_por_rol_test.dart` + `hfx_qa_103` OK 7 | ✅ |
| D11 | Alcance de consultas ajenas (TEMPORAL) | Control negativo (lee sí, escribe no) + `hfx_qa_103` OK 3 + `hfx_clin_005` OK 9 | ✅ |
| D12 | Alcance y estados del asistente | 5 controles negativos + `hfx_qa_103` OK 4-6 | ✅ |
| D13 | Caja chica | Cambios de propagación de error y tolerancia decimal | ⚠️ sin prueba propia |
| D14 | Admin no puede iniciar su consulta | `PuedeIniciarConsulta`, criterio único para las tres vistas | ⚠️ sin prueba propia |
| D15 | Filtro de doctor en agenda | `filtro_doctor_agenda_test.dart` (4) | ✅ |
| D16 | Búsqueda por cédula | Cambio en `searchPersonas` | ⚠️ sin prueba propia |
| D17 | Rango de fechas y opción del modal | Propagación de `formatoInicial` y `rango` | ⚠️ sin prueba propia |
| D18 | Botón de expediente imposible | `paciente_responsive_test.dart` | ✅ |
| D19 | Equipos duplicado | Jornada admin (no hay destino de primer nivel) + `responsive_shell_test.dart` | ✅ |
| D20 | «Admin que tiene consultas dice que no» | Misma corrección que D3/D4 | ✅ |

## Lo que este E2E NO cubre, y por qué

Conviene decirlo claro para que nadie lea «jornada superada» como «todo
probado».

1. **La jornada clínica completa por interfaz.** Registrar diagnósticos y
   tratamientos por pieza, cerrar la consulta y generar el PDF desde la
   pantalla no está automatizado. Lo que sí está: el cierre transaccional
   (`hfx_clin_002_cierre_transaccional_test.sql`), el contenido del PDF
   (`expediente_pdf_test.dart`) y la persistencia sin pieza. Falta el hilo que
   los une pulsando botones.

2. **La jornada de la asistente por interfaz.** Su matriz está probada por API
   (5 controles negativos) y en SQL, que es donde se impone; no por pantalla.

3. **La pestaña Equipos dentro de Inventario.** El `TabBar` no se pinta de
   forma observable en el arnés headless. Se afirma la mitad que importaba —que
   Equipos ya no es destino de primer nivel— y la otra la fija
   `responsive_shell_test.dart` sobre la estructura de navegación.

4. **D6b en producción.** La siembra de `clave_odontograma` va por patrones de
   nombre sobre el catálogo real, que el repositorio no versiona y que en local
   está vacío. Al aplicarla en producción imprime cuántas filas quedaron sin
   clave: **hay que leer ese aviso** y decidir si falta algún patrón.

5. **El escenario «caja de ayer quedó abierta» (D13).** Los cambios están
   hechos —el error real se propaga y el cierre compara con tolerancia— pero no
   se reprodujo el escenario completo.

## Evidencia archivada

- `jornada_ui.log` — jornada del admin-doctor.
- `jornada_ui_doctora.log` — jornada de la doctora.
- `controles_negativos.log` — 14 intentos por API, todos rechazados como debe.
- `seed.log`, `overlay.log`, `chromedriver.log` — preparación del entorno.
