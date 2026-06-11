import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

abstract interface class UsuarioRepository {
  /// Login por username. El email sintético (username@saluddental.com)
  /// se construye internamente en la implementación.
  Future<Usuario> loginUsuario(String username, String password);

  /// Carga el perfil del backend dado un UUID de Supabase Auth.
  /// Retorna null si el UUID existe en Auth pero no tiene perfil en el backend.
  Future<Usuario?> getPerfilPorUuid(String uuid);

  Future<void> signOut();
  String? getCurrentUserId();
  bool isSessionActive();
  Future<List<Usuario>> getUsuarios();

  Stream<supabase.AuthState> get onAuthStateChange;
}
