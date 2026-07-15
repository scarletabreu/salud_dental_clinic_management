import 'package:salud_dental_clinic_management/core/errors/guard.dart';
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
  }) => runGuarded(
    () => _dataSource.signIn(email: email, password: password),
    context: 'iniciar sesión',
  );

  @override
  Future<void> signOut() =>
      runGuarded(() => _dataSource.signOut(), context: 'cerrar sesión');

  @override
  Stream<AuthUsuario?> get onAuthStateChange => _dataSource.onAuthStateChange;

  @override
  AuthUsuario? get currentUser => _dataSource.currentUser;
}
