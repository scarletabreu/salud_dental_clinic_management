// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
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

      // Al renovarse el token (~1 h) el perfil se recarga aunque el UUID sea
      // el mismo (MU-5): un rol quitado o un usuario desactivado deja de
      // operar en el siguiente refresh, sin publicar `usuarios` por realtime
      // (sus grants de columna no conviven con las filas completas que
      // entrega postgres_changes).
      final esRefreshDeToken =
          authState.event == AuthChangeEvent.tokenRefreshed;

      // Ya tenemos usuario cargado con ese mismo UUID → no volver a cargar
      if (!esRefreshDeToken &&
          state.isAuthenticated &&
          state.usuario?.id == session.user.id) {
        return;
      }

      // Sesión activa pero el cubit está vacío (ej: reinicio de app) → cargar perfil
      await _cargarPerfilDesdeUuid(
        session.user.id,
        // Un fallo transitorio de red durante el refresh no puede cerrar la
        // sesión: se conserva el perfil vigente y el próximo refresh reintenta.
        conservarSesionSiFalla: esRefreshDeToken,
      );
    });
  }

  /// Carga el perfil del backend usando el UUID de Supabase Auth.
  Future<void> _cargarPerfilDesdeUuid(
    String uuid, {
    bool conservarSesionSiFalla = false,
  }) async {
    try {
      final usuario = await _usuarioRepository.getPerfilPorUuid(uuid);
      if (usuario != null) {
        emit(state.copyWith(isAuthenticated: true, usuario: usuario));
      } else {
        // UUID en Auth pero sin perfil en el backend → limpiar. Esto incluye
        // al usuario desactivado: el perfil operativo deja de resolver.
        emit(const AuthState());
      }
    } catch (_) {
      if (conservarSesionSiFalla && state.isAuthenticated) return;
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