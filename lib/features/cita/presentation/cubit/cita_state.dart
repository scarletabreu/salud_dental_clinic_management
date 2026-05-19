import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

enum CalendarioViewMode { mensual, semanal, diaria }

abstract class CitaState extends Equatable {
  const CitaState();

  @override
  List<Object?> get props => [];
}

class CitaLoading extends CitaState {
  const CitaLoading();
}

class CitaLoaded extends CitaState {
  final List<Cita> citas;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarioViewMode viewMode;

  const CitaLoaded({
    required this.citas,
    required this.focusedDay,
    required this.selectedDay,
    required this.viewMode,
  });

  List<Cita> citasForDay(DateTime day) {
    return citas
        .where(
          (c) =>
              c.date.year == day.year &&
              c.date.month == day.month &&
              c.date.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  CitaLoaded copyWith({
    List<Cita>? citas,
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarioViewMode? viewMode,
  }) {
    return CitaLoaded(
      citas: citas ?? this.citas,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [citas, focusedDay, selectedDay, viewMode];
}

class CitaError extends CitaState {
  final String message;

  const CitaError(this.message);

  @override
  List<Object?> get props => [message];
}
