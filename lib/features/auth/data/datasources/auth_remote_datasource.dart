import 'package:salud_dental_clinic_management/features/auth/domain/entities/auth_usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthUsuario> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Error de autenticación: usuario nulo tras el inicio de sesión.');
    }

    return AuthUsuario(
      id: user.id,
      email: user.email ?? email,
      accessToken: response.session?.accessToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthUsuario?> get onAuthStateChange {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return AuthUsuario(
        id: user.id,
        email: user.email ?? '',
        accessToken: data.session?.accessToken,
      );
    });
  }

  AuthUsuario? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUsuario(
      id: user.id,
      email: user.email ?? '',
      accessToken: _client.auth.currentSession?.accessToken,
    );
  }
}