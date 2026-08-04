import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/get_historial_financiero_usecase.dart';
import 'historial_financiero_state.dart';

class HistorialFinancieroCubit extends Cubit<HistorialFinancieroState> {
  final GetHistorialFinancieroUseCase _getHistorial;

  HistorialFinancieroCubit({
    required GetHistorialFinancieroUseCase getHistorial,
  }) : _getHistorial = getHistorial,
       super(const HistorialFinancieroInitial());

  Future<void> cargar(String pacienteId) async {
    emit(const HistorialFinancieroLoading());
    try {
      final cuentas = await _getHistorial(pacienteId);

      final totalPendiente = cuentas.fold(
        0.0,
        (sum, c) => sum + (c.balancePendiente > 0 ? c.balancePendiente : 0),
      );
      final totalCobrado = cuentas.fold(0.0, (sum, c) => sum + c.montoPagado);
      final totalFacturado = cuentas.fold(0.0, (sum, c) => sum + c.montoTotal);

      emit(
        HistorialFinancieroLoaded(
          cuentas: cuentas,
          totalPendiente: totalPendiente,
          totalCobrado: totalCobrado,
          totalFacturado: totalFacturado,
        ),
      );
    } catch (e) {
      emit(
        HistorialFinancieroError(
          'No se pudo cargar el historial financiero.\n$e',
        ),
      );
    }
  }
}
