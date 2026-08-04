-- HFX-QA-100 · Retirar las vistas `*_seguro` huérfanas de producción.
--
-- Defecto D3 de la jornada de QA: «Pacientes no cargan — no relationship
-- between 'pacientes_seguro' and 'persona_contactos'». El cliente nunca pide
-- `pacientes_seguro`: pide `pacientes` con el embed anidado
-- `personas → persona_contactos → contactos`. Pero PostgREST resuelve las
-- relaciones contra su caché de esquema, y con `pacientes_seguro` presente —una
-- vista sobre `pacientes` creada a mano en el Studio— la inferencia se vuelve
-- ambigua y el error sale nombrando la vista.
--
-- Las tres vistas (`pacientes_seguro`, `personas_seguro`, `contactos_seguro`)
-- están huérfanas: ninguna policy, función, vista ni código de ninguna rama del
-- repositorio las referencia. Enmascaraban cédula/teléfono/dirección/referencia
-- para doctores no-admin, una intención razonable que nadie llegó a cablear.
--
-- El drop va precedido de una verificación mecánica de dependencias. Si algo
-- llegara a depender de ellas —en producción o en cualquier base donde se
-- aplique esta migración— el bloque **aborta** en vez de romper nada.
--
-- `debe_ocultar_contacto_paciente()` se conserva: la versionó HFX-CLIN-011 y no
-- estorba. Queda disponible si el enmascaramiento se retoma bien hecho.

do $$
declare
  v_vistas text[] := array['pacientes_seguro', 'personas_seguro', 'contactos_seguro'];
  v_vista  text;
  v_dependientes text;
begin
  foreach v_vista in array v_vistas loop
    if to_regclass('public.' || v_vista) is null then
      raise notice 'HFX-QA-100: %.% no existe aquí; nada que retirar.', 'public', v_vista;
      continue;
    end if;

    -- (a) Objetos del catálogo que dependen de la vista (otras vistas, reglas,
    --     columnas generadas, índices, restricciones...). Se excluye la propia
    --     regla `_RETURN` de la vista, que siempre depende de sí misma.
    select string_agg(distinct format('%s %s', d.classid::regclass, d.objid), ', ')
      into v_dependientes
      from pg_depend d
      join pg_rewrite rw on rw.oid = d.objid and d.classid = 'pg_rewrite'::regclass
     where d.refobjid = to_regclass('public.' || v_vista)
       and rw.ev_class <> to_regclass('public.' || v_vista);

    if v_dependientes is not null then
      raise exception
        'HFX-QA-100: % tiene dependientes en el catálogo (%). Se aborta el drop.',
        v_vista, v_dependientes;
    end if;

    -- (b) Policies cuyo USING o WITH CHECK nombre la vista.
    select string_agg(format('%s.%s', schemaname, policyname), ', ')
      into v_dependientes
      from pg_policies
     where coalesce(qual, '') like '%' || v_vista || '%'
        or coalesce(with_check, '') like '%' || v_vista || '%';

    if v_dependientes is not null then
      raise exception
        'HFX-QA-100: % aparece en policies (%). Se aborta el drop.',
        v_vista, v_dependientes;
    end if;

    -- (c) Cuerpos de funciones que nombren la vista.
    select string_agg(p.proname, ', ')
      into v_dependientes
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.prosrc like '%' || v_vista || '%';

    if v_dependientes is not null then
      raise exception
        'HFX-QA-100: % aparece en el cuerpo de funciones (%). Se aborta el drop.',
        v_vista, v_dependientes;
    end if;

    execute format('drop view public.%I', v_vista);
    raise notice 'HFX-QA-100: vista % retirada.', v_vista;
  end loop;
end;
$$;

-- PostgREST cachea el grafo de relaciones: sin este aviso seguiría resolviendo
-- los embeds contra las vistas que acaban de desaparecer.
notify pgrst, 'reload schema';
