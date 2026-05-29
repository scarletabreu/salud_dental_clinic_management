import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UsuarioRepository {
  String? getCurrentUserId();
  bool isSessionActive();
  Future<void> signOut();
  Stream<AuthState> get onAuthStateChange;
  Future<Usuario> loginUsuario(String username,String password);
}
