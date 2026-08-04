import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class GetCuentaByIdUseCase {
  final CuentaRepository repository;

  GetCuentaByIdUseCase({required this.repository});

  Future<Cuenta> call(String id) => repository.getCuentaById(id);
}
