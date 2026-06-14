import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

/// Se lanza cuando se intenta cambiar el estado de una cita siguiendo una
/// transición que el grafo de [EstadoCita.transicionesPermitidas] no permite.
class TransicionEstadoInvalida implements Exception {
  final EstadoCita actual;
  final EstadoCita destino;

  const TransicionEstadoInvalida(this.actual, this.destino);

  @override
  String toString() =>
      'No se puede pasar de "${actual.label}" a "${destino.label}".';
}
