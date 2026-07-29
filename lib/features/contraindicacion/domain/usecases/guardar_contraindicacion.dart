import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';

class GuardarContraindicacion {
  final ContraindicacionRepository repository;

  GuardarContraindicacion(this.repository);

  Future<void> call(Contraindicacion contraindicacion) async {
    return repository.guardarContraindicacion(contraindicacion);
  }
}
