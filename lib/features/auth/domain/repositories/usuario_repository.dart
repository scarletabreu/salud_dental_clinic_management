import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/features/auth/domain/entities/listado_perfiles.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

abstract interface class UsuarioRepository {
  Future<Usuario> loginUsuario(String username, String password);
  Future<Usuario?> getPerfilPorUuid(String uuid);
  Future<void> signOut();
  String? getCurrentUserId();
  bool isSessionActive();
  /// Consolida doctores, admins y asistentes en un solo listado.
  ///
  /// No lanza por un fallo parcial: si una de las tres lecturas o una fila
  /// suelta se cae, lo que sí cargó se devuelve igual y lo que falló viaja
  /// como [AvisoPerfil]. La pantalla de Perfiles debe seguir siendo usable
  /// aunque un registro esté corrupto.
  Future<ListadoPerfiles> getUsuarios();
  Stream<supabase.AuthState> get onAuthStateChange;

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
  });

  Future<void> actualizarUsuario({
    required String usuarioId,
    required String nombre,
    required String apellido,
    required DateTime birthDate,
    required String govID,
    required String telefono,
  });

  Future<void> resetearPassword({
    required String usuarioId,
    required String nuevaPassword,
  });

  Future<String?> desactivarUsuario({
    required String usuarioId,
    required RolUsuario rol,
  });

  Future<List<Usuario>> getAsistentesDisponibles();

  Future<List<String>> getAsistentesAsignadosIds(String doctorId);

  Future<void> asignarAsistentes({
    required String doctorId,
    required List<String> asistenteIds,
  });
}