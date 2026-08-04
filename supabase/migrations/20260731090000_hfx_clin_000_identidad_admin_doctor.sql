-- ============================================================================
--  HFX-CLIN-000 · Identidad admin-doctor
--
--  El dominio declara `Admin extends Doctor`, pero la base no lo sostenía: el
--  trigger de alta metía al admin sólo en `admins`, así que el perfil que el
--  login pide por PostgREST (`admins -> doctores -> usuarios -> personas`) no
--  tenía por dónde resolverse y la sesión moría después de que Auth ya había
--  autenticado. Un admin tampoco podía recibir citas ni firmar consultas,
--  porque `citas.doctor_id` y `consultas.doctor_id` apuntan a `doctores`.
--
--  A partir de aquí un administrador es una identidad clínica con capacidades
--  añadidas: el mismo UUID vive en `usuarios`, `doctores` y `admins`, y la FK
--  lo vuelve imposible de romper.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Backfill de administradores históricos sin fila clínica.
--
--    `on conflict do nothing` protege la fila clínica que ya exista: un admin
--    que además fue dado de alta como doctor conserva su especialidad real.
--    Los que no tienen ninguna reciben la misma especialidad por defecto que
--    usa el alta de usuarios, para que el dato sea explícito y no un NULL.
-- ---------------------------------------------------------------------------
insert into public.doctores (id, especialidad, esta_disponible, deleted_at)
select a.id,
       'General',              -- especialidad por defecto para datos históricos
       true,
       a.deleted_at            -- una baja administrativa no revive como doctor
  from public.admins a
  left join public.doctores d on d.id = a.id
 where d.id is null
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Comprobación post-backfill. Si algo quedó fuera es que hay un admin cuyo
--    UUID no existe en `usuarios`, y eso no se arregla insertando a ciegas.
-- ---------------------------------------------------------------------------
do $$
declare
  v_huerfanos text;
begin
  select string_agg(a.id::text, ', ')
    into v_huerfanos
    from public.admins a
    left join public.doctores d on d.id = a.id
   where d.id is null;

  if v_huerfanos is not null then
    raise exception using
      errcode = 'P0001',
      message = format(
        'HFX-CLIN-000: quedaron admins sin identidad clínica (%s).', v_huerfanos),
      hint = 'Cada uno necesita su fila en public.usuarios antes de reconciliar '
             'la identidad clínica. Revisa si el UUID viene de un alta a medias.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. La FK que impide volver a caer en el mismo estado. `admins.id` sigue
--    apuntando también a `usuarios` (la FK existente no se toca): la cadena
--    usuarios -> doctores -> admins queda cerrada por los dos extremos.
-- ---------------------------------------------------------------------------
alter table public.admins
  drop constraint if exists admins_id_doctores_fkey;

alter table public.admins
  add constraint admins_id_doctores_fkey
  foreign key (id) references public.doctores (id)
  on update cascade on delete cascade;

comment on constraint admins_id_doctores_fkey on public.admins is
  'HFX-CLIN-000: un administrador es un doctor con capacidades añadidas. '
  'Sin esta FK el login por PostgREST no puede resolver su perfil.';

-- ---------------------------------------------------------------------------
-- 4. Alta de usuarios: un admin nace con las tres identidades.
--
--    Además valida antes de escribir. El trigger corre dentro del INSERT de
--    `auth.users`, así que abortar aquí impide que quede un usuario capaz de
--    autenticarse pero sin perfil operativo: la transacción de Auth se revierte
--    entera.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_persona_id  uuid;
  v_contacto_id uuid;
  v_meta        jsonb := new.raw_user_meta_data;
  v_rol         text  := v_meta ->> 'rol';
  v_telefono    text  := nullif(trim(v_meta ->> 'telefono'), '');
  v_nombre      text  := nullif(trim(v_meta ->> 'nombre'), '');
  v_apellido    text  := nullif(trim(v_meta ->> 'apellido'), '');
  v_cedula      text  := nullif(trim(v_meta ->> 'cedula'), '');
  v_username    text  := nullif(trim(v_meta ->> 'username'), '');
begin
  if v_rol is null or v_rol not in ('doctor', 'admin', 'asistente') then
    raise exception
      'El rol proporcionado ("%") es inválido o no fue enviado en la metadata.',
      coalesce(v_rol, 'NULL')
      using errcode = 'P0001';
  end if;

  -- Validar antes de escribir: si falta un dato obligatorio, el alta no debe
  -- dejar media persona creada ni un usuario de Auth sin perfil. `personas`
  -- exige nombre, apellido, fecha de nacimiento y cédula, y `usuarios` exige
  -- username; sin este bloque el fallo llegaba como un error de constraint.
  if v_nombre is null
     or v_apellido is null
     or v_username is null
     or v_cedula is null
     or nullif(v_meta ->> 'fecha_nacimiento', '') is null
  then
    raise exception
      'Faltan datos obligatorios para crear el usuario: nombre, apellido, fecha_nacimiento, cedula y username.'
      using errcode = 'P0001',
            hint = 'Los envía admin-crear-usuario dentro de user_metadata.';
  end if;

  if v_rol = 'asistente' and nullif(trim(v_meta ->> 'turno'), '') is null then
    raise exception 'Un asistente necesita turno.' using errcode = 'P0001';
  end if;

  -- El UUID de Auth manda: es el mismo en persona, usuario y perfil, y es el
  -- que compara `auth.uid()` en RLS y en las RPC clínicas.
  insert into public.personas (
    id, nombre, apellido, fecha_nacimiento, cedula, estatus
  ) values (
    new.id,
    v_nombre,
    v_apellido,
    nullif(v_meta ->> 'fecha_nacimiento', '')::date,
    v_cedula,
    coalesce(v_meta ->> 'estatus', 'activo')::estatus_persona
  )
  returning id into v_persona_id;

  if v_telefono is not null then
    insert into public.contactos (numero_telefono)
    values (v_telefono)
    returning id into v_contacto_id;

    insert into public.persona_contactos (
      persona_id, tipo_contacto, contacto_id, es_principal
    ) values (
      v_persona_id, 'telefono', v_contacto_id, true
    );
  end if;

  insert into public.usuarios (id, username)
  values (v_persona_id, v_username);

  -- Doctor y admin comparten identidad clínica; el admin sólo añade la fila
  -- administrativa encima.
  if v_rol in ('doctor', 'admin') then
    insert into public.doctores (id, especialidad, esta_disponible)
    values (
      v_persona_id,
      coalesce(nullif(trim(v_meta ->> 'especialidad'), ''), 'General'),
      true
    );
  end if;

  if v_rol = 'admin' then
    insert into public.admins (id, departamento)
    values (
      v_persona_id,
      coalesce(nullif(trim(v_meta ->> 'departamento'), ''), 'Administración')
    );
  elsif v_rol = 'asistente' then
    insert into public.asistentes (id, turno)
    values (v_persona_id, trim(v_meta ->> 'turno'));
  end if;

  return new;
end;
$$;

alter function public.handle_new_user() owner to postgres;

comment on function public.handle_new_user() is
  'HFX-CLIN-000: aprovisiona persona, usuario y perfil con el UUID de Auth. '
  'El admin recibe además fila en `doctores`, porque ejerce clínica.';

-- ---------------------------------------------------------------------------
-- 5. El trigger que dispara ese alta no estaba versionado en ningún archivo:
--    sólo existía en la instancia. Una base reconstruida autenticaba usuarios
--    que nunca llegaban a tener perfil.
-- ---------------------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
