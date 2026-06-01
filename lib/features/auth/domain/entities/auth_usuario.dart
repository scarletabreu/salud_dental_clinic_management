class AuthUsuario {
  final String id;
  final String email;
  final String? accessToken;

  const AuthUsuario({
    required this.id,
    required this.email,
    this.accessToken,
  });
}