#!/usr/bin/env bash
# HFX-CLIN-002 · dos cierres simultáneos sobre la misma consulta.
#
# La prueba SQL corre dentro de una transacción y por eso no puede observar el
# bloqueo entre sesiones. Aquí se abren dos conexiones reales: la primera
# mantiene la consulta bloqueada mientras cierra; la segunda entra después y
# tiene que encontrarse el cierre ya hecho, no crear otra cuenta ni volver a
# descontar inventario.
#
# Uso:  supabase/tests/hfx_clin_002_concurrencia.sh [DATABASE_URL]

set -euo pipefail

DB_URL="${1:-${DATABASE_URL_LOCAL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}}"

CONSULTA='40000000-0000-4000-8000-000000000001'
CITA='40000000-0000-4000-8000-000000000002'
PACIENTE='40000000-0000-4000-8000-000000000003'
DOCTOR='40000000-0000-4000-8000-000000000004'
CONSUMIBLE='40000000-0000-4000-8000-000000000005'
TRATAMIENTO='40000000-0000-4000-8000-000000000006'

psql_q() { psql "$DB_URL" -v ON_ERROR_STOP=1 -qtA "$@"; }

limpiar() {
  psql "$DB_URL" -qtA >/dev/null 2>&1 <<SQL || true
delete from public.auditoria_clinica where consulta_id = '$CONSULTA';
delete from public.movimientos_stock_consumible where consulta_id = '$CONSULTA';
delete from public.items_cuenta where cuenta_id in (select id from public.cuentas where consulta_id = '$CONSULTA');
delete from public.cuentas where consulta_id = '$CONSULTA';
delete from public.consumos_consulta where consulta_id = '$CONSULTA';
delete from public.tratamientos_aplicados where consulta_id = '$CONSULTA';
delete from public.diagnosticos_aplicados where consulta_id = '$CONSULTA';
delete from public.recetas where consulta_id = '$CONSULTA';
delete from public.dientes where odontograma_id in (select id from public.odontogramas where consulta_id = '$CONSULTA');
delete from public.odontogramas where consulta_id = '$CONSULTA';
delete from public.consultas where id = '$CONSULTA';
delete from public.citas where id = '$CITA';
delete from public.consumibles where id = '$CONSUMIBLE';
delete from public.tratamientos where id = '$TRATAMIENTO';
delete from public.pacientes where id = '$PACIENTE';
delete from public.personas where id = '$PACIENTE';
delete from public.doctores where id = '$DOCTOR';
delete from public.usuarios where id = '$DOCTOR';
delete from auth.users where id = '$DOCTOR';
SQL
}

trap limpiar EXIT
limpiar

psql_q >/dev/null <<SQL
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  created_at, updated_at, raw_user_meta_data
) values (
  '$DOCTOR', '00000000-0000-0000-0000-000000000000', 'authenticated',
  'authenticated', 'hfx002-conc@test.local', 'x', now(), now(),
  '{"rol":"doctor","nombre":"Clara","apellido":"Concurrente","fecha_nacimiento":"1985-01-01","cedula":"HFX002-C","username":"hfx002_c","especialidad":"General"}'
);

insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
values ('$PACIENTE', 'Paco', 'Concurrente', date '1990-01-01', 'HFX002-PC');
insert into public.pacientes (id, genero) values ('$PACIENTE', 'masculino');

insert into public.citas (id, persona_id, doctor_id, fecha_hora, duracion_minutos)
values ('$CITA', '$PACIENTE', '$DOCTOR', now() + interval '1 day', 30);

insert into public.consultas (id, paciente_id, doctor_id, cita_id, fecha)
values ('$CONSULTA', '$PACIENTE', '$DOCTOR', '$CITA', now());

insert into public.tratamientos (id, nombre, costo, alcance)
values ('$TRATAMIENTO', 'Resina concurrencia', 1200, 'diente');

insert into public.consumibles (id, nombre, stock_actual, stock_minimo, precio)
values ('$CONSUMIBLE', 'Gasas concurrencia', 10, 1, 20);

