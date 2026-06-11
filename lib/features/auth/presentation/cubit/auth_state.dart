import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final Usuario? usuario;
  final String? error;

  final List<RolUsuario> _extraRoles;

  const AuthState({
    this.isAuthenticated = false,
    this.usuario,
    this.error,
    List<RolUsuario> extraRoles = const [],
  }) : _extraRoles = extraRoles;

  RolUsuario? get rol => usuario?.rol;

  List<RolUsuario> get roles {
    if (usuario == null) return const [];
    return {usuario!.rol, ..._extraRoles}.toList();
  }

  bool hasRole(RolUsuario rol) => roles.contains(rol);

  bool hasAllRoles(List<RolUsuario> checkRoles) =>
      checkRoles.every(roles.contains);

  bool hasAnyRole(List<RolUsuario> checkRoles) =>
      checkRoles.any(roles.contains);

  AuthState copyWith({
    bool? isAuthenticated,
    Usuario? usuario,
    String? error,
    List<RolUsuario>? extraRoles,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      usuario: usuario ?? this.usuario,
      error: error, // null limpia el error anterior
      extraRoles: extraRoles ?? _extraRoles,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, usuario, error, _extraRoles];
}
