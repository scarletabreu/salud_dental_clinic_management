# HFX-QA-100 · Reconciliar el esquema (Fase 0 del plan de QA del 1 ago 2026)

Rama: `HFX-QA-100-esquema`, desde `dev`.
Plan de origen: `docs/QA-2026-08-01-plan-correccion.md`, Fase 0.

**Estado: implementado y verificado en local. Falta aplicarlo en producción**
(requiere autorización explícita; ver «Aplicación en producción»).

---

## El hallazgo que cambia el gate

El plan proponía cerrar la fase con `supabase db diff --linked` vacío. **Ese
comando da un falso negativo.** El 1 ago 2026, ejecutado contra esta instancia,
devolvió:

```
No schema changes found
```

mientras producción tenía tres tablas, cuatro vistas, cinco funciones, diez
triggers y catorce policies que la base local no tenía. El motor `pg-delta`
cachea catálogos por hash del conjunto de migraciones y, cuando el hash coincide
a ambos lados, da la comparación por buena. Borrar la caché (`supabase/.temp/
pgdelta/*.json`) no lo arregla: la segunda ejecución tampoco escribió catálogos
y volvió a decir que no había cambios.

Un gate de seguridad que miente es peor que no tener gate, así que la fase
entrega uno propio:

```bash
tool/produccion/deriva_esquema.sh          # informe legible
tool/produccion/deriva_esquema.sh --breve  # sólo el recuento
```

Vuelca las dos bases con `supabase db dump`, parte cada volcado en sentencias
respetando el entrecomillado por dólar, las normaliza y compara los conjuntos.
Sale con 1 si hay deriva. Normaliza a propósito dos cosas que no son deriva: los
comentarios `--` (redacción, no estructura) y el orden físico de las columnas de
un `CREATE TABLE` (depende de cuándo se añadió cada una y no tiene efecto
semántico).

---

## La deriva real que encontró

El diagnóstico del plan se quedó corto. Además de lo previsto, apareció:

| Qué | Dónde estaba | Resolución |
|---|---|---|
| `doctor_paciente` + trigger de autoasignación | sólo producción | versionado tal cual |
| `auditoria_log`, `items_receta` | sólo producción | versionadas y **cerradas al cliente** desde su creación (HFX-CLIN-009 iba guardado por existencia, así que en local nunca corría) |
| Vista `resumen_actividad_plan` | sólo producción | versionada |
| 5 funciones + 10 triggers (auditoría, cascada de borrado, código de receta) | sólo producción | versionados |
| 14 policies de SELECT con guardias `puede_ver_*` | distintas | adoptadas las de producción |
| `tratamientos_aplicados.cantidad_realizada` | sólo producción | versionada |
| `items_plan_tratamiento.tipo_ejecucion`, `sesiones_planificadas` + 3 checks | sólo producción | versionadas |
| `items_cuenta.tratamiento_aplicado_id` + FK | sólo producción | versionada |
| `recetas.codigo_receta` + secuencia | sólo producción | versionada |
| `hfx_base_recibir_compra` | **producción va por delante** | adoptada la de producción |
| Guardias RLS ejecutables por `PUBLIC` | sólo en local | cerradas, como en producción |
| **FK duplicada `admins → doctores`** | sólo producción | retirada la redundante |

Dos cosas merecen subrayarse.

**El cliente ya leía columnas que la base local no tenía.**
`tratamiento_aplicado_model` mapea `cantidad_realizada`,
`resumen_actividad_plan_model` mapea `tipo_ejecucion` y
`sesiones_planificadas`, y `receta_model` mapea `codigo_receta`. Ninguna existía
en una base levantada con `supabase db reset`. No era «producción derivó»: era
el repositorio quien estaba atrasado, y cualquier entorno de desarrollo o de
pruebas estaba corriendo contra un esquema incompleto.

**La FK duplicada es la causa directa del defecto D2.** Producción tenía dos
restricciones sobre `admins.id` hacia `doctores.id`: `admins_id_doctores_fkey`
(la que creó HFX-CLIN-000, versionada y comentada) y `admins_id_fkey` (el nombre
de la línea base, repuntado a mano en el Studio de `usuarios` a `doctores`).
PostgREST ve dos caminos y responde «more than one relationship was found for
'admins' and 'doctores'». Se retira la redundante: ninguna aporta integridad que
la otra no imponga ya, así que no cambia ninguna garantía de datos.

