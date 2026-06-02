import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/auth_usuario.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial mientras se verifica la sesión almacenada.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Operación en curso (sign-in o sign-out).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Sesión activa y válida.
final class Authenticated extends AuthState {
  final AuthUsuario usuario;
  const Authenticated(this.usuario);

  @override
  List<Object?> get props => [usuario.id];
}

/// Sin sesión activa (nunca inició sesión o cerró sesión).
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error durante el inicio de sesión.
final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}