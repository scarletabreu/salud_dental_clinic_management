import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/eliminar_equipo_usecase.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/get_inventario_usecase.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/registrar_o_actualizar_equipo_usecase.dart';
import 'equipo_state.dart';

class EquipoCubit extends Cubit<EquipoState> {
  final GetInventarioEquiposUseCase _getInventario;
  final RegistrarOActualizarEquipoUseCase _registrarOActualizar;
  final EliminarEquipoUseCase _eliminar;

  EquipoCubit({
    required GetInventarioEquiposUseCase getInventario,
    required RegistrarOActualizarEquipoUseCase registrarOActualizar,
    required EliminarEquipoUseCase eliminar,
  }) : _getInventario = getInventario,
       _registrarOActualizar = registrarOActualizar,
       _eliminar = eliminar,
       super(const EquipoInitial());

  Future<void> cargarEquipos() async {
    emit(const EquipoLoading());
    try {
      final equipos = await _getInventario();
      emit(EquipoLoaded(todos: equipos, filtrados: equipos));
    } catch (e) {
      emit(EquipoError('No se pudo cargar el inventario de equipos.\n$e'));
    }
  }

  void aplicarFiltros({String? query}) {
    final current = state;
    if (current is! EquipoLoaded) return;

    final q = (query ?? current.searchQuery).toLowerCase().trim();

    final filtrados = current.todos.where((e) {
      if (q.isEmpty) return true;
      return e.nombre.toLowerCase().contains(q) ||
          e.descripcion.toLowerCase().contains(q);
    }).toList();

    emit(current.copyWith(filtrados: filtrados, searchQuery: q));
  }

  Future<bool> guardarEquipo(Equipo equipo) async {
    final current = state;
    if (current is! EquipoLoaded) return false;

    emit(
      EquipoOperating(
        todos: current.todos,
        filtrados: current.filtrados,
        searchQuery: current.searchQuery,
      ),
    );

    try {
      await _registrarOActualizar(equipo);
      await cargarEquipos();
      return true;
    } catch (e) {
      // Restauramos el estado anterior y dejamos que la UI maneje el error
      emit(current);
      return false;
    }
  }

  Future<bool> eliminarEquipo(String id) async {
    final current = state;
    if (current is! EquipoLoaded) return false;

    emit(
      EquipoOperating(
        todos: current.todos,
        filtrados: current.filtrados,
        searchQuery: current.searchQuery,
      ),
    );

    try {
      await _eliminar(id);
      await cargarEquipos();
      return true;
    } catch (e) {
      emit(current);
      return false;
    }
  }
}
