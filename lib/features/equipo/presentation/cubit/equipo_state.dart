import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';

sealed class EquipoState {
  const EquipoState();
}

class EquipoInitial extends EquipoState {
  const EquipoInitial();
}

class EquipoLoading extends EquipoState {
  const EquipoLoading();
}

class EquipoLoaded extends EquipoState {
  final List<Equipo> todos;
  final List<Equipo> filtrados;
  final String searchQuery;

  const EquipoLoaded({
    required this.todos,
    required this.filtrados,
    this.searchQuery = '',
  });

  EquipoLoaded copyWith({
    List<Equipo>? todos,
    List<Equipo>? filtrados,
    String? searchQuery,
  }) {
    return EquipoLoaded(
      todos: todos ?? this.todos,
      filtrados: filtrados ?? this.filtrados,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EquipoError extends EquipoState {
  final String message;
  const EquipoError(this.message);
}

class EquipoOperating extends EquipoLoaded {
  const EquipoOperating({
    required super.todos,
    required super.filtrados,
    super.searchQuery,
  });
}
