import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UsuarioRemoteDataSource {
  User? getCurrentSupabaseUser();
  String? getCurrentUserId();
  Future<void> signOut();
  bool isSessionActive();
  Stream<AuthState> get authStateChanges;
}
