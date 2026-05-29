// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UsuarioRepository _usuarioRepository;

  AuthCubit({required UsuarioRepository usuarioRepository})
      : _usuarioRepository = usuarioRepository,
        super(AuthState.initial());

  /// Método para iniciar sesión usando el repositorio de Usuarios existente
  Future<void> login(String username, String password) async {
    try {
      // Tu UsuarioRepository debe encargarse de ir a Supabase, validar las credenciales,
      // revisar si el ID existe en las tablas hijas (Admin, Doctor, Asistente)
      // y retornar la instancia concreta (ej: AdminModel, DoctorModel) casteada como Usuario.
      final usuario = await _usuarioRepository.loginUsuario(username, password);

      emit(state.copyWith(
        isAuthenticated: true,
        usuario: usuario,
      ));
    } catch (e) {
      // Si falla, volvemos al estado inicial no autenticado
      emit(AuthState.initial());
    }
  }

  /// Restablecer el estado (Cerrar sesión)
  void logout() {
    emit(AuthState.initial());
  }
}