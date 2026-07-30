/// Vista mínima de una consulta vista desde su cita: identidad y si sigue
/// abierta. Permite que la agenda enlace con la consulta y que la cancelación
/// sepa si hay algo abierto, sin cargar el expediente completo (SD-160).
///
/// No confundir con `ReferenciaConsulta` (odontograma): esa describe una visita
/// dentro del historial de una pieza; esta solo resuelve el vínculo
/// cita↔consulta.
class ConsultaDeCita {
  final String id;
  final bool finalizada;

  const ConsultaDeCita({required this.id, required this.finalizada});

  bool get estaAbierta => !finalizada;

  // Igualdad por valor: viaja dentro del estado de `CitaCubitLoaded`, cuyo
  // `props` compara el mapa entero. Sin esto la agenda no se repintaría al
  // pasar una consulta de abierta a finalizada.
  @override
  bool operator ==(Object other) =>
      other is ConsultaDeCita &&
      other.id == id &&
      other.finalizada == finalizada;

  @override
  int get hashCode => Object.hash(id, finalizada);
}
