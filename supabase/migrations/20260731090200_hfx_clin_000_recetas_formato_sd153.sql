-- ============================================================================
--  HFX-CLIN-000 · Formato de recetas (SD-153) versionado
--
--  La instancia lleva tiempo con el formato nuevo —una receta es una cabecera
--  con sus medicinas dentro de `items_receta`— pero ese cambio nunca llegó al
--  repositorio. En una base reconstruida `recetas` conserva el formato viejo
--  (una medicina por fila, con `medicina_id`, `titulo`, `dosis`, `frecuencia`,
--  `indicaciones` y `duracion` NOT NULL), así que el insert del cliente, que no
--  manda ninguna de esas columnas, muere con una violación de NOT NULL.
--
--  Esta migración deja la tabla en el formato que el cliente ya usa, sin
--  destruir las filas antiguas: las columnas del formato anterior se conservan
--  y sólo dejan de ser obligatorias.
-- ============================================================================

alter table public.recetas
  add column if not exists doctor_id                        uuid,
  add column if not exists fecha_emision                    timestamptz,
  add column if not exists indicaciones_generales           text,
  add column if not exists justificacion_contraindicaciones text,
  add column if not exists estado                           text,
  add column if not exists motivo_anulacion                 text,
  add column if not exists receta_reemplazada_id            uuid,
  add column if not exists items_receta                     jsonb;

alter table public.recetas
  alter column fecha_emision set default now(),
  alter column estado        set default 'activa',
  alter column items_receta  set default '[]'::jsonb;

-- Las filas del formato antiguo siguen siendo válidas: se les da fecha y
-- estado para que el listado no tenga que adivinarlos.
update public.recetas
   set fecha_emision = coalesce(fecha_emision, created_at),
       estado        = coalesce(estado, 'activa'),
       items_receta  = coalesce(items_receta, '[]'::jsonb)
 where fecha_emision is null or estado is null or items_receta is null;

-- El formato nuevo no rellena estas columnas: dejarlas obligatorias es lo que
-- rompe el insert del cliente.
alter table public.recetas
  alter column medicina_id  drop not null,
  alter column titulo       drop not null,
  alter column dosis        drop not null,
  alter column frecuencia   drop not null,
  alter column indicaciones drop not null,
  alter column duracion     drop not null;

alter table public.recetas
  drop constraint if exists recetas_doctor_id_fkey,
  add constraint recetas_doctor_id_fkey
    foreign key (doctor_id) references public.doctores (id) on delete restrict,
  drop constraint if exists recetas_receta_reemplazada_id_fkey,
  add constraint recetas_receta_reemplazada_id_fkey
    foreign key (receta_reemplazada_id) references public.recetas (id) on delete restrict,
  drop constraint if exists recetas_estado_check,
  add constraint recetas_estado_check
    check (estado in ('activa', 'anulada', 'reemplazada'));

create index if not exists idx_recetas_paciente on public.recetas (paciente_id)
  where deleted_at is null;

comment on column public.recetas.items_receta is
  'SD-153: medicinas de la receta. Cada elemento lleva nombre, presentación, '
  'dosis, vía, frecuencia, duración, cantidad e indicaciones específicas.';
comment on column public.recetas.estado is
  'activa | anulada | reemplazada. Una receta corregida apunta a la anterior '
  'con receta_reemplazada_id en vez de editarla.';

notify pgrst, 'reload schema';
