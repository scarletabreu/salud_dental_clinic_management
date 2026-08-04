-- SD-150 · Odontograma unificado sobre diagnósticos y tratamientos.
--
-- Ejecutar después de SD-141. Es aditiva e idempotente: conserva el jsonb
-- únicamente para tejidos blandos y transforma sus hallazgos dentales en
-- filas con consulta, fecha y pieza de origen.

-- 1. El eje de diagnósticos queda tan completo como tratamientos_aplicados.
alter table public.diagnosticos_aplicados
  add column if not exists consulta_id uuid references public.consultas(id),
  add column if not exists diente_id uuid references public.dientes(id),
  add column if not exists superficie tipo_superficie,
  add column if not exists origen text not null default 'preexistente';

-- La ausencia de una pieza es parte del estado clínico normalizado. La app la
-- consulta y actualiza junto con las anotaciones de cada diente.
alter table public.dientes
  add column if not exists esta_ausente boolean not null default false;

create index if not exists idx_diagnosticos_aplicados_consulta_id
  on public.diagnosticos_aplicados (consulta_id);
create index if not exists idx_diagnosticos_aplicados_diente_id
  on public.diagnosticos_aplicados (diente_id);

-- La clave es configuración clínica: ninguna vista codifica el catálogo.
alter table public.diagnosticos
  add column if not exists clave_odontograma text;
alter table public.tratamientos
  add column if not exists clave_odontograma text;

-- Una indicación se conserva en el plan, pero no se factura hasta aplicarse.
alter table public.tratamientos_aplicados
  add column if not exists estado text not null default 'aplicado';

create index if not exists idx_tratamientos_aplicados_estado
  on public.tratamientos_aplicados (consulta_id, estado)
  where deleted_at is null;

-- 2. Catálogo inicial de las claves impresas. No se duplica si la clínica ya
--    configuró una entrada con la misma clave.
insert into public.diagnosticos (
  nombre, descripcion, severidad_default, alcance, categoria,
  clave_odontograma, created_at, updated_at
)
select seed.nombre, seed.descripcion,
       seed.severidad::public.severidad_diagnosis,
       seed.alcance::public.alcance,
       seed.categoria::public.categoria_diagnosis,
       seed.clave, now(), now()
from (values
  ('Cariada', 'Lesión cariosa registrada en el odontograma.', 'moderada', 'puntual', 'caries', 'cariada'),
  ('Pérdida dental', 'Pieza dental ausente o perdida.', 'grave', 'diente', 'patologia_atm', 'perdida'),
  ('No erupcionado', 'Pieza que aún no ha erupcionado.', 'leve', 'diente', 'ortodoncia', 'no_erupcionado'),
  ('Restaurada preexistente', 'Restauración realizada antes de la consulta.', 'leve', 'puntual', 'estetica', 'restaurada'),
  ('Pulpectomía/Pulpotomía preexistente', 'Tratamiento pulpar previo.', 'leve', 'diente', 'endodoncia', 'pulpectomia_pulpotomia')
) as seed(nombre, descripcion, severidad, alcance, categoria, clave)
where not exists (
  select 1 from public.diagnosticos d
  where d.clave_odontograma = seed.clave and d.deleted_at is null
);

insert into public.tratamientos (
  nombre, descripcion, costo, alcance, clave_odontograma, created_at, updated_at
)
select 'Extracción indicada',
       'Procedimiento indicado; se factura solo al ejecutarse.',
       0, 'diente', 'extraccion_indicada', now(), now()
where not exists (
  select 1 from public.tratamientos t
  where t.clave_odontograma = 'extraccion_indicada' and t.deleted_at is null
);

-- 3. Toda consulta, incluida una anterior a esta migración, tiene 52 piezas.
--    El WHERE evita depender de un índice único que las instalaciones antiguas
--    todavía pueden no tener.
with piezas(fdi_code) as (
  values
    (51), (52), (53), (54), (55), (61), (62), (63), (64), (65),
    (71), (72), (73), (74), (75), (81), (82), (83), (84), (85)
), nuevas as (
  insert into public.dientes (odontograma_id, fdi_code, created_at, updated_at)
  select o.id, p.fdi_code, now(), now()
  from public.odontogramas o cross join piezas p
  where o.deleted_at is null
    and not exists (
      select 1 from public.dientes d
      where d.odontograma_id = o.id and d.fdi_code = p.fdi_code
    )
  returning id, fdi_code
)
insert into public.superficies (
  diente_id, tipo_superficie, tratamientos_ids, created_at, updated_at
)
select n.id, cara.tipo::tipo_superficie, '{}'::uuid[], now(), now()
from nuevas n
cross join lateral unnest(array[
  'mesial',
  'distal',
  'vestibular',
  case when n.fdi_code between 51 and 68 then 'palatina' else 'lingual' end,
  case when n.fdi_code % 10 <= 3 then 'incisal' else 'oclusal' end
]) as cara(tipo);

