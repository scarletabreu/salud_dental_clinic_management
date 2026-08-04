# MU-6 · Cierre del plan multiusuario: jornada a tres sesiones

**Fecha:** 4 ago 2026 · **Stack:** local (`supabase start`) · **Rama:** `MU-6-red-de-seguridad`

## Qué demuestra

La jornada completa de la clínica ejecutada por **tres sesiones autenticadas
simultáneas** (admin, doctora, asistente), verificando por el mismo transporte
que consumen las pantallas —eventos `postgres_changes` con RLS— que:

- cada acción de una sesión llega a las demás **sin interacción y en <2 s**
  (medido: 0–510 ms, muy por debajo del criterio);
- **ningún rol recibe eventos fuera de su alcance**.

## Cómo reproducirla

```bash
supabase start
tool/e2e/jornada_multiusuario.sh
```

El wrapper aplica el seed de certificación, limpia los restos de corridas
anteriores (todo lo del arnés lleva la marca `MU-6 jornada`) y ejecuta
`tool/e2e/jornada_multiusuario.dart`. La evidencia queda en
`docs/qa/e2e-ui/jornada_multiusuario.log`.

## Resultado (4 ago 2026)

```
✓ Tres sesiones suscritas a citas, cajas, cuentas, doctor_asistentes, personas (RLS activo)
✓ la asignación de la doctora llega a la sesión del asistente (255 ms)
✓ la llegada marcada por el asistente aparece en la sesión de la doctora (458 ms)
✓ …y también en la del admin (0 ms)
✓ la reagenda hecha por el admin llega a la agenda de la doctora (459 ms)
✓ la apertura de caja del asistente llega a la sesión del admin (510 ms)
✓ la cuenta de la consulta finalizada aparece en el mostrador del asistente (458 ms)
✓ a la doctora NO le llega la cuenta de un paciente que no es suyo (RLS)
✓ la persona recién creada llega al directorio del asistente (0 ms)
✓ el cobro del asistente actualiza la cuenta en la sesión del admin (510 ms)
✓ el cierre de caja se propaga a la sesión del admin (510 ms)
✓ Jornada multiusuario completa: cada sesión vio lo suyo y nada ajeno
```

## Decisiones del arnés

- **La consulta finalizada se simula por psql** (consulta + cuenta con la
  marca del arnés): el cierre clínico completo con su payload versionado ya lo
  cubre el arnés de UI de certificación; aquí lo que se verifica es la
  propagación de su efecto observable, la pre-factura.
- **El alcance negativo se prueba con un paciente sin relación con la
  doctora.** `puede_ver_paciente` le da a recepción el mostrador completo por
  diseño, así que la aserción correcta es que la *doctora* no reciba cuentas
  de pacientes ajenos — y no las recibe.
- Los pasos de mutación usan la sesión del rol que lo haría en la vida real
  (RPCs `registrar_llegada_cita` y `registrar_pago`, insert/update de `cajas`
  con el cliente del asistente, reagenda con el del admin).

## Cobertura de la fase 6

- **6.1 Resume:** `_DashboardShellViewState` es `WidgetsBindingObserver`; al
  volver del background dispara `SenalesRealtime.recargarTodo()` — el mismo
  camino que la reconexión del websocket (MU-0).
- **6.2 Reentrada a pantallas retenidas:** no hay marcado de «sucia»: los
  cubits de las pantallas retenidas escuchan las señales y recargan con
  debounce cuando su dominio cambia de verdad, nunca por navegar (SD-132).
  Al volver, la pantalla ya está al día; la decisión está documentada en
  `LazyDestinationStack`.
- **6.3 Cierre E2E multiusuario:** esta corrida.
