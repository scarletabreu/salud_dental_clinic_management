import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class CerrarCuenta {
  final CuentaRepository repository;
  CerrarCuenta(this.repository);

  Future<Cuenta> call(String consultaId) async {
    final cuenta = await repository.getCuentaByConsultaId(consultaId);
    if (cuenta == null) throw Exception('Cuenta no encontrada');
    final cuentaActualizada = cuenta.cerrarCuenta();
    await repository.actualizarCuenta(cuentaActualizada);
    return cuentaActualizada;
  }
}