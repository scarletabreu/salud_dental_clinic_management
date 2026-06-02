import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UsuarioRemoteDataSource {
  User? getCurrentSupabaseUser();
  String? getCurrentUserId();
  Future<void> signOut();
  bool isSessionActive();
  Stream<AuthState> get authStateChanges;
  Future<AuthResponse> signInWithPassword({required String email, required String password});

  Future<Map<String, dynamic>?> getPerfilPorTabla({
    required String tabla, 
    required String uuid, 
    String selectColumns = '*',
  });

}
