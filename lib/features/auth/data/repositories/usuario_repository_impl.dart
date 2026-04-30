import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  @override
  String? getCurrentUserId() {
    try {
      return remoteDataSource.getCurrentUserId();
    } catch (e) {
      return null;
    }
  }

  @override
  bool isSessionActive() {
    try {
      return remoteDataSource.isSessionActive();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Stream<AuthState> get onAuthStateChange => remoteDataSource.authStateChanges;
}
