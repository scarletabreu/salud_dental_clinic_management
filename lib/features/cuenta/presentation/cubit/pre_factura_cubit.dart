import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';
import 'pre_factura_state.dart';

class PreFacturaCubit extends Cubit<PreFacturaState> {
  final GetCuentaByIdUseCase _getCuenta;
  final RegistrarPago _registrarPago;

  PreFacturaCubit({
    required GetCuentaByIdUseCase getCuenta,
    required RegistrarPago registrarPago,
  })  : _getCuenta = getCuenta,
        _registrarPago = registrarPago,
        super(const PreFacturaInicial());

  Future<void> cargar(String cuentaId) async {
    emit(const PreFacturaCargando());
    try {
      final cuenta = await _getCuenta(cuentaId);
      emit(PreFacturaCargada(cuenta));
    } catch (e) {
      emit(PreFacturaError('No se pudo cargar la cuenta.\n$e'));
    }
  }

  Future<void> recargar(String cuentaId) => cargar(cuentaId);

  /// Registra un cobro sobre la cuenta actualmente cargada y la recarga para
  /// reflejar el nuevo saldo y estado. Devuelve `null` si el cobro fue exitoso o
  /// un mensaje de error mostrable si falló (validación, red o servidor). No
  /// emite estados de error para no tumbar la pantalla: el diálogo de cobro
  /// gestiona su propio feedback con el mensaje devuelto.
  Future<String?> registrarPago({
    required double monto,
    required MetodoPago metodo,
  }) async {
    final actual = state;
    if (actual is! PreFacturaCargada) {
      return 'La cuenta aún no está cargada.';
    }

    try {
      await _registrarPago(cuenta: actual.cuenta, monto: monto, metodo: metodo);
      await cargar(actual.cuenta.id!);
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo registrar el pago. Inténtalo de nuevo.';
    }
  }
}
