import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/listado_perfiles.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/data/models/perfil_actual_mapper.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  // `usuarios` tiene grants por columna (todo menos password_hash): un `*`
  // sobre esa tabla falla con «permission denied», así que se piden columnas.
  static const _columnasUsuario =
      'id, username, last_login, created_at, deleted_at, updated_at';

  static const _selectPerfilCompleto =
      '*, usuarios($_columnasUsuario, personas(*, persona_contactos(*, contactos(*))))';

  // La pista de restricción no es opcional. Desde HFX-CLIN-001 existe
  // `auditoria_correcciones_clinicas`, con FK a `doctores` y a `admins`:
  // PostgREST la infiere como tabla puente y aparece un segundo camino
  // `admins ↔ doctores`, así que un `doctores(...)` a secas responde «more
  // than one relationship was found» (defecto D2). Nombrando la restricción se
  // elige el camino directo. La clave del JSON sigue siendo `doctores`, de modo
  // que `AdminModel.fromJson` no cambia.
  static const _selectPerfilAdmin =
      '*, doctores!admins_id_doctores_fkey('
      '*, usuarios($_columnasUsuario, personas(*, persona_contactos(*, contactos(*)))))';

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

  /// El perfil de la sesión sale de un único contrato del servidor.
  ///
  /// El encadenado anterior de PostgREST (`admins` -> `doctores` -> `usuarios`
  /// -> `personas`) dependía de una relación que no existía en toda base, y su
  /// ausencia se manifestaba como una sesión que caía justo después de
  /// autenticar. `uuid` se conserva en la firma por compatibilidad, pero quien
  /// manda es `auth.uid()`: nadie puede pedir el perfil de otro.
  @override
  Future<Usuario?> getPerfilPorUuid(String uuid) {
    return runGuarded(() async {
      final fila = await remoteDataSource.getPerfilActual();
      if (fila == null) return null;
      return PerfilActualMapper.desdeFila(fila);
    }, context: 'cargar el perfil');
  }

  /// Perfil de **otro** usuario, para el listado y para releer un alta recién
  /// hecha. Va por la relación de PostgREST, que HFX-CLIN-000 garantiza al
  /// crear la FK `admins.id -> doctores.id`.
  Future<Usuario?> _perfilDeOtroUsuario(String uuid) async {
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
  }

  /// Las tres lecturas van por separado y **cada fila se deserializa aparte**.
  ///
  /// Antes las tres compartían un solo `runGuarded` y un solo `map`: bastaba
  /// que fallara una lectura, o que una sola fila viniera incompleta, para que
  /// la pantalla entera quedara en error y no se pudiera administrar a nadie
  /// (defecto D2). Ahora lo que falla se convierte en un aviso y el resto del
  /// personal se sigue listando.
  @override
  Future<ListadoPerfiles> getUsuarios() async {
    final perfiles = <Usuario>[];
    final avisos = <AvisoPerfil>[];

    await _cargarRol<DoctorModel>(
      tabla: 'doctores',
      rol: RolUsuario.doctor,
      selectColumns: _selectPerfilCompleto,
      desdeJson: DoctorModel.fromJson,
      perfiles: perfiles,
      avisos: avisos,
    );

    await _cargarRol<AdminModel>(
      tabla: 'admins',
      rol: RolUsuario.admin,
      selectColumns: _selectPerfilAdmin,
      desdeJson: AdminModel.fromJson,
      perfiles: perfiles,
      avisos: avisos,
    );

    await _cargarRol<AsistenteModel>(
      tabla: 'asistentes',
      rol: RolUsuario.asistente,
      selectColumns: _selectPerfilCompleto,
      desdeJson: AsistenteModel.fromJson,
      perfiles: perfiles,
      avisos: avisos,
    );

    return ListadoPerfiles(perfiles: perfiles, avisos: avisos);
  }

  Future<void> _cargarRol<T extends Usuario>({
    required String tabla,
    required RolUsuario rol,
    required String selectColumns,
    required T Function(Map<String, dynamic>) desdeJson,
    required List<Usuario> perfiles,
    required List<AvisoPerfil> avisos,
  }) async {
    final List<dynamic>? filas;
    try {
      filas = await runGuarded(
        () => remoteDataSource.getPerfilesPorTabla(
          tabla: tabla,
          selectColumns: selectColumns,
        ),
        context: 'cargar los perfiles de $tabla',
      );
    } catch (e) {
      avisos.add(
        AvisoPerfil(
          titulo: 'No se pudo cargar el personal de tipo ${rol.name}',
          detalle: e.toString(),
          rol: rol,
          esSeccionCompleta: true,
        ),
      );
      return;
    }

    if (filas == null) return;

    for (final fila in filas) {
      final mapa = fila is Map ? Map<String, dynamic>.from(fila) : null;
      try {
        if (mapa == null) throw const FormatException('La fila no es un objeto');
        _exigirPersona(mapa, rol);
        perfiles.add(desdeJson(mapa));
      } catch (e) {
        avisos.add(
          AvisoPerfil(
            id: mapa?['id'] as String?,
            titulo: _tituloDeFila(mapa, rol),
            detalle: e.toString(),
            rol: rol,
          ),
        );
      }
    }
  }

  /// Los mappers de perfil son deliberadamente tolerantes: rellenan con valores
  /// por defecto lo que falte, porque otros caminos (el perfil de la sesión,
  /// la relectura tras un alta) prefieren un objeto incompleto a una excepción.
  ///
  /// En un **listado** esa tolerancia miente: una fila sin `personas` se pinta
  /// como una persona llamada «nombre apellido» nacida hoy. Un administrador no
  /// puede distinguir eso de un registro real mal escrito. Aquí se exige lo
  /// mínimo para que la fila represente a alguien; lo que no lo cumpla acaba
  /// como aviso, que es lo honesto.
  static void _exigirPersona(Map<String, dynamic> mapa, RolUsuario rol) {
    final persona = (mapa['usuarios'] as Map?)?['personas'] as Map?;
    final nombre = persona?['nombre'];
    if (nombre is! String || nombre.trim().isEmpty) {
      throw const FormatException(
        'El perfil no tiene datos de persona asociados.',
      );
    }
  }

  /// Lo más reconocible que se pueda rescatar de una fila que no deserializó.
  static String _tituloDeFila(Map<String, dynamic>? mapa, RolUsuario rol) {
    final persona = (mapa?['usuarios'] as Map?)?['personas'] as Map?;
    final nombre = [persona?['nombre'], persona?['apellido']]
        .whereType<String>()
        .join(' ')
        .trim();
    if (nombre.isNotEmpty) return nombre;

    final username = (mapa?['usuarios'] as Map?)?['username'] as String?;
    if (username != null && username.isNotEmpty) return username;

    final id = mapa?['id'] as String?;
    final abreviado = id != null && id.length >= 8 ? id.substring(0, 8) : id;
    return abreviado != null ? '${rol.name} #$abreviado' : 'Perfil sin datos';
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

    // Ojo: el perfil que se relee es el del usuario recién creado, no el de la
    // sesión que lo creó. `getPerfilPorUuid` resuelve siempre `auth.uid()`.
    final perfil = await runGuarded(
      () => _perfilDeOtroUsuario(uuid),
      context: 'cargar el perfil del usuario creado',
    );
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
  Future<String?> desactivarUsuario({
    required String usuarioId,
    required RolUsuario rol,
  }) {
    return runGuarded(() async {
      if (rol == RolUsuario.admin) {
        return 'Los administradores no pueden desactivarse desde esta pantalla.';
      }

      final citasPendientes = await remoteDataSource.contarCitasPendientes(
        usuarioId,
      );
      if (citasPendientes > 0) {
        return 'Tiene $citasPendientes cita${citasPendientes == 1 ? '' : 's'} '
            'pendiente${citasPendientes == 1 ? '' : 's'} como doctor asignado. '
            'Debe finalizarlas o cancelarlas antes de desactivar.';
      }

      final consultasPendientes = await remoteDataSource
          .contarConsultasPendientes(usuarioId);
      if (consultasPendientes > 0) {
        return 'Tiene $consultasPendientes consulta${consultasPendientes == 1 ? '' : 's'} '
            'sin finalizar. Debe completarlas antes de desactivar.';
      }

      await remoteDataSource.desactivarUsuarioRemoto(usuarioId);
      return null;
    }, context: 'desactivar el usuario');
  }

  @override
  Future<List<Usuario>> getAsistentesDisponibles() {
    return runGuarded(() async {
      final list = await remoteDataSource.getTodosAsistentes();
      if (list == null) return [];
      return list
          .map((json) => AsistenteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }, context: 'cargar la lista de asistentes');
  }

  @override
  Future<List<String>> getAsistentesAsignadosIds(String doctorId) {
    return runGuarded(
      () => remoteDataSource.getAsistenteIdsAsignados(doctorId),
      context: 'cargar los asistentes asignados',
    );
  }

  @override
  Future<void> asignarAsistentes({
    required String doctorId,
    required List<String> asistenteIds,
  }) {
    return runGuarded(
      () => remoteDataSource.reemplazarAsistentesDoctor(
        doctorId,
        asistenteIds,
      ),
      context: 'asignar los asistentes',
    );
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      remoteDataSource.authStateChanges;
}