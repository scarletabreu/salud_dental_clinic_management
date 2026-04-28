import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  @override
  String? getCurrentUserId() => remoteDataSource.getCurrentUserId();

  @override
  bool isSessionActive() => remoteDataSource.isSessionActive();

  @override
  Future<void> signOut() async => await remoteDataSource.signOut();

  @override
  Stream<AuthState> get onAuthStateChange => remoteDataSource.authStateChanges;
}
