import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class GetCuentasPorCobrarUseCase {
  final CuentaRepository repository;

  GetCuentasPorCobrarUseCase({required this.repository});

  Future<List<Cuenta>> call() => repository.getCuentasPorCobrar();
}
