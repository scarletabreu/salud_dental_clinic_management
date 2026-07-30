# HFX-CLIN-001 · Seguridad de RPC, RLS y datos sensibles

Fecha de cierre técnico: 2026-07-30.

## Resultado

El servidor vuelve a decidir quién puede leer o mutar cada recurso. Una anon
key sin sesión ya no ejecuta funciones de negocio ni accede directamente a
tablas públicas. Los wrappers `SECURITY DEFINER` validan sesión, perfil activo,
capacidad, autoría, existencia y estado antes de delegar en la transacción
existente.

Las conexiones internas de migración y mantenimiento conservan los contratos
históricos mediante `es_contexto_interno()`. La excepción requiere
`session_user` `postgres`/`service_role` **y** no admite `SET ROLE
authenticated`; una llamada PostgREST usa `authenticator` y nunca entra por
esta ruta.

## Inventario de funciones públicas

Se inspeccionaron las 47 firmas de `pg_proc` después de reconstruir la base.
La clasificación y los grants resultantes son:

| Clase | Funciones | Contrato |
|---|---|---|
| Solo trigger | `actualizar_stock_por_compra`, `bloquear_cancelacion_con_consulta_abierta`, `cancelar_citas_paciente_inactivo`, `fn_aplicar_movimiento_stock`, `handle_new_user`, `limpiar_diagnosticos_superficie`, `manejar_cita_cancelada`, `marcar_item_plan_ejecutado`, `realinear_consulta_al_reprogramar_cita`, `registrar_pago_en_caja`, `sync_disponibilidad_doctor`, `update_modified_column`, `update_timestamp`, `validar_caja_abierta`, `validar_cita_item_plan`, `validar_disponibilidad_doctor_simple`, `validar_doctor_activo`, `validar_fecha_nacimiento`, `validar_monto_cuotas`, `validar_monto_pago`, `verificar_item_plan_ejecutable` | owner y `service_role`; nunca cliente |
| Lectura/autorización autenticada | `perfil_actual`, `get_active_doctors`, `es_admin`, `es_doctor`, `es_asistente`, `puede_ver_consulta`, `puede_editar_consulta_propia` | `authenticated` y `service_role`; cada helper usa `auth.uid()` y baja lógica |
| Mutación clínica | las dos firmas de `crear_consulta_completa`, `finalizar_consulta` | clínico activo, actor igual al doctor del recurso y estado permitido |
| Mutación de caja/asistente | `generar_plan_cuotas`, `marcar_cuotas_vencidas`, `registrar_pago`, `recibir_compra` | admin o asistente activo; `recibir_compra` fija actor desde la sesión |
| Mutación administrativa | `ajustar_stock_consumible`, `registrar_mantenimiento_equipo`, `corregir_consulta_ajena` | admin activo; la corrección ajena solo admite notas/motivo y audita antes/después |
| Base interna | las ocho funciones `hfx_base_*` y `es_contexto_interno` | owner y `service_role`; sin `EXECUTE` para `authenticated` |

No quedan funciones con `EXECUTE` para `anon` ni funciones con el grant
implícito de `PUBLIC`. Los default privileges de funciones, tablas y secuencias
también quedaron cerrados.

## Matriz de autorización relevante

`Propia` significa que `doctor_id = auth.uid()` y que el perfil/recurso no está
dado de baja. Admin hereda identidad clínica, por lo que puede ejercer en sus
propias citas; su lectura administrativa global no le permite firmar por otro.

| Recurso / operación | Anon | Admin | Doctor | Asistente | Service role |
|---|---|---|---|---|---|
| Citas · SELECT | no | global | propia | global | global |
| Citas · INSERT/UPDATE/DELETE | no | global | propia | global | global |
| Vínculos cita-plan · SELECT | no | global | propia | global | global |
| Vínculos cita-plan · INSERT/DELETE | no | sí | no | sí | sí |
| Consultas · SELECT | no | global | propia | no | global |
| Consultas · INSERT/UPDATE | no | propia | propia | no | sí |
| Consulta ajena · corrección | no | RPC auditada | no | no | sí |
| Recetas, diagnósticos y tratamientos aplicados · SELECT | no | global | propia | no | global |
| Recetas, diagnósticos y tratamientos aplicados · escritura | no | propia | propia | no | sí |
| Documentos clínicos · SELECT/escritura | no | global/propia | propia | no | sí |
| Caja, pagos y cuotas · lectura | no | sí | sí | sí | sí |
| Pagos/cuotas · mutación RPC | no | sí | no | sí | sí |
| Compras · recepción RPC | no | sí | no | sí | sí |
| Stock y mantenimiento · mutación RPC | no | sí | no | no | sí |
| Usuarios · `password_hash` | no | no | no | no | sí |

