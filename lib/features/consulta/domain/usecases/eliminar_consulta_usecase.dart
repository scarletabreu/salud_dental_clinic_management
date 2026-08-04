import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/helpers/consulta_helper.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';

/// Use Case para eliminar una consulta de forma segura.
///
/// Realiza validaciones de guardrail antes de ejecutar el delete:
/// - Solo permite eliminar consultas de hoy
/// - Solo sin tratamientos aplicados
/// - Solo sin pre-factura
///
/// Aunque la UI debería haber ocultado el botón, esta validación en el
/// repositorio es defensiva contra manipulaciones o carreras de condición.
class EliminarConsultaUseCase {
  final ConsultaRepository repository;

  EliminarConsultaUseCase({required this.repository});

  /// Elimina una consulta si cumple los criterios de eliminabilidad.
  ///
  /// Lanza una excepción si la consulta no es eliminable.
  /// TODO: Registrar en auditoría cuando exista el mecanismo.
  Future<void> call(Consulta consulta) async {
    if (!esConsultaEliminable(consulta)) {
      throw Exception(
        'No se puede eliminar esta consulta: ${razonNoEliminable(consulta)}',
      );
    }

    if (consulta.id == null) {
      throw Exception('La consulta debe tener un ID válido para ser eliminada.');
    }

    // Ejecutar el delete; las cascadas FK del esquema se encargan del resto.
    await repository.eliminarConsulta(consulta.id!);

    // TODO: Registrar en sistema de auditoría:
    // - Usuario que realizó la eliminación
    // - Timestamp exacto
    // - ID de consulta eliminada
    // - Motivo (error de creación, etc.)
  }
}
