# HFX-CLIN-002 · Persistencia y cierre clínico transaccional

Fecha de cierre técnico: 2026-07-30.

## Resultado

El guardado clínico dejó de ser una lista de llamadas independientes. Existen
dos operaciones de servidor y ninguna más:

- `guardar_borrador_consulta(p_consulta_id, p_version, p_payload)` guarda todo
  el borrador —cabecera, signos vitales, condiciones temporales, odontograma,
  hallazgos, ejecuciones, receta en borrador, insumos declarados y documentos—
  dentro de una transacción, y devuelve los ids confirmados, la versión y el
  timestamp.
- `cerrar_consulta(p_consulta_id, p_version, p_payload, p_idempotencia_key,
  p_metodo_pago, p_nota)` cierra la consulta: aplica el último borrador,
  verifica y descuenta inventario, emite las recetas, genera la pre-factura de
  lo ejecutado, completa la cita y registra auditoría. O queda todo confirmado,
  o no cambia nada.

Ya no hay un estado intermedio posible entre "consulta cerrada" y "cuenta,
inventario y cita coherentes": los dos ocurren en la misma transacción.

## Contrato del payload (versión 1)

Una clave ausente no se toca. Una clave presente describe el conjunto completo
deseado, y lo que desaparezca de ella se anula por borrado lógico, nunca se
borra. Cada fila con `id` se actualiza en su sitio; sin `id`, se inserta y su
identidad vuelve en la respuesta para sellarla en memoria.

```jsonc
{
  "version_payload": 1,
  "notas": "…",
  "signos_vitales": { },
  "temp_condiciones": ["…"],
  "evaluacion_clinica": { },
  "dientes": [{ "fdi_code": 16, "esta_ausente": false, "observaciones": "…",
                "tratamientos": [ … ], "diagnosticos": [ … ] }],
  "recetas": [{ "id": "…", "version": 3, "items_receta": [ … ] }],
  "insumos": [{ "consumible_id": "…", "nombre": "…", "cantidad": 3 }],
  "documentos": [ … ]
}
```

## Códigos de error estables

| Código | Significado | Qué hace la app |
|---|---|---|
| `CL001` | Conflicto de versión: otra sesión guardó primero | `ConflictoVersionFailure`; el workspace marca `EstadoGuardado.conflicto` y conserva el trabajo local |
| `CL002` | La consulta ya está finalizada | `ConsultaCerradaFailure`; se abandona el workspace en vez de autoguardar en el vacío |
| `CL003` | Stock insuficiente para el consumo declarado | `StockInsuficienteFailure`; el mensaje nombra el insumo y la cantidad |
| `CL004` | Payload o recurso inválido | error genérico, sin exponer el payload |
| `CL005` | Intento de modificar una receta ya emitida | bloqueado por disparador |
| `42501` | El actor no puede ejercer sobre esa consulta | igual que HFX-CLIN-001 |

## Defectos de origen corregidos

1. **`superficiecle`.** El diagnóstico viajaba con una columna inexistente:
   PostgREST lo ignoraba, la pantalla seguía mostrándolo y la base no lo tenía.
   Ahora viaja como `superficie` y la prueba REST lo comprueba contra la base
   real, no contra un doble.
2. **Recetas borradas en cada autoguardado.** El `DELETE FROM recetas WHERE
   consulta_id = …` desapareció. El borrador reconcilia por identidad y una
   receta emitida es inmutable: solo admite anulación o reemplazo, y un
   disparador rechaza cualquier otra escritura o borrado.
3. **Inventario descontado fuera del cierre.** El consumo se declaraba en
   memoria del navegador y se descontaba con una llamada por insumo antes de
   finalizar. Ahora vive en `consumos_consulta`, sobrevive a una recarga, se
   agrega cuando el formulario repite un consumible y solo mueve stock dentro
   de la transacción de cierre.
4. **"Consumible X no existe".** El error venía de la interacción entre
   `SELECT … FOR UPDATE` y RLS. Las RPC son `SECURITY DEFINER` y validan
   existencia y stock antes de tocar el ledger, con un mensaje que dice cuánto
   queda y cuánto se pretende consumir.