Aun así, D2 necesita también el arreglo de cliente de F1: la tabla
`auditoria_correcciones_clinicas` de HFX-CLIN-001 tiene FK a `admins` y a
`doctores`, y PostgREST sigue infiriendo con ellas un camino m2m. La pista
explícita de constraint en el embed hace falta igual.

---

## El puente de nombres: `directorio_pacientes`

Con las policies de producción, un doctor regular sólo lee la ficha de los
pacientes con asignación activa en `doctor_paciente`. Eso es lo que se quiere
para los datos clínicos y de contacto. Pero la decisión D11 deja al doctor ver
**todas** las consultas, y sin un puente esas filas volverían a pintar
`Paciente #uuid` (defecto D4).

`directorio_pacientes` expone exactamente `id`, `nombre`, `apellido` —ni cédula,
ni fecha de nacimiento, ni contactos, ni nada clínico— y es legible por todo el
personal clínico autenticado. Sigue el patrón de SD-146: vista sin
`security_invoker`, propiedad de `postgres`, con el control de acceso dentro de
la propia vista. No filtra `deleted_at`, para que un paciente dado de baja siga
resolviendo su nombre en el historial antiguo.

---

## Consecuencia para las fases siguientes

Las pantallas tienen que entender el modelo restrictivo: **«no veo la ficha
completa de este paciente» es un estado normal para un doctor no asignado, no un
error**. Los listados resuelven nombres contra el directorio; la ficha sigue
gobernada por `puede_ver_paciente()`. F1 y F3 se apoyan en esto.

---

## Verificación hecha

- `supabase db reset` aplica las tres migraciones limpio.
- Las 13 pruebas SQL existentes siguen en verde con las policies endurecidas.
- Nueva prueba `supabase/tests/hfx_qa_100_esquema_produccion_test.sql`, 9
  comprobaciones, todas en verde:
  1. los objetos de la deriva existen; 2. sin asignación el doctor no lee la
  ficha; 3. atender una consulta concede el acceso; 4. el acceso no se contagia
  a otro doctor; 5. el directorio sí resuelve el nombre; 6. el directorio expone
  sólo tres columnas; 7. las vistas `*_seguro` no existen; 8. `admins` tiene una
  sola FK hacia `doctores`; 9. `auditoria_log` e `items_receta` están cerradas.
- `tool/produccion/deriva_esquema.sh`: de 64 diferencias iniciales a 19, y las
  19 restantes son **exactamente** lo que la migración cambiará en producción
  cuando se aplique (retirar las tres vistas `*_seguro` y la FK duplicada; crear
  el directorio). Tras aplicarla el gate debe quedar en cero.

---

## Aplicación en producción — PENDIENTE DE AUTORIZACIÓN

Nada de `db push`: el registro de migraciones de ambas partes sigue siendo
disjunto (ver `docs/PRODUCCION-plan-migracion.md`). El procedimiento es el
mismo flujo manual ya usado el 31 jul:

1. Copia de seguridad previa:
   ```bash
   supabase db dump --linked             -f copia/01_schema.sql
   supabase db dump --linked --data-only -f copia/02_datos.sql
   ```
2. Ensayo sobre la copia: `tool/produccion/ensayo_migracion.sh copia/`.
3. Aplicar en la instancia, en orden y una a una, las tres migraciones
   `20260811090000`, `20260811090100`, `20260811090200`.
4. `notify pgrst, 'reload schema'` (las dos últimas ya lo emiten).
5. Registrar las tres entradas en `supabase_migrations.schema_migrations`.
6. Gate: `tool/produccion/deriva_esquema.sh` debe salir en cero.

**Qué cambia realmente en producción.** Sólo tres cosas; el resto de la
migración son no-ops allí:

- se retiran las vistas `pacientes_seguro`, `personas_seguro`, `contactos_seguro`
  (con verificación de dependencias previa que **aborta** el drop si algo
  dependiera de ellas);
- se retira la FK redundante `admins_id_fkey`;
- se crea la vista `directorio_pacientes`.

Ninguna toca datos. La primera es la que resuelve el defecto D3 por sí sola.
