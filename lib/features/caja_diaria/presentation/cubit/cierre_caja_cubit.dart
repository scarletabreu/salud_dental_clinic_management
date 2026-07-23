import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'cierre_caja_state.dart';

class CierreCajaCubit extends Cubit<CierreCajaState> {
  final CajaDiariaRepository repository;

  CierreCajaCubit(this.repository) : super(CierreCajaInitial());

  Future<void> cargarResumen() async {
    emit(CierreCajaLoading());
    try {
      final resumen = await repository.getResumenCierre();
      emit(
        CierreCajaResumenCargado(
          resumen: resumen,
          montoContado: 0,
          diferencia: 0 - resumen.montoEsperado,
        ),
      );
    } catch (e) {
      emit(CierreCajaError('No se pudo cargar el resumen de caja: $e'));
    }
  }

  void actualizarConteo(double montoContado) {
    final actual = state;
    if (actual is CierreCajaResumenCargado) {
      emit(actual.copyWith(montoContado: montoContado));
    }
  }

  Future<void> confirmarCierre({String? observaciones}) async {
    final actual = state;
    if (actual is! CierreCajaResumenCargado) return;

    emit(CierreCajaConfirmando());
    try {
      await repository.cerrarCaja(
        montoReal: actual.montoContado,
        montoCierre: actual.montoContado,
        observaciones: observaciones,
      );
      emit(
        CierreCajaExito(
          resumen: actual.resumen,
          montoContado: actual.montoContado,
          diferencia: actual.diferencia,
          fechaCierre: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(CierreCajaError('No se pudo cerrar la caja: $e'));
      emit(actual);
    }
  }
}
