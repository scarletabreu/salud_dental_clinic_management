import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/actualizar_existencia.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/eliminar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/get_inventario.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/guardar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_state.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/get_directorio_suplidores.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';

class InventarioCubit extends Cubit<InventarioState> {
  final GetInventario _getInventario;
  final GuardarConsumible _guardarConsumible;
  final ActualizarExistencia _actualizarExistencia;
  final EliminarConsumible _eliminarConsumible;
  final GetDirectorioSuplidores _getDirectorioSuplidores;

  StreamSubscription<void>? _senalInventario;

  InventarioCubit({
    required GetInventario getInventario,
    required GuardarConsumible guardarConsumible,
    required ActualizarExistencia actualizarExistencia,
    required EliminarConsumible eliminarConsumible,
    required GetDirectorioSuplidores getDirectorioSuplidores,
    SenalesRealtime? senales,
  }) : _getInventario = getInventario,
       _guardarConsumible = guardarConsumible,
       _actualizarExistencia = actualizarExistencia,
       _eliminarConsumible = eliminarConsumible,
       _getDirectorioSuplidores = getDirectorioSuplidores,
       super(const InventarioLoading()) {
    // El consumo silencioso de las consultas llega a la pantalla (MU-4): la
    // señal recarga las existencias conservando búsqueda y filtro activos.
    _senalInventario = senales
        ?.de(DominioSenal.inventario)
        .listen((_) => _refrescarEnSilencio());
  }

  Future<void> _refrescarEnSilencio() async {
    if (state is! InventarioLoaded) return;
    try {
      final list = await _getInventario();
      final vigente = state;
      if (isClosed || vigente is! InventarioLoaded) return;
      emit(vigente.copyWith(consumibles: list));
    } catch (e) {
      // La pantalla conserva lo último que sí cargó.
      AppLog.error('refrescar el inventario', e);
    }
  }

  @override
  Future<void> close() async {
    await _senalInventario?.cancel();
    return super.close();
  }

  Future<void> cargar() async {
    emit(const InventarioLoading());
    try {
      final list = await _getInventario();
      List<Suplidor> suplidores = const [];
      try {
        suplidores = await _getDirectorioSuplidores();
      } catch (_) {
        // El suplidor es opcional; un fallo al cargarlo no bloquea el inventario.
      }
      emit(InventarioLoaded(consumibles: list, suplidores: suplidores));
    } catch (_) {
      emit(
        const InventarioError(
          'Error al cargar los consumibles del inventario.',
        ),
      );
    }
  }

  void filtrarPorBusqueda(String query) {
    final currentState = state;
    if (currentState is InventarioLoaded) {
      emit(currentState.copyWith(busqueda: query));
    }
  }

  void toggleFiltroCriticos(bool soloCriticos) {
    final currentState = state;
    if (currentState is InventarioLoaded) {
      emit(currentState.copyWith(soloCriticos: soloCriticos));
    }
  }

  Future<String?> guardar(Consumible consumible) async {
    try {
      await _guardarConsumible(consumible);
      await cargar();
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al guardar el artículo: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  Future<String?> ajustarStock(
    String id,
    int nuevoStock,
    MotivoAjusteStock motivo,
  ) async {
    try {
      if (nuevoStock < 0) return 'El stock no puede ser negativo.';
      await _actualizarExistencia(id, nuevoStock, motivo);
      await cargar();
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al actualizar el stock.';
    }
  }

  Future<String?> eliminar(String id) async {
    try {
      await _eliminarConsumible(id);
      await cargar();
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al dar de baja el consumible.';
    }
  }
}
