import 'package:salud_dental_clinic_management/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/auth_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUsuario> signIn({
    required String email,
    required String password,
  }) => _dataSource.signIn(email: email, password: password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Stream<AuthUsuario?> get onAuthStateChange => _dataSource.onAuthStateChange;

  @override
  AuthUsuario? get currentUser => _dataSource.currentUser;
}