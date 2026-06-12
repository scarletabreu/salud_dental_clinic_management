import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';

abstract class ConsultaRepository {
  Future<List<Consulta>> getConsultas();

  /// Crea la consulta junto a su odontograma, los 32 dientes con sus
  /// superficies y los documentos clínicos en una sola operación atómica
  /// (RPC). Devuelve el id de la consulta creada.
  Future<String> crearConsultaCompleta(Consulta consulta);

  /// Persiste el trabajo clínico del workspace al terminar la consulta:
  /// tratamientos asignados en [odontograma] (vinculados a los dientes ya
  /// creados de la consulta) y las [notas] clínicas.
  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required Odontograma odontograma,
    String? notas,
  });

  /// Nombres del catálogo para tratamientos aplicados (id aplicado → nombre).
  Future<Map<String, String>> getNombresTratamientosAplicados(
    List<String> ids,
  );

  Future<List<Consulta>> getHistorialPaciente(String pacienteId);
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
