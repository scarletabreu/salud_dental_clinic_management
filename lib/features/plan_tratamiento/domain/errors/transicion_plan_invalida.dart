/// Se intentó mover una actividad o un plan a un estado que su ciclo de vida no
/// permite (aceptar algo ya rechazado, completar algo que nunca empezó).
///
/// Existe como error de dominio para que la interfaz pueda decir qué paso se
/// pidió y desde dónde, en lugar de mostrar un fallo genérico de base de datos.
class TransicionPlanInvalida implements Exception {
  final String origen;
  final String destino;
  final String sujeto;

  const TransicionPlanInvalida({
    required this.origen,
    required this.destino,
    this.sujeto = 'la actividad',
  });

  String get mensaje =>
      'No se puede pasar $sujeto de «$origen» a «$destino».';

  @override
  String toString() => mensaje;
}
