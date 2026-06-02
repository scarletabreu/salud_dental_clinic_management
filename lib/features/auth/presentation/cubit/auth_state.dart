// lib/features/auth/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final Usuario? usuario;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.usuario,
    this.error,
  });

  RolUsuario? get rol => usuario?.rol;

  AuthState copyWith({
    bool? isAuthenticated,
    Usuario? usuario,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      usuario: usuario ?? this.usuario,
      error: error, // null limpia el error anterior
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, usuario, error];
}