-- HFX-QA-108 · Procedimientos históricos invisibles o en el lugar equivocado
--
-- HFX-CLIN-003 impide desde el 2 ago 2026 que una aplicación contradiga el
-- alcance de su catálogo, pero no reinterpretó las filas anteriores. En
-- producción quedaron procedimientos `arcada/global` ligados a una pieza o
-- superficie y procedimientos de `diente` ligados a una cara. Los lectores
-- modernos separan lo general de lo dental; esa forma histórica hacía que la
-- misma fila apareciera en una vista y desapareciera en otra o en el PDF.
--
-- Solo se corrige lo que el catálogo determina sin ambigüedad:
--   * arcada/global: no lleva pieza ni superficie;
--   * diente: conserva la pieza y no lleva superficie.
-- No se inventa una pieza ausente ni una cara faltante. Esos casos se informan
-- al final para corrección clínica manual.

create or replace function public.hfx_qa_108_normalizar_alcance_historico()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tratamientos_generales integer := 0;
  v_tratamientos_diente_inferidos integer := 0;
  v_tratamientos_diente integer := 0;
  v_diagnosticos_generales integer := 0;
  v_diagnosticos_diente integer := 0;
  v_arrays_reconstruidos integer := 0;
  v_ambiguos_tratamiento integer := 0;
  v_ambiguos_diagnostico integer := 0;
begin
  update tratamientos_aplicados ta
     set diente_id = null,
         superficie = null,
         updated_at = now()
    from tratamientos t
   where t.id = ta.tratamiento_id
     and ta.deleted_at is null
     and t.alcance in ('arcada', 'global')
     and (ta.diente_id is not null or ta.superficie is not null);
  get diagnostics v_tratamientos_generales = row_count;

  -- Un tratamiento de diente puede recuperar su pieza sin adivinar cuando la
  -- actividad del plan está vinculada a un diagnóstico con pieza. No se copia
  -- el `diente_id` histórico directamente: si la ejecución ocurrió en otra
  -- consulta, se busca la pieza del odontograma ejecutor por su código FDI.
  update tratamientos_aplicados ta
     set diente_id = destino.id,
         superficie = null,
         updated_at = now()
    from tratamientos t,
         items_plan_tratamiento ip,
         diagnosticos_aplicados da,
         dientes origen,
         odontogramas od_destino,
         dientes destino
   where t.id = ta.tratamiento_id
     and t.alcance = 'diente'
     and ta.deleted_at is null
     and ta.diente_id is null
     and ip.id = ta.item_plan_id
     and da.id = ip.diagnostico_aplicado_id
     and origen.id = da.diente_id
     and od_destino.consulta_id = ta.consulta_id
     and od_destino.deleted_at is null
     and destino.odontograma_id = od_destino.id
     and destino.deleted_at is null
     and destino.fdi_code = origen.fdi_code;
  get diagnostics v_tratamientos_diente_inferidos = row_count;

  update tratamientos_aplicados ta
     set superficie = null,
         updated_at = now()
    from tratamientos t
   where t.id = ta.tratamiento_id
     and ta.deleted_at is null
     and t.alcance = 'diente'
     and ta.diente_id is not null
     and ta.superficie is not null;
  get diagnostics v_tratamientos_diente = row_count;

  update diagnosticos_aplicados da
     set diente_id = null,
         superficie = null,
         updated_at = now()
    from diagnosticos d
   where d.id = da.diagnosis_id
     and da.deleted_at is null
     and d.alcance in ('arcada', 'global')
     and (da.diente_id is not null or da.superficie is not null);
  get diagnostics v_diagnosticos_generales = row_count;

  update diagnosticos_aplicados da
     set superficie = null,
         updated_at = now()
    from diagnosticos d
   where d.id = da.diagnosis_id
     and da.deleted_at is null
     and d.alcance = 'diente'
     and da.diente_id is not null
     and da.superficie is not null;
  get diagnostics v_diagnosticos_diente = row_count;

  -- `dientes.tratamientos_aplicados_ids` es una proyección auxiliar. Al
  -- desligar los generales se reconstruye desde la tabla normalizada para que
  -- ningún lector antiguo los siga atribuyendo a la pieza anterior.
  with esperados as (
    select di.id,
           coalesce(
             array_agg(ta.id order by ta.created_at)
               filter (where ta.id is not null),
             '{}'::uuid[]
           ) ids
      from dientes di
      left join tratamientos_aplicados ta
        on ta.diente_id = di.id and ta.deleted_at is null
     group by di.id
  )
  update dientes di
     set tratamientos_aplicados_ids = e.ids,
         updated_at = now()
    from esperados e
   where e.id = di.id
     and di.tratamientos_aplicados_ids is distinct from e.ids;
  get diagnostics v_arrays_reconstruidos = row_count;

  select count(*) into v_ambiguos_tratamiento
    from tratamientos_aplicados ta
    join tratamientos t on t.id = ta.tratamiento_id
   where ta.deleted_at is null
     and ((t.alcance = 'puntual'
           and (ta.diente_id is null or ta.superficie is null))
       or (t.alcance = 'diente' and ta.diente_id is null));

  select count(*) into v_ambiguos_diagnostico
    from diagnosticos_aplicados da
    join diagnosticos d on d.id = da.diagnosis_id
   where da.deleted_at is null
     and ((d.alcance = 'puntual'
           and (da.diente_id is null or da.superficie is null))
       or (d.alcance = 'diente' and da.diente_id is null));

  return jsonb_build_object(
    'tratamientos_generales_normalizados', v_tratamientos_generales,
    'tratamientos_diente_inferidos', v_tratamientos_diente_inferidos,
    'tratamientos_diente_normalizados', v_tratamientos_diente,
    'diagnosticos_generales_normalizados', v_diagnosticos_generales,
    'diagnosticos_diente_normalizados', v_diagnosticos_diente,
    'arrays_diente_reconstruidos', v_arrays_reconstruidos,
    'tratamientos_ambiguos_pendientes', v_ambiguos_tratamiento,
    'diagnosticos_ambiguos_pendientes', v_ambiguos_diagnostico
  );
end;
$$;

alter function public.hfx_qa_108_normalizar_alcance_historico() owner to postgres;
revoke all on function public.hfx_qa_108_normalizar_alcance_historico()
  from public, anon, authenticated;

do $$
declare
  v_resultado jsonb;
begin
  v_resultado := public.hfx_qa_108_normalizar_alcance_historico();
  raise notice 'HFX-QA-108: %', v_resultado;
end;
$$;

comment on function public.hfx_qa_108_normalizar_alcance_historico() is
  'HFX-QA-108. Normaliza aplicaciones históricas cuando el alcance del catálogo determina su ubicación sin ambigüedad; informa las que requieren revisión clínica.';
