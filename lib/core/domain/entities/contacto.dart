class Contacto {
  final String? id;
  final String email;
  final String numeroTelefono;
  final String direccion;

  Contacto({
    this.id,
    required this.email,
    required this.numeroTelefono,
    required this.direccion,
  });

  Contacto copyWith({
    String? telefono,
    String? email,
    String? direccion,
  }) {
    return Contacto(
      numeroTelefono: telefono ?? numeroTelefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion
    );
  }
}
