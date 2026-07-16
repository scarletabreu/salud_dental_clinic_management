import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'pre_factura_state.dart';

class PreFacturaCubit extends Cubit<PreFacturaState> {
  final GetCuentaByIdUseCase _getCuenta;

  PreFacturaCubit({required GetCuentaByIdUseCase getCuenta})
    : _getCuenta = getCuenta,
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
}
