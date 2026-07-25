import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/actualizar_existencia.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/eliminar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/get_inventario.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/guardar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_state.dart';

class InventarioCubit extends Cubit<InventarioState> {
  final GetInventario _getInventario;
  final GuardarConsumible _guardarConsumible;
  final ActualizarExistencia _actualizarExistencia;
  final EliminarConsumible _eliminarConsumible;

  InventarioCubit({
    required GetInventario getInventario,
    required GuardarConsumible guardarConsumible,
    required ActualizarExistencia actualizarExistencia,
    required EliminarConsumible eliminarConsumible,
  }) : _getInventario = getInventario,
       _guardarConsumible = guardarConsumible,
       _actualizarExistencia = actualizarExistencia,
       _eliminarConsumible = eliminarConsumible,
       super(const InventarioLoading());

  Future<void> cargar() async {
    emit(const InventarioLoading());
    try {
      final list = await _getInventario();
      emit(InventarioLoaded(consumibles: list));
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
    } catch (e) {
      return 'Error al guardar el artículo: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  Future<String?> ajustarStock(String id, int nuevoStock) async {
    try {
      await _actualizarExistencia(id, nuevoStock);
      await cargar();
      return null;
    } catch (e) {
      return 'Error al actualizar el stock.';
    }
  }

  Future<String?> eliminar(String id) async {
    try {
      await _eliminarConsumible(id);
      await cargar();
      return null;
    } catch (e) {
      return 'Error al eliminar el consumible.';
    }
  }
}
