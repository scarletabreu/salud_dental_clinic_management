-- Lo que las tres jornadas dejaron escrito en la base.
--
-- La pantalla puede decir «guardado» y no haber escrito nada: esta es la
-- última palabra. Cada línea sale como `clave|valor`.

\pset tuples_only on
\pset format unaligned
\pset fieldsep '|'

-- Consultas cerradas de la jornada de la doctora.
select 'consulta.' || p.nombre || '.finalizada', c.finalizada::text
  from public.consultas c
  join public.personas p on p.id = c.paciente_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

-- Fecha de la consulta = hoy en la zona de la clínica (el contenedor de
-- Postgres corre en UTC; comparar sin convertir da falsos negativos).
select 'consulta.' || p.nombre || '.es_de_hoy',
       ((c.fecha at time zone 'America/Santo_Domingo')::date
        = (current_timestamp at time zone 'America/Santo_Domingo')::date)::text
  from public.consultas c
  join public.personas p on p.id = c.paciente_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

-- F1-06 · los signos vitales tienen fila estructurada, no sólo el jsonb.
select 'vitales.' || p.nombre || '.filas', count(sv.id)::text
  from public.consultas c
  join public.personas p on p.id = c.paciente_id
  left join public.signos_vitales_consulta sv on sv.consulta_id = c.id
 where c.motivo_consulta like 'VERIF %'
 group by p.nombre
 order by 1;

-- Odontograma y tratamiento aplicado con su precio congelado.
select 'tratamiento.' || p.nombre || '.' || coalesce(ta.diente_id::text, 'global'),
       coalesce(ta.precio_aplicado, -1)::text
  from public.tratamientos_aplicados ta
  join public.consultas c on c.id = ta.consulta_id
  join public.personas p on p.id = c.paciente_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

-- Renglones de la receta. La fuente es el JSONB `recetas.items_receta`; la
-- tabla normalizada del mismo nombre está vacía a propósito (F4-04 del audit,
-- aceptada: ninguna función de la base inserta en ella).
select 'receta.' || p.nombre || '.renglones',
       jsonb_array_length(coalesce(r.items_receta, '[]'::jsonb))::text
  from public.recetas r
  join public.consultas c on c.id = r.consulta_id
  join public.personas p on p.id = c.paciente_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

select 'receta.tabla_normalizada', count(*)::text from public.items_receta;

-- F2-02 · la cuenta cobra el tratamiento aplicado, no cero.
select 'cuenta.' || p.nombre || '.total', cu.monto_total::text
  from public.cuentas cu
  join public.personas p on p.id = cu.paciente_id
  join public.consultas c on c.id = cu.consulta_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

select 'cuenta.' || p.nombre || '.estado', cu.estado
  from public.cuentas cu
  join public.personas p on p.id = cu.paciente_id
  join public.consultas c on c.id = cu.consulta_id
 where c.motivo_consulta like 'VERIF %'
 order by 1;

-- F2-03 · el método de pago elegido se guarda tal cual.
select 'pago.' || p.nombre || '.' || pg.estado::text,
       pg.monto::text || ' via ' || coalesce(pg.metodo_pago::text, 'NULO')
  from public.pagos pg
  join public.cuentas cu on cu.id = pg.cuenta_id
  join public.personas p on p.id = cu.paciente_id
 order by 1;

-- S10/F2-04 · el cobro entra en el arqueo del día.
select 'caja.movimiento.' || mc.tipo::text, mc.monto::text || ' · ' || coalesce(mc.descripcion, '')
  from public.movimientos_caja mc
  join public.cajas cj on cj.id = mc.caja_diaria_id
 where cj.fecha_civil = current_date
 order by mc.fecha;

-- I1 · la compra recibida sube el stock por el libro de movimientos.
select 'compra.estado', c.estado::text from public.compras c order by c.created_at desc limit 1;

select 'stock.' || co.nombre, co.stock_actual::text
  from public.consumibles co
 where co.nombre = 'Gutapercha punta F2';

select 'movimiento_stock.' || ms.motivo,
       ms.stock_anterior::text || ' → ' || ms.stock_nuevo::text
  from public.movimientos_stock_consumible ms
 order by ms.created_at desc limit 3;

-- Estado final de la agenda de hoy.
select 'cita.' || p.nombre || '.estado', ci.estado::text
  from public.citas ci
  join public.personas p on p.id = ci.persona_id
 where ci.fecha_hora::date = current_date
 order by 1;

-- Altas hechas por la interfaz.
select 'alta.' || p.nombre || ' ' || p.apellido, coalesce(r.tipo_sangre::text, 'SIN RECORD')
  from public.personas p
  join public.pacientes pa on pa.id = p.id
  left join public.records r on r.paciente_id = p.id
 where p.apellido in ('Encarnación E2E', 'Recepción E2E')
   and p.deleted_at is null
 order by 1;
