-- ============================================================================
--  HFX-CLIN-000 · Contrato único de perfil y catálogo de doctores
--
--  Dos objetos de los que dependía el arranque de la app vivían sólo en la
--  instancia remota: `get_active_doctors` (agenda y selector de doctor) no
--  estaba en ninguna migración, y la resolución del perfil se hacía a base de
--  tres consultas anidadas de PostgREST cuya relación acababa de crearse en
--  esta misma tanda.
--
--  Aquí se versionan los dos y se les quita el `password_hash` que hasta hoy
--  viajaba hasta el navegador.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. `perfil_actual()` — contrato único del perfil de la sesión.
--
--    Recibe implícitamente `auth.uid()`; nadie puede pedir el perfil de otro.
--    Devuelve la identidad personal común, el rol operativo y sólo los campos
--    que ese rol tiene. Un admin llega con datos clínicos y administrativos,
--    porque es un doctor con capacidades añadidas.
-- ---------------------------------------------------------------------------
drop function if exists public.perfil_actual();

create function public.perfil_actual()
returns table (
  id                uuid,
  rol               text,
  nombre            text,
  apellido          text,
  fecha_nacimiento  date,
  cedula            text,
  estatus           text,
  username          text,
  telefono          text,
  email             text,
  direccion         text,
  especialidad      text,
  esta_disponible   boolean,
  departamento      text,
  turno             text
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    u.id,
    case
      when a.id is not null then 'admin'
      when d.id is not null then 'doctor'
      when s.id is not null then 'asistente'
    end                                       as rol,
    p.nombre,
    p.apellido,
    p.fecha_nacimiento,
    p.cedula,
    p.estatus::text,
    u.username,
    c.numero_telefono                         as telefono,
    c.email,
    c.direccion,
    d.especialidad,
    d.esta_disponible,
    a.departamento,
    s.turno
  from public.usuarios u
  join public.personas p on p.id = u.id
  left join public.doctores   d on d.id = u.id and d.deleted_at is null
  left join public.admins     a on a.id = u.id and a.deleted_at is null
  left join public.asistentes s on s.id = u.id and s.deleted_at is null
  left join lateral (
    select ct.numero_telefono, ct.email, ct.direccion
      from public.persona_contactos pc
      join public.contactos ct on ct.id = pc.contacto_id
     where pc.persona_id = p.id
     order by pc.es_principal desc nulls last
     limit 1
  ) c on true
 where u.id = auth.uid()
   and u.deleted_at is null
   and p.deleted_at is null
   and (a.id is not null or d.id is not null or s.id is not null);
$$;

comment on function public.perfil_actual() is
  'HFX-CLIN-000: perfil de la sesión actual. Nunca devuelve password_hash y '
  'no admite consultar el perfil de otro usuario.';

revoke all on function public.perfil_actual() from public, anon;
grant execute on function public.perfil_actual() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. `get_active_doctors()` — catálogo de doctores agendables.
--
--    Cambia la firma (sale `password_hash`), así que hay que soltar la versión
--    anterior: Postgres no reemplaza una función cuando cambia el tipo de
--    retorno, crea una sobrecarga y PostgREST deja de saber cuál elegir.
--
--    Los administradores aparecen aquí sin nada extra: desde HFX-CLIN-000
--    tienen fila en `doctores`, que es lo que este catálogo lee.
-- ---------------------------------------------------------------------------
drop function if exists public.get_active_doctors();

create function public.get_active_doctors()
returns table (
  doctor_id         uuid,
  especialidad      text,
  esta_disponible   boolean,
  username          text,
  nombre            text,
  apellido          text,
  fecha_nacimiento  date,
  cedula            text,
  deleted_at        timestamptz,
  es_admin          boolean
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select d.id,
         d.especialidad,
         d.esta_disponible,
         u.username,
         p.nombre,
         p.apellido,
         p.fecha_nacimiento,
         p.cedula,
         u.deleted_at,
         (a.id is not null) as es_admin
    from public.doctores d
    join public.usuarios u on u.id = d.id
    join public.personas p on p.id = d.id
    left join public.admins a on a.id = d.id and a.deleted_at is null
   where d.deleted_at is null
     and u.deleted_at is null
     and p.deleted_at is null;
$$;

comment on function public.get_active_doctors() is
  'HFX-CLIN-000: doctores activos, administradores incluidos. Ya no devuelve '
  'password_hash: era PII que acababa impresa en la consola del navegador.';

revoke all on function public.get_active_doctors() from public, anon;
grant execute on function public.get_active_doctors() to authenticated;

notify pgrst, 'reload schema';
