import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

sealed class PersonalPerfilesState extends Equatable {
  const PersonalPerfilesState();

  @override
  List<Object?> get props => [];
}

class PerfilInitial extends PersonalPerfilesState {
  const PerfilInitial();
}

class PerfilLoading extends PersonalPerfilesState {
  const PerfilLoading();
}

class PerfilError extends PersonalPerfilesState {
  final String message;
  const PerfilError(this.message);

  @override
  List<Object?> get props => [message];
}

class PerfilLoaded extends PersonalPerfilesState {
  final List<Usuario> todos;
  final List<Usuario> filtrados;
  final RolUsuario? rolFiltro;
  final String queryBusqueda;

  const PerfilLoaded({
    required this.todos,
    required this.filtrados,
    this.rolFiltro,
    this.queryBusqueda = '',
  });

  PerfilLoaded copyWith({
    List<Usuario>? todos,
    List<Usuario>? filtrados,
    RolUsuario? Function()? rolFiltro,
    String? queryBusqueda,
  }) {
    return PerfilLoaded(
      todos: todos ?? this.todos,
      filtrados: filtrados ?? this.filtrados,
      rolFiltro: rolFiltro != null ? rolFiltro() : this.rolFiltro,
      queryBusqueda: queryBusqueda ?? this.queryBusqueda,
    );
  }

  @override
  List<Object?> get props => [todos, filtrados, rolFiltro, queryBusqueda];
}
