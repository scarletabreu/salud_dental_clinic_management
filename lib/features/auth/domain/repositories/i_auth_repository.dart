import 'package:salud_dental_clinic_management/features/auth/domain/entities/auth_usuario.dart';

abstract interface class IAuthRepository {
  Future<AuthUsuario> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AuthUsuario?> get onAuthStateChange;
  AuthUsuario? get currentUser;
}