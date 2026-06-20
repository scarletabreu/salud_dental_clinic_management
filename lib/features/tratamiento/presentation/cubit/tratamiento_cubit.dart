import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'tratamiento_state.dart';

class TratamientoCubit extends Cubit<TratamientoState> {
  final TratamientoRepository _repository;

  TratamientoCubit(this._repository) : super(const TratamientoInitial());

  Future<void> loadTratamientos() async {
    emit(const TratamientoLoading());
    try {
      final lista = await _repository.getCatalogoTratamientos();
      emit(TratamientoLoaded(lista));
    } catch (e) {
      emit(TratamientoError('Error al cargar datos desde el servidor: $e'));
    }
  }

  Future<bool> guardarTratamiento(Tratamiento tratamiento) async {
    if (state is! TratamientoLoaded) return false;
    final tratamientosActuales = (state as TratamientoLoaded).tratamientos;

    final existeDuplicado = tratamientosActuales.any(
      (t) =>
          t.nombre.trim().toLowerCase() ==
              tratamiento.nombre.trim().toLowerCase() &&
          t.id != tratamiento.id,
    );

    if (existeDuplicado) {
      emit(TratamientoError(
        'Ya existe un tratamiento con el nombre "${tratamiento.nombre}".',
      ));
      emit(TratamientoLoaded(tratamientosActuales));
      return false;
    }

    try {
      await _repository.guardarTratamiento(tratamiento);
      await loadTratamientos();
      return true;
    } catch (e) {
      emit(TratamientoError('Error al guardar el tratamiento: $e'));
      emit(TratamientoLoaded(tratamientosActuales));
      return false;
    }
  }

  Future<void> eliminarTratamiento(String id) async {
    if (state is! TratamientoLoaded) return;
    final tratamientosActuales = (state as TratamientoLoaded).tratamientos;

    try {
      await _repository.eliminarTratamiento(id);
      await loadTratamientos();
    } catch (e) {
      emit(TratamientoError('Error al eliminar: $e'));
      emit(TratamientoLoaded(tratamientosActuales));
    }
  }
}
