import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

enum CalendarioViewMode { mensual, semanal, diaria }

abstract class CitaCubitState extends Equatable {
  const CitaCubitState();

  @override
  List<Object?> get props => [];
}

class CitaCubitLoading extends CitaCubitState {
  const CitaCubitLoading();
}

class CitaCubitLoaded extends CitaCubitState {
  final List<Cita> citas;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarioViewMode viewMode;

  final bool isSubmitting;
  final String? errorMessage;

  const CitaCubitLoaded({
    required this.citas,
    required this.focusedDay,
    required this.selectedDay,
    required this.viewMode,
    this.isSubmitting = false,
    this.errorMessage,
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

  CitaCubitLoaded copyWith({
    List<Cita>? citas,
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarioViewMode? viewMode,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) {
    return CitaCubitLoaded(
      citas: citas ?? this.citas,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      viewMode: viewMode ?? this.viewMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [citas, focusedDay, selectedDay, viewMode];
}

class CitaCubitError extends CitaCubitState {
  final String message;

  const CitaCubitError(this.message);

  @override
  List<Object?> get props => [message];
}
