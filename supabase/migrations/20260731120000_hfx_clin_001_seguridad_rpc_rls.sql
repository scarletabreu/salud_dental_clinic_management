-- HFX-CLIN-001: el servidor vuelve a ser la autoridad de cada operación.
-- La línea base concedía por defecto funciones, tablas y secuencias a anon.

alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon;
alter default privileges for role postgres in schema public
  revoke all on tables from public, anon;
alter default privileges for role postgres in schema public
  revoke all on sequences from public, anon;

revoke execute on all functions in schema public from public, anon, authenticated;
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

-- Las suites SQL, migraciones y tareas operativas conectadas directamente a
-- Postgres no tienen JWT. `session_user` sigue siendo `authenticator` dentro
-- de una RPC SECURITY DEFINER, por lo que esta excepción no abre PostgREST.
create or replace function public.es_contexto_interno()
returns boolean
language sql stable security invoker
set search_path = ''
as $$
  select session_user in ('postgres', 'service_role')
     and current_setting('role', true) in ('none', 'postgres', 'service_role');
$$;

-- Las comprobaciones de rol ignoran perfiles dados de baja.
create or replace function public.es_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.admins a on a.id = u.id and a.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;

create or replace function public.es_doctor()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.doctores d on d.id = u.id and d.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;

create or replace function public.es_asistente()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.asistentes a on a.id = u.id and a.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;

create or replace function public.puede_ver_consulta(p_consulta_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select public.es_admin() or exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
       and public.es_doctor()
  );
$$;

create or replace function public.puede_editar_consulta_propia(p_consulta_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
       and coalesce(c.finalizada, false) = false
       and public.es_doctor()
  );
$$;

-- Encapsular las RPC existentes permite conservar sus contratos y añadir una
-- barrera uniforme sin duplicar todavía la transacción clínica de HFX-CLIN-002.
alter function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
) rename to hfx_base_crear_consulta_completa;

create function public.crear_consulta_completa(
  p_paciente_id uuid,
  p_doctor_id uuid,
  p_cita_id uuid,
  p_fecha timestamptz,
  p_motivo_consulta text,
  p_temp_condiciones jsonb,
  p_dientes jsonb,
  p_documentos jsonb
) returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_cita public.citas%rowtype;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_doctor()) then
    raise exception 'Sesión clínica activa requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_doctor_id is distinct from auth.uid() then
    raise exception 'No puede firmar una consulta como otro doctor.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita no existe o fue eliminada.' using errcode = 'P0002';
  end if;
  if v_cita.doctor_id is distinct from p_doctor_id
     or v_cita.persona_id is distinct from p_paciente_id then
    raise exception 'La cita no pertenece al doctor y paciente indicados.'
      using errcode = '42501';
  end if;
  if v_cita.estado::text in ('cancelada', 'completada') then
    raise exception 'El estado de la cita no permite iniciar una consulta.'
      using errcode = '55000';
  end if;

  return public.hfx_base_crear_consulta_completa(
    p_paciente_id, p_doctor_id, p_cita_id, p_fecha, p_motivo_consulta,
    p_temp_condiciones, p_dientes, p_documentos
  );
end;
$$;

alter function public.finalizar_consulta(uuid, text, text)
  rename to hfx_base_finalizar_consulta;

create function public.finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'contado',
  p_nota text default null
) returns uuid
language plpgsql security definer
set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not public.puede_editar_consulta_propia(p_consulta_id)
     ) then
    raise exception 'Solo el autor clínico activo puede finalizar la consulta.'
      using errcode = '42501';
  end if;
  return public.hfx_base_finalizar_consulta(
    p_consulta_id, p_metodo_pago, p_nota
  );
end;
$$;

-- Mutaciones financieras/operativas: sesión activa y capacidad explícita.
alter function public.ajustar_stock_consumible(uuid, integer, text)
  rename to hfx_base_ajustar_stock_consumible;
create or replace function public.hfx_base_ajustar_stock_consumible(
  p_consumible_id uuid, p_nuevo_stock integer, p_motivo text
) returns void
language plpgsql
set search_path = public
as $$
declare
  v_stock_anterior integer;