insert into public.tratamientos_aplicados (
  tratamiento_id, consulta_id, precio_aplicado, estado, doctor_ejecuta_id
) values ('$TRATAMIENTO', '$CONSULTA', 1200, 'aplicado', '$DOCTOR');

insert into public.consumos_consulta (consulta_id, consumible_id, nombre, cantidad)
values ('$CONSULTA', '$CONSUMIBLE', 'Gasas concurrencia', 4);
SQL

# Sesión A: cierra y retiene el bloqueo unos segundos antes de confirmar.
psql "$DB_URL" -v ON_ERROR_STOP=1 -qtA >/dev/null <<SQL &
begin;
select public.cerrar_consulta('$CONSULTA', null, '{}'::jsonb, 'clave-a');
select pg_sleep(3);
commit;
SQL
PID_A=$!

sleep 1

# Sesión B: entra mientras A todavía no confirmó. Debe esperar el bloqueo y,
# al liberarse, encontrarse la consulta ya cerrada por otro intento lógico.
SALIDA_B=$(psql "$DB_URL" -qtA <<SQL 2>&1 || true
select public.cerrar_consulta('$CONSULTA', null, '{}'::jsonb, 'clave-b');
SQL
)

wait "$PID_A"

if ! grep -q "ya fue finalizada" <<<"$SALIDA_B"; then
  echo "FALLO: el segundo cierre no fue rechazado. Salida: $SALIDA_B" >&2
  exit 1
fi

CUENTAS=$(psql_q -c "select count(*) from public.cuentas where consulta_id = '$CONSULTA' and deleted_at is null;")
ITEMS=$(psql_q -c "select count(*) from public.items_cuenta ic join public.cuentas c on c.id = ic.cuenta_id where c.consulta_id = '$CONSULTA';")
MOVIMIENTOS=$(psql_q -c "select count(*) from public.movimientos_stock_consumible where consulta_id = '$CONSULTA';")
STOCK=$(psql_q -c "select stock_actual from public.consumibles where id = '$CONSUMIBLE';")
CITA_ESTADO=$(psql_q -c "select estado from public.citas where id = '$CITA';")

[ "$CUENTAS" = "1" ]     || { echo "FALLO: se crearon $CUENTAS cuentas" >&2; exit 1; }
[ "$ITEMS" = "1" ]       || { echo "FALLO: la cuenta quedó con $ITEMS ítems" >&2; exit 1; }
[ "$MOVIMIENTOS" = "1" ] || { echo "FALLO: se registraron $MOVIMIENTOS movimientos de stock" >&2; exit 1; }
[ "$STOCK" = "6" ]       || { echo "FALLO: el stock quedó en $STOCK (esperado 6)" >&2; exit 1; }
[ "$CITA_ESTADO" = "completada" ] || { echo "FALLO: la cita quedó en $CITA_ESTADO" >&2; exit 1; }

# Reintentar con la clave que sí cerró devuelve el mismo resultado.
REINTENTO=$(psql_q -c "select public.cerrar_consulta('$CONSULTA', null, '{}'::jsonb, 'clave-a') ->> 'cuenta_id';")
CUENTAS_FINAL=$(psql_q -c "select count(*) from public.cuentas where consulta_id = '$CONSULTA' and deleted_at is null;")
STOCK_FINAL=$(psql_q -c "select stock_actual from public.consumibles where id = '$CONSUMIBLE';")

[ -n "$REINTENTO" ]        || { echo "FALLO: el reintento no devolvió la cuenta" >&2; exit 1; }
[ "$CUENTAS_FINAL" = "1" ] || { echo "FALLO: el reintento duplicó la cuenta" >&2; exit 1; }
[ "$STOCK_FINAL" = "6" ]   || { echo "FALLO: el reintento volvió a descontar stock" >&2; exit 1; }

echo "OK · dos cierres simultáneos producen una sola cuenta, un solo movimiento y una cita completada"
