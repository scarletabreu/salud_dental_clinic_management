// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UsuarioRepository _usuarioRepository;
  StreamSubscription<dynamic>? _authSubscription;

  AuthCubit({required UsuarioRepository usuarioRepository})
    : _usuarioRepository = usuarioRepository,
      super(const AuthState()) {
    _subscribeToAuthChanges();
  }

  void _subscribeToAuthChanges() {
    _authSubscription = _usuarioRepository.onAuthStateChange.listen((
      authState,
    ) async {
      final session = authState.session;

      if (session == null) {
        if (state.isAuthenticated) emit(const AuthState());
        return;
      }

      if (state.isAuthenticated && state.usuario?.id == session.user.id) return;

      await _cargarPerfilDesdeUuid(session.user.id);
    });
  }

  Future<void> _cargarPerfilDesdeUuid(String uuid) async {
    try {
      final usuario = await _usuarioRepository.getPerfilPorUuid(uuid);
      if (usuario != null) {
        emit(state.copyWith(isAuthenticated: true, usuario: usuario));
      } else {
        emit(const AuthState());
      }
    } catch (_) {
      emit(const AuthState());
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final usuario = await _usuarioRepository.loginUsuario(username, password);
      emit(state.copyWith(isAuthenticated: true, usuario: usuario));
    } catch (e) {
      emit(AuthState(error: _parseError(e.toString())));
    }
  }

  Future<void> logout() async {
    await _usuarioRepository.signOut();
    emit(const AuthState());
  }

  String _parseError(String raw) {
    if (raw.contains('Invalid login credentials') ||
        raw.contains('invalid_credentials')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (raw.contains('no tiene un perfil operativo')) {
      return 'El usuario no tiene un rol asignado. Contacta al administrador.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'Sin conexión. Verifica tu red e intenta de nuevo.';
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
