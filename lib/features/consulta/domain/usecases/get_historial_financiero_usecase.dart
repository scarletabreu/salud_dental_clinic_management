import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class GetHistorialFinancieroUseCase {
  final CuentaRepository repository;

  GetHistorialFinancieroUseCase({required this.repository});

  Future<List<Cuenta>> call(String pacienteId) =>
      repository.getHistorialFinanciero(pacienteId);
}
