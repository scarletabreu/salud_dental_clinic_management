// lib/features/auth/data/repositories/usuario_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';

// Importaciones de tus modelos específicos de personal para el mapeo polimórfico
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  @override
  String? getCurrentUserId() {
    try {
      return remoteDataSource.getCurrentUserId();
    } catch (e) {
      return null;
    }
  }

  @override
  bool isSessionActive() {
    try {
      return remoteDataSource.isSessionActive();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<Usuario> loginUsuario(String username, String password) async {
    try {
      // 1. Delegamos la autenticación base al DataSource
      final response = await remoteDataSource.signInWithPassword(
        email: '$username@saluddental.com',
        password: password,
      );

      final userUuid = response.user?.id;
      if (userUuid == null) {
        throw Exception('Usuario no encontrado en la autenticación.');
      }

      // 2. BUSQUEDA EN CASCADA (Polimorfismo en DB)
      // Delegamos los queries de infraestructura al remoteDataSource usando su supabaseClient interno

      // ¿Es un Doctor / Odontólogo?
      final doctorData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'doctores',
        uuid: userUuid,
        selectColumns: '*, asistentes(*)',
      );

      if (doctorData != null) {
        return DoctorModel.fromJson(doctorData);
      }

      // ¿Es un Administrador?
      final adminData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'administradores',
        uuid: userUuid,
      );

      if (adminData != null) {
        return AdminModel.fromJson(adminData);
      }

      // ¿Es un Asistente?
      final asistenteData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'asistentes',
        uuid: userUuid,
      );

      if (asistenteData != null) {
        return AsistenteModel.fromJson(asistenteData);
      }

      // Failsafe corporativo
      throw Exception('El usuario autenticado no tiene un perfil operativo asignado.');
    } catch (e) {
      throw Exception('Error de inicio de sesión: ${e.toString()}');
    }
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange => remoteDataSource.authStateChanges;
}