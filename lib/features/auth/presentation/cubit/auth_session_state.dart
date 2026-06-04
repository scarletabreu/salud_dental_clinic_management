import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/auth_usuario.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  final AuthUsuario usuario;
  const Authenticated(this.usuario);

  @override
  List<Object?> get props => [usuario.id];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
