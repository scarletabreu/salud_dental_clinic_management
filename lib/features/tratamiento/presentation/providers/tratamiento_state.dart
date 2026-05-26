import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';

abstract class TratamientoState {}

class TratamientoInitial extends TratamientoState {}

class TratamientoLoading extends TratamientoState {}

class TratamientoLoaded extends TratamientoState {
  final List<Tratamiento> tratamientos;
  TratamientoLoaded(this.tratamientos);
}

class TratamientoError extends TratamientoState {
  final String message;
  TratamientoError(this.message);
}

class TratamientoCubit extends Cubit<TratamientoState> {
  final TratamientoRepository repository;

  TratamientoCubit({required this.repository}) : super(TratamientoInitial());

  Future<void> loadTratamientos() async {
    emit(TratamientoLoading());
    try {
      final lista = await repository.getCatalogoTratamientos();
      emit(TratamientoLoaded(lista));
    } catch (e) {
      emit(TratamientoError(e.toString()));
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
      emit(
        TratamientoError(
          'Ya existe un tratamiento con el nombre "${tratamiento.nombre}".',
        ),
      );
      emit(TratamientoLoaded(tratamientosActuales));
      return false;
    }

    try {
      await repository.guardarTratamiento(tratamiento);
      await loadTratamientos();
      return true;
    } catch (e) {
      emit(TratamientoError('Error al guardar: $e'));
      emit(TratamientoLoaded(tratamientosActuales));
      return false;
    }
  }

  Future<void> eliminarTratamiento(String id) async {
    if (state is! TratamientoLoaded) return;
    final deRespaldo = (state as TratamientoLoaded).tratamientos;
    try {
      await repository.eliminarTratamiento(id);
      await loadTratamientos();
    } catch (e) {
      emit(TratamientoError('Error al eliminar: $e'));
      emit(TratamientoLoaded(deRespaldo));
    }
  }
}
