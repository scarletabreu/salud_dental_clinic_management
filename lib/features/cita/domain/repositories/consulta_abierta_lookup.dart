import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';

/// Puerto estrecho para que la cita pueda mirar hacia su consulta sin depender
/// del repositorio de consultas completo.
///
/// Sostiene dos reglas de SD-160: una cita no se cancela mientras su consulta
/// siga abierta, y la agenda debe poder enlazar con la consulta que ya existe.
/// El adaptador vive en el feature de consulta, así la dependencia apunta en un
/// solo sentido.
abstract class ConsultaAbiertaLookup {
  /// Consulta de cada cita que tenga una, indexada por `citaId`. Las citas sin
  /// consulta no aparecen en el mapa.
  Future<Map<String, ConsultaDeCita>> paraCitas(List<String> citaIds);

  /// `true` si la cita tiene una consulta viva y sin finalizar.
  Future<bool> tieneConsultaAbierta(String citaId);
}