5. **Reintentos que duplicaban.** Índices únicos parciales garantizan una
   cuenta vigente por consulta, una consulta vigente por cita y un movimiento
   de stock por consulta-consumible; la clave de idempotencia hace que repetir
   el mismo cierre devuelva el resultado existente.

## Esquema añadido

- `consultas`: `version`, `finalizada_at`, `cerrada_por`, `cierre_key`.
- `consumos_consulta`: insumos declarados de la consulta, con unicidad vigente
  por `(consulta_id, consumible_id)`.
- `movimientos_stock_consumible`: `consulta_id`, motivo `consumoClinico` y
  unicidad por `(consulta_id, consumible_id)`.
- `recetas`: `version`, `emitida_at` y estados `borrador | emitida | anulada |
  reemplazada` (el histórico `activa` se migró a `emitida`).
- `auditoria_clinica`: eventos clínicos por consulta, base del timeline que
  pide HFX-CLIN-005.
- Índices únicos `consultas_cita_vigente_uk` y `cuentas_consulta_vigente_uk`.

La migración aborta con un mensaje accionable si encuentra citas con dos
consultas abiertas o consultas con dos cuentas vigentes: son datos que hay que
resolver a mano antes de imponer la regla.

## Endurecimiento adicional

HFX-CLIN-001 cerró los default privileges para `public` y `anon`, pero una
función nueva creada por `postgres` seguía naciendo con `EXECUTE` para
`authenticated`. Esta migración también los cierra para `authenticated`: desde
aquí, cada función que deba usar el cliente se concede explícitamente. Se
detectó porque las funciones base de este ticket quedaron publicadas sin
pedirlo, y la prueba lo comprueba.

## Decisiones

- **Una evaluación sin ejecución no genera pre-factura.** Cobrar cero es ruido
  administrativo y el plan propuesto o aceptado no factura por sí mismo. El
  servidor decide si hay algo que cobrar; el cliente ya no tiene dos caminos de
  cierre distintos.
- **Se retiró la compatibilidad con esquemas anteriores** de
  `tratamientos_aplicados` (`payloadTratamientoParaEsquemaAnterior` y
  compañía). Desde HFX-CLIN-000 el esquema es reproducible y la escritura pasa
  por la RPC; su intención —no perder la justificación clínica— la cumple ahora
  la columna real. Sus pruebas se retiraron junto con el código que probaban.
- **La clave de idempotencia sobrevive al fallo.** Reintentar un cierre que
  falló es el mismo intento lógico, no uno nuevo; es lo que hace que una
  respuesta perdida por red no cobre dos veces.

## Validación ejecutada

```text
supabase db reset --local                          OK
7 archivos supabase/tests/*.sql                    OK
hfx_clin_002_concurrencia.sh                       OK
hfx_clin_002_contrato_rest.sh                      OK
hfx_clin_001_rest_ofensivo.sh                      OK
hfx_clin_000_smoke_login_agenda.sh                 OK
flutter analyze                                    0 errores
dart run tool/ci/verificar_pruebas.dart            0 fallos, 0 conocidos
```

`tool/ci/pruebas_conocidas_rojas.txt` quedó vacío: el único fallo heredado era
el del diagnóstico que no se guardaba, y este ticket lo cerró. El analyzer
conserva nueve advertencias preexistentes fuera de los archivos de este hotfix.

## Limitaciones conocidas

- El recorrido web completo (dos pestañas reales, red interrumpida a mitad del
  cierre) no se ejecutó aquí: la concurrencia se comprobó con dos conexiones
  PostgreSQL reales y el contrato con PostgREST real. La jornada clínica
  completa pertenece a HFX-CLIN-006.
- `hfx_base_finalizar_consulta` sigue siendo quien crea la cuenta y sus ítems.
  Se reutiliza a propósito —es lógica ya probada— pero eso deja dos funciones
  con conocimiento del cierre financiero.
- `supabase/schema.sql` se regeneró con `supabase db dump --local`. El dump
  anterior se había generado contra la instancia enlazada, así que el diff
  incluye diferencias de forma (extensión `pg_net`, ausencia de `CREATE SCHEMA
  public`) además de los objetos nuevos.
