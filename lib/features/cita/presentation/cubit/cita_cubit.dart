import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'cita_cubit_state.dart';

class CitaCubit extends Cubit<CitaCubitState> {
  final CitaRepository _repository;

  CitaCubit(this._repository) : super(const CitaCubitLoading());

  Future<void> load() async {
    emit(const CitaCubitLoading());
    try {
      final citas = await _repository.getCitas();
      final now = DateTime.now();
      emit(
        CitaCubitLoaded(
          citas: citas,
          focusedDay: now,
          selectedDay: now,
          viewMode: CalendarioViewMode.mensual,
        ),
      );
    } catch (e) {
      emit(CitaCubitError(e.toString()));
    }
  }

  bool _tieneConflictoHorario(Cita nuevaCita, List<Cita> todasLasCitas) {
    return todasLasCitas.any((c) {
      if (c.id == nuevaCita.id) return false;
      if (c.doctor.id != nuevaCita.doctor.id) return false;
      if (c.estado == EstadoCita.cancelada) return false;

      return nuevaCita.date.isBefore(c.fechaFin) &&
          c.date.isBefore(nuevaCita.fechaFin);
    });
  }

  Future<void> createCita(Cita cita) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      emit(current.copyWith(isSubmitting: true, errorMessage: () => null));

      if (_tieneConflictoHorario(cita, current.citas)) {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: () =>
                'El odontólogo elegido ya tiene una cita programada en ese horario.',
          ),
        );
        return;
      }

      print('Datos enviados a Supabase: $cita');
      await _repository.createCita(cita);
      await load();
    } catch (e) {
      print('Error capturado en Cubit: $e');
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: () => 'Error 400: Revisa los campos enviados. $e',
        ),
      );
    }
  }

  Future<void> cambiarEstadoCita(String id, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      await _repository.updateCitaEstado(id, nuevoEstado);

      final citasActualizadas = current.citas.map((cita) {
        if (cita.id == id) {
          return cita.copyWith(estado: nuevoEstado);
        }
        return cita;
      }).toList();

      emit(current.copyWith(citas: citasActualizadas));
    } catch (e) {
      emit(
        current.copyWith(
          errorMessage: () => 'No se pudo actualizar el estado de la cita: $e',
        ),
      );
    }
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(
      current.copyWith(
        selectedDay: selectedDay,
        focusedDay: focusedDay,
        errorMessage: () => null,
      ),
    );
  }

  void onPageChanged(DateTime focusedDay) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(current.copyWith(focusedDay: focusedDay));
  }

  void changeViewMode(CalendarioViewMode mode) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(current.copyWith(viewMode: mode));
  }

  void goToToday() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    final now = DateTime.now();
    emit(current.copyWith(focusedDay: now, selectedDay: now));
  }

  void goToNext() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    if (current.viewMode == CalendarioViewMode.diaria) {
      final next = current.selectedDay.add(const Duration(days: 1));
      emit(current.copyWith(focusedDay: next, selectedDay: next));
      return;
    }
    final next = current.viewMode == CalendarioViewMode.mensual
        ? DateTime(current.focusedDay.year, current.focusedDay.month + 1, 1)
        : current.focusedDay.add(const Duration(days: 7));
    emit(current.copyWith(focusedDay: next));
  }

  void goPrevious() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    if (current.viewMode == CalendarioViewMode.diaria) {
      final prev = current.selectedDay.subtract(const Duration(days: 1));
      emit(current.copyWith(focusedDay: prev, selectedDay: prev));
      return;
    }
    final prev = current.viewMode == CalendarioViewMode.mensual
        ? DateTime(current.focusedDay.year, current.focusedDay.month - 1, 1)
        : current.focusedDay.subtract(const Duration(days: 7));
    emit(current.copyWith(focusedDay: prev));
  }

  List<Cita> eventLoader(DateTime day) {
    final current = state;
    if (current is! CitaCubitLoaded) return [];
    return current.citasForDay(day);
  }

  Future<void> actualizarCita(Cita citaActualizada) async {
    print("ACTUALIZAR CUBIT: $hashCode");
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      emit(current.copyWith(isSubmitting: true, errorMessage: () => null));

      final tieneChoque = current.citas.any((c) {
        if (c.id == citaActualizada.id) return false;
        if (c.doctor.id != citaActualizada.doctor.id) return false;

        return citaActualizada.date.isBefore(c.fechaFin) &&
            c.date.isBefore(citaActualizada.fechaFin);
      });

      if (tieneChoque) {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: () =>
                'El odontólogo elegido no tiene disponibilidad en este horario.',
          ),
        );
        return;
      }

      await _repository.updateCita(citaActualizada);

      final citasActualizadas = await _repository.getCitas();

      emit(
        current.copyWith(
          citas: citasActualizadas,
          isSubmitting: false,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      print('Error capturado en actualizarCita: $e');
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: () => 'Error al guardar cambios en el servidor: $e',
        ),
      );
    }
  }
}