Las tablas de catálogo clínico (medicinas, procedimientos, tratamientos,
diagnósticos y condiciones) mantienen lectura para clínicos; sus políticas no
conceden capacidades al asistente. Las tablas operativas conservan su matriz
existente y las mutaciones sensibles pasan además por wrappers autorizados.

## Storage

- `fotos-pacientes` continúa privado, con acceso autenticado a perfiles activos
  y validación del paciente indicado por la primera carpeta.
- `documentos-clinicos` dejó de ser público. Solo un clínico activo puede subir
  a `paciente/actor/archivo`; la policy compara el segundo segmento con
  `auth.uid()`.
- El cliente persiste la ruta privada, no una URL pública. Al copiar un enlace
  solicita una URL firmada válida durante cinco minutos.

## Datos sensibles y Edge Function

Se retiró `passwordHash` de todas las entidades, modelos, mappers y
constructores Dart. `authenticated` solo recibe un grant por columna sobre
`usuarios`, que excluye `password_hash`.

`AppLog.error` redacta UUID y registra únicamente el tipo de error. Se
eliminaron los `print` de respuestas Supabase, rutas de fotos, assets y
payloads. La búsqueda final no encontró impresiones directas fuera del
encapsulador.

`admin-crear-usuario` ahora:

1. acepta únicamente `POST` JSON con Bearer token;
2. valida allowlist CORS cuando está configurada;
3. resuelve el caller y exige admin activo;
4. valida rol y campos antes de usar Admin Auth;
5. usa service role solo dentro de la función;
6. revierte usuarios sin perfil;
7. devuelve códigos estables sin detalles internos;
8. audita actor, operación, recurso y rol, nunca la contraseña.

## Pruebas ofensivas y reconstrucción

- `hfx_clin_001_seguridad_rpc_rls_test.sql`: ACL, anon, asistente, autoría de
  doctor, cita/documento ajenos, corrección admin, ajuste de stock y baja
  lógica.
- `hfx_clin_001_rest_ofensivo.sh`: anon key, token inválido, receta de
  asistente, consulta ajena, trigger manual, Storage público, corrección
  auditada y ausencia de hashes.
- `validation_test.ts`: campos por rol, normalización y allowlist CORS.
- `hfx_clin_000_identidad_admin_doctor_test.sql`: admin ejerciendo clínica
  sobre su propia cita.

La prueba SQL no invoca una función revocada desde un bloque `DO` con rol
`anon`: esa combinación provoca un `SIGSEGV` reproducible en la imagen local de
PostgreSQL 17. La ACL se comprueba con `has_function_privilege` y la invocación
real se cubre por REST, que es la frontera de producción.

## Validación ejecutada

```text
supabase db reset --local                         OK
6 archivos supabase/tests/*.sql                  OK
hfx_clin_000_smoke_login_agenda.sh               OK
hfx_clin_001_rest_ofensivo.sh                    OK
deno check admin-crear-usuario                    OK
deno test validation_test.ts                     3/3
flutter analyze                                  0 errores
dart run tool/ci/verificar_pruebas.dart           sin regresiones
```

La suite Flutter conserva un único fallo conocido de persistencia clínica,
registrado en `tool/ci/pruebas_conocidas_rojas.txt` y asignado a HFX-CLIN-002.
El analyzer conserva diez warnings preexistentes fuera de los archivos de este
hotfix. `supabase db lint` no reporta errores; conserva un warning histórico
porque `hfx_base_recibir_compra` mantiene el parámetro público
`p_usuario_id` por compatibilidad aunque la autoría se valida en el wrapper.
