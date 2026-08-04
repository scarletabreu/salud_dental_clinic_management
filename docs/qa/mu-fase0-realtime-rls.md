# MU-0 · Verificación: Realtime entrega eventos recortados por RLS

**Fecha:** 4 ago 2026 · **Stack:** local (`supabase start`) · **Rama:** `MU-0-cimientos-realtime`

## Qué se verificó y por qué

Todo el plan multiusuario descansa sobre una premisa: el recorte por rol de los
eventos realtime lo hace Postgres con las policies RLS (`citas_select` de d11),
no el cliente. Si eso no fuera cierto, cada pantalla tendría que re-filtrar
eventos ajenos y un error dejaría datos de un doctor en la sesión de otro.

## Cómo reproducirla

```bash
supabase start          # stack local
tool/e2e/realtime_rls.sh
```

El arnés aplica el seed de certificación (admin y doctora con contraseña
conocida), abre **dos sesiones reales** con el cliente de Supabase, suscribe
ambas a `postgres_changes` de `public.citas` y toca por psql (rol `postgres`,
fuera de RLS) una cita de la doctora y una del admin.

## Resultado (4 ago 2026)

```
✓ Sesiones abiertas: admin y doctora
✓ Ambas sesiones suscritas a postgres_changes de citas
✓ cita de la doctora → la ve el admin (ve todo)
✓ cita de la doctora → la ve la doctora (es suya)
✓ cita del admin → la ve el admin
✓ cita del admin → a la doctora NO le llega (RLS)
✓ Realtime local entrega eventos con recorte RLS por rol
```

La premisa queda demostrada en local: el contenedor Realtime evalúa las
policies por suscriptor y la doctora nunca recibe eventos de citas ajenas.

## Estado de la publicación

`20260818090000_mu0_realtime_multiusuario.sql` agrega a `supabase_realtime`:
`cajas`, `citas`, `cuentas`, `personas`, `pacientes`, `consumibles`,
`doctor_asistentes`, `reglas_clinicas` (además de `movimientos_caja`, que ya
estaba). `usuarios` queda fuera adrede (grants de columna vs. filas completas
de realtime); `REPLICA IDENTITY` no se toca (borrados del dominio son soft).

## Pendiente que solo el dueño puede autorizar

- **Aplicar la migración en producción.** `tool/produccion/deriva_esquema.sh`
  reporta hoy exactamente esas 8 sentencias `ALTER PUBLICATION` sólo en local
  y ninguna otra deriva: es el estado intermedio esperado hasta el despliegue.
  Nota: el dump de `supabase db dump` **sí** incluye la membresía de la
  publicación, así que el gate cubre este cambio (mejor de lo que suponía la
  línea base de HFX-CLIN-000).
- **Verificar entrega de eventos en producción.** La instancia es Supabase
  hosted (`*.supabase.co`), donde Realtime está habilitado por defecto, pero
  la prueba de entrega real implica escribir una fila: se hará junto con la
  aplicación de la migración, con autorización explícita.
