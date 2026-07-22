import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';

class EmitirFactura {
  final CuentaRepository repository;
  EmitirFactura(this.repository);

  Future<Cuenta> call({
    required String consultaId,
    required MetodoPago modoPago,
    required TipoPaciente tipoPaciente,
  }) async {
    final cuenta = await repository.getCuentaByConsultaId(consultaId);
    if (cuenta == null) {
      throw Exception('No existe cuenta ABIERTA para la consulta $consultaId');
    }
    final cuentaActualizada = cuenta.emitirFactura(
      modoPago: modoPago,
      tipoPaciente: tipoPaciente,
    );
    await repository.actualizarCuenta(cuentaActualizada);
    return cuentaActualizada;
  }
}