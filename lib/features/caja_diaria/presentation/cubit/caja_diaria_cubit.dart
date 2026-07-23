import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

class CajaDiariaCubit extends Cubit<CajaDiariaState> {
  CajaDiariaCubit(this._repository) : super(const CajaDiariaLoading());

  final CajaDiariaRepository _repository;
  StreamSubscription<List<MovimientoCaja>>? _movimientosSubscription;
  CajaDiaria? _cajaActual;

  Future<void> cargar() async {
    await _movimientosSubscription?.cancel();
    _movimientosSubscription = null;
    emit(const CajaDiariaLoading());

    try {
      final caja = await _repository.getCajaActual();
      if (caja == null) {
        _cajaActual = null;
        emit(const CajaDiariaSinAbrir());
        return;
      }

      _cajaActual = caja;
      emit(CajaDiariaAbierta(caja: caja));
      _movimientosSubscription = _repository
          .watchMovimientos(caja.id!)
          .listen(
            (movimientos) {
              final cajaActual = _cajaActual;
              if (cajaActual != null && !isClosed) {
                emit(
                  CajaDiariaAbierta(caja: cajaActual, movimientos: movimientos),
                );
              }
            },
            onError: (_, _) {
              // La caja sigue siendo útil aunque se retrase el stream de movimientos.
            },
          );
    } catch (_) {
      emit(const CajaDiariaError('No se pudo consultar la caja de hoy.'));
    }
  }

  Future<String?> abrirCaja(double montoApertura) async {
    if (montoApertura < 0) return 'El monto inicial no puede ser negativo.';

    try {
      await _repository.abrirCaja(montoApertura);
      await cargar();
      return null;
    } catch (_) {
      if (!isClosed) {
        emit(
          const CajaDiariaSinAbrir(
            error:
                'No se pudo abrir la caja. Verifica tu conexión e inténtalo de nuevo.',
          ),
        );
      }
      return 'No se pudo abrir la caja. Inténtalo de nuevo.';
    }
  }

  @override
  Future<void> close() async {
    await _movimientosSubscription?.cancel();
    return super.close();
  }

  ResumenCierre? obtenerResumenCierre() {
    final currentState = state;
    if (currentState is! CajaDiariaAbierta) return null;

    final Map<String, double> totalesPorMetodo = {
      'Efectivo / General': currentState.ingresos,
    };

    return ResumenCierre(
      totalesPorMetodoPago: totalesPorMetodo,
      totalIngresos: currentState.ingresos,
      totalEgresos: currentState.egresos,
      montoEsperado: currentState.montoEsperado,
      movimientos: currentState.movimientos,
    );
  }

  Future<String?> cerrarCaja({
    required double montoReal,
    required double montoEsperado,
  }) async {
    try {
      await _repository.cerrarCaja(
        montoReal: montoReal,
        montoCierre: montoReal,
      );
      return null;
    } catch (e) {
      return 'Error al cerrar la caja: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }
}
