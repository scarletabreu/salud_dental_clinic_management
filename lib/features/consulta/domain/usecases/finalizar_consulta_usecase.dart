import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';

/// Cierra la consulta y produce el handoff clínico→financiero: la BD, en una
/// sola operación atómica (RPC), suma los precios de los tratamientos aplicados,
/// crea la cuenta ABIERTA con sus ítems y marca la cita como completada.
///
/// Devuelve el id de la cuenta (pre-factura) para poder navegar hacia ella.
class FinalizarConsultaUseCase {
  final ConsultaRepository _repository;

  FinalizarConsultaUseCase(this._repository);

  Future<String> call({required String consultaId, String? nota}) {
    return _repository.finalizarConsulta(consultaId: consultaId, nota: nota);
  }
}
