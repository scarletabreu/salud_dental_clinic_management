import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

abstract interface class UsuarioRepository {
  Future<Usuario> loginUsuario(String username, String password);
  Future<Usuario?> getPerfilPorUuid(String uuid);
  Future<void> signOut();
  String? getCurrentUserId();
  bool isSessionActive();
  Future<List<Usuario>> getUsuarios();
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

  Future<void> eliminarUsuario({required String usuarioId});
}
