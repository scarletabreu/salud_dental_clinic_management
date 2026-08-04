import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/listado_perfiles.dart';
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

  /// Perfiles que no se pudieron cargar. Se pintan como tarjeta de error junto
  /// a los demás, en vez de sustituir la pantalla entera por un error global.
  final List<AvisoPerfil> avisos;

  const PerfilLoaded({
    required this.todos,
    required this.filtrados,
    this.rolFiltro,
    this.queryBusqueda = '',
    this.avisos = const [],
  });

  /// Los avisos también se filtran: si hay un rol seleccionado sólo se muestran
  /// los suyos, y una búsqueda por texto los oculta (no hay nada que buscar en
  /// un perfil que no cargó).
  List<AvisoPerfil> get avisosVisibles {
    if (queryBusqueda.trim().isNotEmpty) return const [];
    if (rolFiltro == null) return avisos;
    return avisos.where((a) => a.rol == rolFiltro).toList();
  }

  PerfilLoaded copyWith({
    List<Usuario>? todos,
    List<Usuario>? filtrados,
    RolUsuario? Function()? rolFiltro,
    String? queryBusqueda,
    List<AvisoPerfil>? avisos,
  }) {
    return PerfilLoaded(
      todos: todos ?? this.todos,
      filtrados: filtrados ?? this.filtrados,
      rolFiltro: rolFiltro != null ? rolFiltro() : this.rolFiltro,
      queryBusqueda: queryBusqueda ?? this.queryBusqueda,
      avisos: avisos ?? this.avisos,
    );
  }

  @override
  List<Object?> get props => [
    todos,
    filtrados,
    rolFiltro,
    queryBusqueda,
    avisos,
  ];
}
