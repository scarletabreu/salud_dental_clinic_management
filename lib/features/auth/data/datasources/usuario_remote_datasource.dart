import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UsuarioRemoteDataSource {
  User? getCurrentSupabaseUser();
  String? getCurrentUserId();
  Future<void> signOut();
  bool isSessionActive();
  Stream<AuthState> get authStateChanges;
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
  Future<List<dynamic>?> getPerfilesPorTabla({
    required String tabla,
    required String selectColumns,
  });

  Future<Map<String, dynamic>?> getPerfilPorTabla({
    required String tabla,
    required String uuid,
    String selectColumns = '*',
  });
  Future<String> crearUsuarioCompleto(Map<String, dynamic> payload);
  Future<void> resetearPassword({
    required String targetUuid,
    required String nuevaPassword,
  });
  Future<void> actualizarPersona(String personaId, Map<String, dynamic> data);
  Future<void> actualizarUsuarioBasico(
    String usuarioId,
    Map<String, dynamic> data,
  );
}
