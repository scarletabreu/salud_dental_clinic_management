/// Decide si una fila aplicada debe leerse fuera de una pieza.
///
/// La columna normalizada es el alcance del catálogo. `diente_id IS NULL` se
/// conserva como respaldo para filas históricas cuyo catálogo cambió o ya no
/// está disponible. Esto permite leer correctamente los registros anteriores
/// a HFX-CLIN-003, cuando la base todavía aceptaba procedimientos de arcada o
/// globales pegados a una pieza.
///
/// Esta misma regla la aplica el servidor desde `audit_004`: las dos barridas
/// del borrador —la de la pieza y la de los generales— la usan para repartirse
/// las filas sin solaparse ni dejar huecos. Antes la barrida de la pieza
/// reclamaba toda fila con su `diente_id`, incluidas las que este predicado
/// manda al otro canal, y el canal de generales intentaba actualizarlas
/// exigiendo `diente_id is null`: cero filas, `CL004`, y la consulta atascada
/// en cada autoguardado y en el cierre (F1-05).
///
/// Que cliente y servidor decidan con el mismo criterio es lo que impide que
/// una fila se cuente dos veces o no la reclame nadie (F4-02).
bool registroClinicoEsGeneral(
  Map<String, dynamic> fila, {
  required String catalogoKey,
}) {
  if (fila['diente_id'] == null) return true;

  final rawCatalogo = fila[catalogoKey];
  if (rawCatalogo is! Map) return false;
  final alcance = rawCatalogo['alcance']?.toString().toLowerCase();
  return alcance == 'arcada' || alcance == 'global';
}
