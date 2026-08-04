class Contacto {
  final String? id;
  final String email;
  final String numeroTelefono;
  final String direccion;
  final bool esEmergencia;

  Contacto({
    this.id,
    required this.email,
    required this.numeroTelefono,
    required this.direccion,
    this.esEmergencia = false,
  });

  Contacto copyWith({
    String? id,
    String? telefono,
    String? email,
    String? direccion,
    bool? esEmergencia,
  }) {
    return Contacto(
      id: id ?? this.id,
      numeroTelefono: telefono ?? numeroTelefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      esEmergencia: esEmergencia ?? this.esEmergencia,
    );
  }
}
