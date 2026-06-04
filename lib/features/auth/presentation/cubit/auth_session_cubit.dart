import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthState> {
  final IAuthRepository _repository;
  StreamSubscription<dynamic>? _authSubscription;

  AuthSessionCubit(this._repository) : super(const AuthInitial());

  void initialize() {
    _authSubscription = _repository.onAuthStateChange.listen((usuario) {
      if (usuario != null) {
        emit(Authenticated(usuario));
      } else {
        emit(const Unauthenticated());
      }
    }, onError: (_) => emit(const Unauthenticated()));

    final current = _repository.currentUser;
    if (current != null) {
      emit(Authenticated(current));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final usuario = await _repository.signIn(
        email: email,
        password: password,
      );
      emit(Authenticated(usuario));
    } on Exception catch (e) {
      final raw = e.toString();

      if (raw.contains('Invalid login credentials') ||
          raw.contains('invalid_credentials')) {
        emit(const AuthError('Correo o contraseña incorrectos.'));
      } else if (raw.contains('Email not confirmed')) {
        emit(const AuthError('Debes confirmar tu correo electrónico primero.'));
      } else if (raw.contains('network') || raw.contains('SocketException')) {
        emit(
          const AuthError('Sin conexión. Verifica tu red e intenta de nuevo.'),
        );
      } else {
        emit(const AuthError('Ocurrió un error inesperado. Intenta de nuevo.'));
      }
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
      emit(const Unauthenticated());
    } on Exception {
      emit(const Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