begin
  if p_nuevo_stock < 0 then
    raise exception 'El stock no puede ser negativo.' using errcode = '22023';
  end if;
  if p_motivo not in ('merma', 'correccion', 'usoInterno') then
    raise exception 'El motivo del ajuste no es válido.' using errcode = '22023';
  end if;

  select stock_actual into v_stock_anterior
    from public.consumibles
   where id = p_consumible_id and activo = true and deleted_at is null
   for update;
  if not found then
    raise exception 'No se encontró un consumible activo para ajustar.'
      using errcode = 'P0002';
  end if;

  -- El trigger de movimientos aplica la diferencia bajo lock. Actualizar el
  -- stock aquí también lo aplicaba dos veces y rompía el CHECK de auditoría.
  insert into public.movimientos_stock_consumible (
    consumible_id, stock_anterior, stock_nuevo, diferencia, motivo, creado_por
  ) values (
    p_consumible_id, v_stock_anterior, p_nuevo_stock,
    p_nuevo_stock - v_stock_anterior, p_motivo, auth.uid()
  );

  update public.consumibles
     set estado = case
           when stock_actual <= 0
             then 'agotado'::public.estado_consumible
           when stock_actual <= stock_minimo
             then 'bajo_stock'::public.estado_consumible
           else 'disponible'::public.estado_consumible
         end
   where id = p_consumible_id;
end;
$$;
create function public.ajustar_stock_consumible(
  p_consumible_id uuid, p_nuevo_stock integer, p_motivo text
) returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_ajustar_stock_consumible(
    p_consumible_id, p_nuevo_stock, p_motivo
  );
end;
$$;

alter function public.generar_plan_cuotas(uuid, jsonb)
  rename to hfx_base_generar_plan_cuotas;
create function public.generar_plan_cuotas(p_cuenta_id uuid, p_cuotas jsonb)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_generar_plan_cuotas(p_cuenta_id, p_cuotas);
end;
$$;

alter function public.marcar_cuotas_vencidas(uuid)
  rename to hfx_base_marcar_cuotas_vencidas;
