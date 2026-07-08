import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

abstract class ConsultaRepository {
  Future<List<Consulta>> getConsultas();
  Future<List<Consulta>> getConsultasByDoctor(String doctorId);

  Future<String> crearConsultaCompleta(Consulta consulta);

  /// Genera la pre-factura de la consulta (cuenta ABIERTA + ítems) y marca la
  /// cita como completada. Devuelve el id de la cuenta creada.
  Future<String> finalizarConsulta({
    required String consultaId,
    String? nota,
  });

  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    required List<Receta> recetas,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  });
  Future<Map<String, TratamientoAplicadoDetalle>>
  getDetalleTratamientosAplicados(List<String> ids);
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);

  Future<Map<int, List<TratamientoAplicado>>>
  getTratamientosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
