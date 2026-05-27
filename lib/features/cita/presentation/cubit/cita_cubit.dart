import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'cita_state.dart';

class CitaCubit extends Cubit<CitaState> {
  final CitaRepository _repository;

  CitaCubit(this._repository) : super(const CitaLoading());

  Future<void> load() async {
    emit(const CitaLoading());
    try {
      final citas = await _repository.getCitas();
      final now = DateTime.now();
      emit(
        CitaLoaded(
          citas: citas,
          focusedDay: now,
          selectedDay: now,
          viewMode: CalendarioViewMode.mensual,
        ),
      );
    } catch (e) {
      emit(CitaError(e.toString()));
    }
  }

  Future<void> cambiarEstadoCita(String id, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! CitaLoaded) return;

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
      emit(CitaError('No se pudo actualizar el estado de la cita: $e'));
    }
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    final current = state;
    if (current is! CitaLoaded) return;
    emit(current.copyWith(selectedDay: selectedDay, focusedDay: focusedDay));
  }

  void onPageChanged(DateTime focusedDay) {
    final current = state;
    if (current is! CitaLoaded) return;
    emit(current.copyWith(focusedDay: focusedDay));
  }

  void changeViewMode(CalendarioViewMode mode) {
    final current = state;
    if (current is! CitaLoaded) return;
    emit(current.copyWith(viewMode: mode));
  }

  void goToToday() {
    final current = state;
    if (current is! CitaLoaded) return;
    final now = DateTime.now();
    emit(current.copyWith(focusedDay: now, selectedDay: now));
  }

  void goToNext() {
    final current = state;
    if (current is! CitaLoaded) return;
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
    if (current is! CitaLoaded) return;
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
    if (current is! CitaLoaded) return [];
    return current.citasForDay(day);
  }
}