-- 4. Backfill de SD-141. Una clave puntual con varias caras produce una fila
--    por cara; las de pieza completa conservan superficie NULL.
with hallazgos as (
  select
    o.id as odontograma_id,
    o.consulta_id,
    c.fecha,
    (pieza.key)::int as fdi_code,
    marca.value as marca
  from public.odontogramas o
  join public.consultas c on c.id = o.consulta_id
  cross join lateral jsonb_each(coalesce(o.evaluacion_clinica -> 'hallazgos', '{}'::jsonb)) pieza
  cross join lateral jsonb_array_elements(pieza.value) marca
), diagnosticos as (
  select
    h.*, d.id as diagnosis_id,
    case h.marca ->> 'estado'
      when 'cariada' then 'moderada'
      when 'perdida' then 'grave'
      else 'leve'
    end as severidad,
    superficie.value #>> '{}' as superficie
  from hallazgos h
  join public.diagnosticos d
    on d.clave_odontograma = h.marca ->> 'estado'
   and d.deleted_at is null
  left join lateral jsonb_array_elements(coalesce(h.marca -> 'superficies', '[null]'::jsonb)) superficie
    on (h.marca -> 'superficies' is not null)
  where h.marca ->> 'estado' <> 'extraccion_indicada'
)
insert into public.diagnosticos_aplicados (
  diagnosis_id, consulta_id, diente_id, superficie, severidad,
  fecha_aplicacion, notas, origen, created_at, updated_at
)
select d.diagnosis_id, d.consulta_id, pieza.id,
       nullif(d.superficie, '')::tipo_superficie,
       d.severidad::severidad_diagnosis, coalesce(d.fecha, now()),
       coalesce(d.marca ->> 'detalle', ''), 'preexistente', now(), now()
from diagnosticos d
join public.dientes pieza
  on pieza.odontograma_id = d.odontograma_id and pieza.fdi_code = d.fdi_code
where not exists (
  select 1 from public.diagnosticos_aplicados da
  where da.consulta_id = d.consulta_id
    and da.diente_id = pieza.id
    and da.diagnosis_id = d.diagnosis_id
    and da.superficie is not distinct from nullif(d.superficie, '')::tipo_superficie
    and da.deleted_at is null
);

with indicaciones as (
  select o.id as odontograma_id, o.consulta_id, (pieza.key)::int as fdi_code,
         marca.value as marca
  from public.odontogramas o
  cross join lateral jsonb_each(coalesce(o.evaluacion_clinica -> 'hallazgos', '{}'::jsonb)) pieza
  cross join lateral jsonb_array_elements(pieza.value) marca
  where marca.value ->> 'estado' = 'extraccion_indicada'
)
insert into public.tratamientos_aplicados (
  tratamiento_id, consulta_id, diente_id, esta_terminado, es_continuo,
  precio_aplicado, notas, estado, created_at, updated_at
)
select t.id, i.consulta_id, pieza.id, false, false, 0,
       coalesce(i.marca ->> 'detalle', ''), 'indicado', now(), now()
from indicaciones i
join public.tratamientos t
  on t.clave_odontograma = 'extraccion_indicada' and t.deleted_at is null
join public.dientes pieza
  on pieza.odontograma_id = i.odontograma_id and pieza.fdi_code = i.fdi_code
where not exists (
  select 1 from public.tratamientos_aplicados ta
  where ta.consulta_id = i.consulta_id
    and ta.diente_id = pieza.id
    and ta.tratamiento_id = t.id
    and ta.estado = 'indicado'
    and ta.deleted_at is null
);

-- El jsonb conserva exclusivamente tejidos blandos cuando ya se migró cada
-- marca dental a una fila auditable.
update public.odontogramas
set evaluacion_clinica = jsonb_build_object(
      'hallazgos', '{}'::jsonb,
      'tejidos_blandos', coalesce(evaluacion_clinica -> 'tejidos_blandos', '{}'::jsonb)
    ),
    updated_at = now()
where coalesce(evaluacion_clinica -> 'hallazgos', '{}'::jsonb) <> '{}'::jsonb;

-- 5. La pre-factura cobra exclusivamente procedimientos ejecutados.
create or replace function finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'Contado',
  p_nota text default null
) returns uuid
language plpgsql
security definer
as $$
declare
  v_paciente_id uuid;
  v_cita_id uuid;
  v_cuenta_id uuid;
  v_monto_total numeric(12,2);
begin
  select paciente_id, cita_id into v_paciente_id, v_cita_id
  from consultas where id = p_consulta_id and deleted_at is null;
  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  select id into v_cuenta_id from cuentas
  where consulta_id = p_consulta_id and deleted_at is null limit 1;
  if v_cuenta_id is not null then return v_cuenta_id; end if;

  select coalesce(sum(precio_aplicado), 0) into v_monto_total
  from tratamientos_aplicados
  where consulta_id = p_consulta_id
    and deleted_at is null
    and coalesce(estado, 'aplicado') = 'aplicado';

  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  ) values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, p_metodo_pago,
    now(), p_nota, now(), now()
  ) returning id into v_cuenta_id;

  insert into items_cuenta (
    cuenta_id, descripcion, precio_unitario, cantidad, created_at, updated_at
  )
  select v_cuenta_id, coalesce(t.nombre, 'Tratamiento'),
         coalesce(ta.precio_aplicado, 0), 1, now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') = 'aplicado';

  if v_cita_id is not null then
    update citas set estado = 'completada'::estado_cita, updated_at = now()
    where id = v_cita_id;
  end if;
  return v_cuenta_id;
end;
$$;

grant execute on function finalizar_consulta(uuid, text, text) to authenticated, anon;
