import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UsuarioRepository {
  String? getCurrentUserId();
  bool isSessionActive();
  Future<void> signOut();
  Stream<AuthState> get onAuthStateChange;
}