create function public.marcar_cuotas_vencidas(p_cuenta_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_marcar_cuotas_vencidas(p_cuenta_id);
end;
$$;

alter function public.registrar_pago(uuid, numeric, text, uuid)
  rename to hfx_base_registrar_pago;
create function public.registrar_pago(
  p_cuenta_id uuid, p_monto numeric, p_metodo_pago text,
  p_cuota_id uuid default null
) returns uuid language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  return public.hfx_base_registrar_pago(
    p_cuenta_id, p_monto, p_metodo_pago, p_cuota_id
  );
end;
$$;

alter function public.recibir_compra(uuid, uuid)
  rename to hfx_base_recibir_compra;
create function public.recibir_compra(p_compra_id uuid, p_usuario_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de compras requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_usuario_id is distinct from auth.uid() then
    raise exception 'El actor de la compra no coincide con la sesión.'
      using errcode = '42501';
  end if;
  perform public.hfx_base_recibir_compra(p_compra_id, p_usuario_id);
end;
$$;

alter function public.registrar_mantenimiento_equipo(uuid, uuid, numeric, timestamptz, text)
  rename to hfx_base_registrar_mantenimiento_equipo;
create function public.registrar_mantenimiento_equipo(
  p_equipo_id uuid, p_suplidor_id uuid, p_costo numeric,
  p_fecha_mantenimiento timestamptz, p_descripcion text default 'Mantenimiento'
) returns uuid language plpgsql security definer set search_path = public
as $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  return public.hfx_base_registrar_mantenimiento_equipo(
    p_equipo_id, p_suplidor_id, p_costo, p_fecha_mantenimiento, p_descripcion
  );
end;
$$;

-- Una corrección ajena nunca cambia doctor_id y siempre deja antes/después.
create table if not exists public.auditoria_correcciones_clinicas (
  id uuid primary key default gen_random_uuid(),
  consulta_id uuid not null references public.consultas(id),
  autor_original_id uuid not null references public.doctores(id),
  corregido_por uuid not null references public.admins(id),
  motivo text not null check (length(btrim(motivo)) >= 10),
  datos_anteriores jsonb not null,
  datos_nuevos jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.auditoria_correcciones_clinicas enable row level security;

create table if not exists public.auditoria_operaciones_admin (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.admins(id),
  operacion text not null,
  recurso_tipo text not null,
  recurso_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.auditoria_operaciones_admin enable row level security;

create or replace function public.corregir_consulta_ajena(
  p_consulta_id uuid, p_cambios jsonb, p_motivo text
) returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_consulta public.consultas%rowtype;
  v_antes jsonb;
  v_despues jsonb;
begin
  if auth.uid() is null or not public.es_admin() then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  if length(btrim(coalesce(p_motivo, ''))) < 10 then
    raise exception 'La corrección requiere un motivo de al menos 10 caracteres.'
      using errcode = '22023';
  end if;
  if p_cambios - array['motivo_consulta', 'notas'] <> '{}'::jsonb then
    raise exception 'La corrección contiene campos no autorizados.'
      using errcode = '22023';
  end if;

  select * into v_consulta from public.consultas
   where id = p_consulta_id and deleted_at is null for update;
  if not found then
    raise exception 'La consulta no existe.' using errcode = 'P0002';
  end if;
  if v_consulta.doctor_id = auth.uid() then
    raise exception 'La consulta propia se corrige por el flujo clínico normal.'
      using errcode = '22023';
  end if;

  v_antes := jsonb_build_object(
    'motivo_consulta', v_consulta.motivo_consulta, 'notas', v_consulta.notas
  );
  update public.consultas
     set motivo_consulta = case when p_cambios ? 'motivo_consulta'
                            then p_cambios->>'motivo_consulta'
                            else motivo_consulta end,
         notas = case when p_cambios ? 'notas'
                 then p_cambios->>'notas' else notas end,
         updated_at = now()
   where id = p_consulta_id;
  select jsonb_build_object(
    'motivo_consulta', motivo_consulta, 'notas', notas
  ) into v_despues from public.consultas where id = p_consulta_id;

  insert into public.auditoria_correcciones_clinicas (
    consulta_id, autor_original_id, corregido_por, motivo,
    datos_anteriores, datos_nuevos
  ) values (
    p_consulta_id, v_consulta.doctor_id, auth.uid(), btrim(p_motivo),
    v_antes, v_despues
  );
end;
$$;

create policy auditoria_correcciones_select_admin
  on public.auditoria_correcciones_clinicas for select to authenticated
  using (public.es_admin());
create policy auditoria_operaciones_select_admin
  on public.auditoria_operaciones_admin for select to authenticated
  using (public.es_admin());

-- RLS clínica: admin ve todo, pero la escritura ordinaria exige autoría propia.
drop policy if exists citas_select on public.citas;
drop policy if exists citas_insert on public.citas;
drop policy if exists citas_update on public.citas;
drop policy if exists citas_delete on public.citas;
create policy citas_select on public.citas for select to authenticated
  using (
    public.es_admin() or public.es_asistente()
    or (public.es_doctor() and doctor_id = auth.uid())
  );
create policy citas_insert on public.citas for insert to authenticated
  with check (
    public.es_admin() or public.es_asistente()
    or (public.es_doctor() and doctor_id = auth.uid())
  );
create policy citas_update on public.citas for update to authenticated
  using (
    public.es_admin() or public.es_asistente()
    or (public.es_doctor() and doctor_id = auth.uid())
  )
  with check (
    public.es_admin() or public.es_asistente()
    or (public.es_doctor() and doctor_id = auth.uid())
  );
create policy citas_delete on public.citas for delete to authenticated
  using (
    public.es_admin() or public.es_asistente()
    or (public.es_doctor() and doctor_id = auth.uid())
  );

drop policy if exists citas_items_plan_select on public.citas_items_plan;
drop policy if exists citas_items_plan_insert on public.citas_items_plan;
drop policy if exists citas_items_plan_delete on public.citas_items_plan;
create policy citas_items_plan_select
  on public.citas_items_plan for select to authenticated
  using (
    exists (
      select 1 from public.citas c
       where c.id = cita_id
         and (
           public.es_admin() or public.es_asistente()
           or (public.es_doctor() and c.doctor_id = auth.uid())
         )
    )
  );
create policy citas_items_plan_insert
  on public.citas_items_plan for insert to authenticated
  with check (public.es_admin() or public.es_asistente());
create policy citas_items_plan_delete
  on public.citas_items_plan for delete to authenticated
  using (public.es_admin() or public.es_asistente());

drop policy if exists consulta_select on public.consultas;
drop policy if exists consulta_insert on public.consultas;
drop policy if exists consulta_update on public.consultas;
drop policy if exists consulta_delete on public.consultas;
create policy consulta_select on public.consultas for select to authenticated
  using (public.es_admin() or doctor_id = auth.uid());
create policy consulta_insert on public.consultas for insert to authenticated
  with check (public.es_doctor() and doctor_id = auth.uid());
create policy consulta_update on public.consultas for update to authenticated
  using (public.puede_editar_consulta_propia(id))
  with check (doctor_id = auth.uid());

drop policy if exists recetas_select on public.recetas;
drop policy if exists recetas_insert on public.recetas;
drop policy if exists recetas_update on public.recetas;
drop policy if exists recetas_delete on public.recetas;
create policy recetas_select on public.recetas for select to authenticated
  using (public.puede_ver_consulta(consulta_id));
create policy recetas_insert on public.recetas for insert to authenticated
  with check (
    public.puede_editar_consulta_propia(consulta_id)
    and doctor_id is not distinct from auth.uid()
  );
create policy recetas_update on public.recetas for update to authenticated
  using (public.puede_editar_consulta_propia(consulta_id))
  with check (
    public.puede_editar_consulta_propia(consulta_id)
    and doctor_id is not distinct from auth.uid()
  );
create policy recetas_delete on public.recetas for delete to authenticated
  using (public.puede_editar_consulta_propia(consulta_id));

drop policy if exists diagnosticos_aplicados_select on public.diagnosticos_aplicados;
drop policy if exists diagnosticos_aplicados_insert on public.diagnosticos_aplicados;
drop policy if exists diagnosticos_aplicados_update on public.diagnosticos_aplicados;
drop policy if exists diagnosticos_aplicados_delete on public.diagnosticos_aplicados;
create policy diagnosticos_aplicados_select
  on public.diagnosticos_aplicados for select to authenticated
  using (public.puede_ver_consulta(consulta_id));
create policy diagnosticos_aplicados_insert
  on public.diagnosticos_aplicados for insert to authenticated
  with check (public.puede_editar_consulta_propia(consulta_id));
create policy diagnosticos_aplicados_update
  on public.diagnosticos_aplicados for update to authenticated
  using (public.puede_editar_consulta_propia(consulta_id))
  with check (public.puede_editar_consulta_propia(consulta_id));
create policy diagnosticos_aplicados_delete
  on public.diagnosticos_aplicados for delete to authenticated
  using (public.puede_editar_consulta_propia(consulta_id));

drop policy if exists tratamientos_aplicados_select on public.tratamientos_aplicados;
drop policy if exists tratamientos_aplicados_insert on public.tratamientos_aplicados;
drop policy if exists tratamientos_aplicados_update on public.tratamientos_aplicados;
drop policy if exists tratamientos_aplicados_delete on public.tratamientos_aplicados;
create policy tratamientos_aplicados_select
  on public.tratamientos_aplicados for select to authenticated
  using (public.puede_ver_consulta(consulta_id));
create policy tratamientos_aplicados_insert
  on public.tratamientos_aplicados for insert to authenticated
  with check (
    public.puede_editar_consulta_propia(consulta_id)
    and doctor_ejecuta_id is not distinct from auth.uid()
  );
create policy tratamientos_aplicados_update
  on public.tratamientos_aplicados for update to authenticated
  using (public.puede_editar_consulta_propia(consulta_id))
  with check (
    public.puede_editar_consulta_propia(consulta_id)
    and doctor_ejecuta_id is not distinct from auth.uid()
  );
create policy tratamientos_aplicados_delete
  on public.tratamientos_aplicados for delete to authenticated
  using (public.puede_editar_consulta_propia(consulta_id));

drop policy if exists documentos_clinicos_select on public.documentos_clinicos;
drop policy if exists documentos_clinicos_insert on public.documentos_clinicos;
drop policy if exists documentos_clinicos_update on public.documentos_clinicos;
drop policy if exists documentos_clinicos_delete on public.documentos_clinicos;
create policy documentos_clinicos_select
  on public.documentos_clinicos for select to authenticated
  using (public.puede_ver_consulta(consulta_id));
create policy documentos_clinicos_insert
  on public.documentos_clinicos for insert to authenticated
  with check (public.puede_editar_consulta_propia(consulta_id));
create policy documentos_clinicos_update
  on public.documentos_clinicos for update to authenticated
  using (public.puede_editar_consulta_propia(consulta_id))
  with check (public.puede_editar_consulta_propia(consulta_id));
create policy documentos_clinicos_delete
  on public.documentos_clinicos for delete to authenticated
  using (public.puede_editar_consulta_propia(consulta_id));

-- Los adjuntos clínicos dejan de ser URLs públicas. La carpeta conserva el
-- paciente como primer segmento y registra al uploader autenticado como
-- segundo segmento; la lectura exige una identidad clínica activa.
update storage.buckets set public = false where id = 'documentos-clinicos';
drop policy if exists documentos_clinicos_insert on storage.objects;
drop policy if exists documentos_clinicos_select on storage.objects;
create policy documentos_clinicos_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'documentos-clinicos'
    and public.es_doctor()
    and (storage.foldername(name))[2] = auth.uid()::text
    and exists (
      select 1 from public.pacientes p
       where p.id::text = (storage.foldername(name))[1]
         and p.deleted_at is null
    )
  );
create policy documentos_clinicos_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'documentos-clinicos'
    and public.es_doctor()
    and exists (
      select 1 from public.pacientes p
       where p.id::text = (storage.foldername(name))[1]
         and p.deleted_at is null
    )
  );

-- password_hash deja de ser una columna legible desde PostgREST.
revoke select on public.usuarios from authenticated;
grant select (
  id, username, last_login, created_at, deleted_at, updated_at
) on public.usuarios to authenticated;

-- Contrato de ejecución explícito. Las funciones hfx_base_* y triggers quedan
-- reservadas al owner/service_role.
revoke execute on all functions in schema public
  from public, anon, authenticated;

grant execute on function public.es_admin() to authenticated, service_role;
grant execute on function public.es_doctor() to authenticated, service_role;
grant execute on function public.es_asistente() to authenticated, service_role;
grant execute on function public.puede_ver_consulta(uuid) to authenticated, service_role;
grant execute on function public.puede_editar_consulta_propia(uuid)
  to authenticated, service_role;
grant execute on function public.perfil_actual() to authenticated, service_role;
grant execute on function public.get_active_doctors() to authenticated, service_role;
grant execute on function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
) to authenticated;
grant execute on function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb,
  public.tipo_atencion_clinica
) to authenticated;
grant execute on function public.finalizar_consulta(uuid, text, text)
  to authenticated;
grant execute on function public.ajustar_stock_consumible(uuid, integer, text)
  to authenticated;
grant execute on function public.generar_plan_cuotas(uuid, jsonb) to authenticated;
grant execute on function public.marcar_cuotas_vencidas(uuid) to authenticated;
grant execute on function public.registrar_pago(uuid, numeric, text, uuid)
  to authenticated;
grant execute on function public.recibir_compra(uuid, uuid) to authenticated;
grant execute on function public.registrar_mantenimiento_equipo(
  uuid, uuid, numeric, timestamptz, text
) to authenticated;
grant execute on function public.corregir_consulta_ajena(uuid, jsonb, text)
  to authenticated;

grant select on public.auditoria_correcciones_clinicas to authenticated;
grant select on public.auditoria_operaciones_admin to authenticated;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;

comment on table public.auditoria_correcciones_clinicas is
  'HFX-CLIN-001: correcciones administrativas que conservan autoría clínica.';
comment on table public.auditoria_operaciones_admin is
  'HFX-CLIN-001: operaciones administrativas sin contraseñas ni payloads sensibles.';
