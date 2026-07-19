import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class ObtenerCuentaPorConsulta {
  final CuentaRepository repository;
  ObtenerCuentaPorConsulta(this.repository);

  Future<Cuenta?> call(String consultaId) {
    return repository.getCuentaByConsultaId(consultaId);
  }
}