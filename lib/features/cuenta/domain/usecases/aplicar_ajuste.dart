import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class AplicarAjuste {
  final CuentaRepository repository;
  AplicarAjuste(this.repository);

  Future<Cuenta> call({
    required String cuentaId,
    required String consultaId,
    required double monto,
    required String motivo,
    required String? doctorAutorizaId,
  }) async {
    final cuenta = await repository.getCuentaByConsultaId(consultaId);
    if (cuenta == null) throw Exception('Cuenta no encontrada');
    final cuentaActualizada = cuenta.aplicarAjuste(
      monto: monto,
      motivo: motivo,
      doctorAutorizaId: doctorAutorizaId,
    );
    await repository.actualizarCuenta(cuentaActualizada);
    return cuentaActualizada;
  }
}