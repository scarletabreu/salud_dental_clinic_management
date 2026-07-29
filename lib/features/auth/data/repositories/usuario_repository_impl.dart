import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  static const _selectPerfilCompleto =
      '*, usuarios(*, personas(*, persona_contactos(*, contactos(*))))';

    static const _selectPerfilAdmin =
      '*, doctores(*, usuarios(*, personas(*, persona_contactos(*, contactos(*)))))';

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
  Future<void> signOut() {
    return runGuarded(() => remoteDataSource.signOut(), context: 'cerrar sesión');
  }

  @override
  Future<Usuario> loginUsuario(String username, String password) async {
    final response = await runGuarded(
      () => remoteDataSource.signInWithPassword(
        email: '$username@saluddental.com',
        password: password,
      ),
      context: 'iniciar sesión',
    );
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
  }

  @override
  Future<Usuario?> getPerfilPorUuid(String uuid) {
    return runGuarded(() async {
      final adminData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'admins',
        uuid: uuid,
        selectColumns: _selectPerfilAdmin,
      );
      if (adminData != null) return AdminModel.fromJson(adminData);

      final doctorData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'doctores',
        uuid: uuid,
        selectColumns: _selectPerfilCompleto,
      );
      if (doctorData != null) return DoctorModel.fromJson(doctorData);



      final asistenteData = await remoteDataSource.getPerfilPorTabla(
        tabla: 'asistentes',
        uuid: uuid,
        selectColumns: _selectPerfilCompleto,
      );
      if (asistenteData != null) return AsistenteModel.fromJson(asistenteData);

      return null;
    }, context: 'cargar el perfil');
  }

  @override
  Future<List<Usuario>> getUsuarios() {
    return runGuarded(() async {
      final List<Usuario> usuariosConsolidados = [];

      final List<dynamic>? listDoctores = await remoteDataSource
          .getPerfilesPorTabla(
            tabla: 'doctores',
            selectColumns: _selectPerfilCompleto,
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
            selectColumns: _selectPerfilAdmin,
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
            selectColumns: _selectPerfilCompleto,
          );
      if (listAsistentes != null) {
        usuariosConsolidados.addAll(
          listAsistentes.map(
            (json) => AsistenteModel.fromJson(json as Map<String, dynamic>),
          ),
        );
      }

      return usuariosConsolidados;
    }, context: 'consolidar el listado de perfiles');
  }

  @override
  Future<Usuario> crearUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required DateTime birthDate,
    required String govID,
    required String username,
    required String telefono,
    required RolUsuario rol,
    String? especialidad,
    String? departamento,
    String? turno,
  }) async {
    final uuid = await runGuarded(
      () => remoteDataSource.crearUsuarioCompleto({
        'email': email,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
        'fecha_nacimiento': birthDate.toIso8601String(),
        'cedula': govID,
        'contactos': [
          {'numero_telefono': telefono},
        ],
        'username': username,
        'rol': rol.name,
        'especialidad': especialidad,
        'departamento': departamento,
        'turno': turno,
      }),
      context: 'crear el usuario',
    );

    final perfil = await getPerfilPorUuid(uuid);
    if (perfil == null) {
      throw Exception('Usuario creado pero no se pudo cargar el perfil.');
    }
    return perfil;
  }

  @override
  Future<void> actualizarUsuario({
    required String usuarioId,
    required String nombre,
    required String apellido,
    required DateTime birthDate,
    required String govID,
    required String telefono,
  }) {
    return runGuarded(() async {
      await remoteDataSource.actualizarPersona(usuarioId, {
        'nombre': nombre,
        'apellido': apellido,
        'fecha_nacimiento': birthDate.toIso8601String(),
        'cedula': govID,
      });
      await remoteDataSource.actualizarTelefonoPersona(
        personaId: usuarioId,
        telefono: telefono,
      );
    }, context: 'actualizar el usuario');
  }

  @override
  Future<void> resetearPassword({
    required String usuarioId,
    required String nuevaPassword,
  }) {
    return runGuarded(
      () => remoteDataSource.resetearPassword(
        targetUuid: usuarioId,
        nuevaPassword: nuevaPassword,
      ),
      context: 'restablecer la contraseña',
    );
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      remoteDataSource.authStateChanges;
}
