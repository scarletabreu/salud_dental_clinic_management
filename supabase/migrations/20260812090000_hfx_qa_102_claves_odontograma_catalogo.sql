-- HFX-QA-102 · Sembrar `clave_odontograma` en el catálogo real.
--
-- Defecto D6b de la jornada de QA del 1 ago 2026: «no funciona el odontograma».
-- La proyección al formulario en papel (`proyeccion_odontograma.dart`) exige
-- `clave_odontograma`, y SD-150 sólo la sembró en las 5 filas de diagnóstico y
-- la de tratamiento que ella misma creó. Todo lo que la clínica añadió después
-- —resina, corona, endodoncia, exodoncia— proyecta NULL, se descarta, y el
-- lienzo queda en blanco.
--
-- Qué NO hace esta migración, y por qué. No cae en la clave «Otro» lo que no
-- encaja. SD-142 ya lo decidió y la razón sigue siendo buena: un asterisco
-- sobre cada pieza con una profilaxis es indistinguible de lo que el doctor sí
-- quiso marcar como «Otro», y llena el diagrama de ruido. Y sobre todo: las
-- claves del formulario **afirman hechos clínicos**. Estampar
-- `pulpectomia_pulpotomia` sobre un diagnóstico de pulpitis diría que se hizo
-- una endodoncia que nadie hizo. Sólo se mapea lo que es cierto; lo demás
-- sigue leyéndose en la ficha de la pieza, que es donde vive el detalle.
--
-- El mapeo va por patrón de nombre porque el catálogo de cada instalación es
-- distinto y el repositorio no lo versiona. Sólo toca filas con la clave a
-- NULL: nunca reescribe una decisión ya tomada.

-- Comparar sin tildes evita duplicar cada patrón («endodoncia» / «endodóncia»,
-- «ionómero» / «ionomero»). Se define aquí en vez de depender de la extensión
-- `unaccent`, que no está instalada en esta instancia.
create or replace function public.hfx_qa_102_sin_tildes(p_texto text)
returns text
language sql immutable
set search_path to 'public'
as $$
  select translate(lower(coalesce(p_texto, '')),
                   'áéíóúüñÁÉÍÓÚÜÑ',
                   'aeiouunAEIOUUN');
$$;

-- ---------------------------------------------------------------------------
-- Tratamientos
-- ---------------------------------------------------------------------------
-- Las tres claves del papel que describen un procedimiento sobre la pieza.

update public.tratamientos set clave_odontograma = 'restaurada'
 where clave_odontograma is null
   and deleted_at is null
   and (
     public.hfx_qa_102_sin_tildes(nombre) ~ 'resina|amalgama|obturaci|restaurac|incrustaci|carilla|corona|onlay|inlay|sellante|ionomero'
   );

update public.tratamientos set clave_odontograma = 'pulpectomia_pulpotomia'
 where clave_odontograma is null
   and deleted_at is null
   and (
     public.hfx_qa_102_sin_tildes(nombre) ~ 'endodon|pulpectom|pulpotom|conducto|biopulpectom|necropulpectom'
   );

update public.tratamientos set clave_odontograma = 'extraccion_indicada'
 where clave_odontograma is null
   and deleted_at is null
   and (
     public.hfx_qa_102_sin_tildes(nombre) ~ 'extracci|exodonc|avulsi'
   );

-- ---------------------------------------------------------------------------
-- Diagnósticos
-- ---------------------------------------------------------------------------
-- Un diagnóstico describe un hallazgo, así que sólo puede mapear a claves que
-- también describen un hallazgo: cariada, perdida, no_erupcionado y —cuando lo
-- que se halla es una endodoncia **previa**— pulpectomia_pulpotomia.

update public.diagnosticos set clave_odontograma = 'cariada'
 where clave_odontograma is null
   and deleted_at is null
   and public.hfx_qa_102_sin_tildes(nombre) ~ 'caries|cariad|lesion cariosa';

update public.diagnosticos set clave_odontograma = 'perdida'
 where clave_odontograma is null
   and deleted_at is null
   and public.hfx_qa_102_sin_tildes(nombre) ~ 'ausen|perdid|edentul|extraid';

update public.diagnosticos set clave_odontograma = 'no_erupcionado'
 where clave_odontograma is null
   and deleted_at is null
   and public.hfx_qa_102_sin_tildes(nombre) ~ 'no erupcion|sin erupcion|retenid|impactad|incluid';

-- «Preexistente» / «previa» es lo que distingue el hallazgo de un tratamiento
-- pulpar ya hecho, del diagnóstico de una pulpa enferma que aún no se trató.
update public.diagnosticos set clave_odontograma = 'pulpectomia_pulpotomia'
 where clave_odontograma is null
   and deleted_at is null
   and public.hfx_qa_102_sin_tildes(nombre) ~ '(endodon|pulpectom|pulpotom|conducto).*(previ|preexist|realizad|tratad)';

update public.diagnosticos set clave_odontograma = 'restaurada'
 where clave_odontograma is null
   and deleted_at is null
   and public.hfx_qa_102_sin_tildes(nombre) ~ '(restaurac|obturac|corona|resina|amalgama).*(previ|preexist|existent)';

-- ---------------------------------------------------------------------------
-- Informe: qué quedó sin clave
-- ---------------------------------------------------------------------------
-- No es un fallo: la mayoría del catálogo no cabe en el vocabulario cerrado del
-- formulario. Se enumera para que quien aplique la migración pueda revisar si
-- falta algún patrón, en vez de descubrirlo por un diagrama vacío.
do $$
declare
  v_sin_clave text;
  v_conteo    integer;
begin
  select count(*), string_agg(nombre, ', ' order by nombre)
    into v_conteo, v_sin_clave
    from public.tratamientos
   where clave_odontograma is null and deleted_at is null;
  raise notice 'HFX-QA-102: % tratamiento(s) sin clave de odontograma: %',
    v_conteo, coalesce(v_sin_clave, '(ninguno)');

  select count(*), string_agg(nombre, ', ' order by nombre)
    into v_conteo, v_sin_clave
    from public.diagnosticos
   where clave_odontograma is null and deleted_at is null;
  raise notice 'HFX-QA-102: % diagnóstico(s) sin clave de odontograma: %',
    v_conteo, coalesce(v_sin_clave, '(ninguno)');
end;
$$;

-- El ayudante era andamio de esta migración; no forma parte del esquema.
drop function public.hfx_qa_102_sin_tildes(text);
