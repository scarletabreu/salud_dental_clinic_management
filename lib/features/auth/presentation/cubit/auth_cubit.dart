// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
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

  // ── Escucha el stream de Supabase Auth para restaurar sesión al arrancar ──
  void _subscribeToAuthChanges() {
    _authSubscription = _usuarioRepository.onAuthStateChange.listen((authState) async {
      final session = authState.session;

      if (session == null) {
        // Sesión cerrada o expirada
        if (state.isAuthenticated) emit(const AuthState());
        return;
      }

      // Ya tenemos usuario cargado con ese mismo UUID → no volver a cargar
      if (state.isAuthenticated && state.usuario?.id == session.user.id) return;

      // Sesión activa pero el cubit está vacío (ej: reinicio de app) → cargar perfil
      await _cargarPerfilDesdeUuid(session.user.id);
    });
  }

  /// Carga el perfil del backend usando el UUID de Supabase Auth.
  Future<void> _cargarPerfilDesdeUuid(String uuid) async {
    try {
      final usuario = await _usuarioRepository.getPerfilPorUuid(uuid);
      if (usuario != null) {
        emit(state.copyWith(isAuthenticated: true, usuario: usuario));
      } else {
        // UUID en Auth pero sin perfil en el backend → limpiar
        emit(const AuthState());
      }
    } catch (_) {
      emit(const AuthState());
    }
  }

  /// Login con username. El email sintético se construye en el repositorio.
  Future<void> login(String username, String password) async {
    try {
      final usuario = await _usuarioRepository.loginUsuario(username, password);
      emit(state.copyWith(isAuthenticated: true, usuario: usuario));
    } catch (e) {
      // Re-emite el mismo estado limpio con el error para que la UI lo muestre
      emit(AuthState(error: _parseError(e)));
    }
  }

  /// Cierre de sesión completo.
  Future<void> logout() async {
    await _usuarioRepository.signOut();
    emit(const AuthState());
  }

  String _parseError(Object e) {
    // El fallo de red llega tipado desde el repositorio migrado.
    if (e is NetworkFailure) return e.message;
    // Para el resto se inspecciona el mensaje ya limpio (ServerFailure.message
    // o el texto de una validación de dominio), no un stacktrace.
    final raw = e is Failure ? e.message : e.toString();
    if (raw.contains('Invalid login credentials') ||
        raw.contains('invalid_credentials')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (raw.contains('no tiene un perfil operativo')) {
      return 'El usuario no tiene un rol asignado. Contacta al administrador.';
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}