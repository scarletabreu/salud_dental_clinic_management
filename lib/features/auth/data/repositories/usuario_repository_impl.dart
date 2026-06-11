// lib/features/auth/data/repositories/usuario_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
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
    } catch (_) {
      return null;
    }
  }

  @override
  bool isSessionActive() {
    try {
      return remoteDataSource.isSessionActive();
    } catch (_) {
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
      print('>>> intentando login con: $username@saluddental.com');
      final response = await remoteDataSource.signInWithPassword(
        email: '$username@saluddental.com',
        password: password,
      );
      print('>>> login ok, uuid: ${response.user?.id}');
      final userUuid = response.user?.id;
      if (userUuid == null) {
        throw Exception('Usuario no encontrado en la autenticación.');
      }

      final perfil = await getPerfilPorUuid(userUuid);
      if (perfil == null) {
        throw Exception(
          'El usuario autenticado no tiene un perfil operativo asignado.',
        );
      }
      return perfil;
    } catch (e) {
      print('>>> ERROR login: $e');
      rethrow;
    }
  }

  /// Búsqueda en cascada por UUID. Mismo orden que antes.
  @override
  Future<Usuario?> getPerfilPorUuid(String uuid) async {
    final doctorData = await remoteDataSource.getPerfilPorTabla(
      tabla: 'doctores',
      uuid: uuid,
      selectColumns: '*, usuarios(*, personas(*))',
    );
    if (doctorData != null) return DoctorModel.fromJson(doctorData);

    final adminData = await remoteDataSource.getPerfilPorTabla(
      tabla: 'admins',
      uuid: uuid,
      selectColumns: '*, usuarios(*, personas(*))',
    );
    if (adminData != null) return AdminModel.fromJson(adminData);

    final asistenteData = await remoteDataSource.getPerfilPorTabla(
      tabla: 'asistentes',
      uuid: uuid,
      selectColumns: '*, usuarios(*, personas(*))',
    );
    if (asistenteData != null) return AsistenteModel.fromJson(asistenteData);

    return null;
  }

  @override
  Future<List<Usuario>> getUsuarios() async {
    final List<Usuario> usuariosConsolidados = [];

    try {
      final List<dynamic>? listDoctores = await remoteDataSource
          .getPerfilesPorTabla(
            tabla: 'doctores',
            selectColumns: '*, usuarios(*, personas(*))',
          );
      if (listDoctores != null) {
        usuariosConsolidados.addAll(
          listDoctores.map(
            (json) => DoctorModel.fromJson(json as Map<String, dynamic>),
          ),
        );
      }

      final List<dynamic>? listAdmins = await remoteDataSource
          .getPerfilesPorTabla(
            tabla: 'admins',
            selectColumns: '*, usuarios(*, personas(*))',
          );
      if (listAdmins != null) {
        usuariosConsolidados.addAll(
          listAdmins.map(
            (json) => AdminModel.fromJson(json as Map<String, dynamic>),
          ),
        );
      }

      final List<dynamic>? listAsistentes = await remoteDataSource
          .getPerfilesPorTabla(
            tabla: 'asistentes',
            selectColumns: '*, usuarios(*, personas(*))',
          );
      if (listAsistentes != null) {
        usuariosConsolidados.addAll(
          listAsistentes.map(
            (json) => AsistenteModel.fromJson(json as Map<String, dynamic>),
          ),
        );
      }

      return usuariosConsolidados;
    } catch (e) {
      throw Exception('Error al consolidar el listado de perfiles: $e');
    }
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      remoteDataSource.authStateChanges;
}
