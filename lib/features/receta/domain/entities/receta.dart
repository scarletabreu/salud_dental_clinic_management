class Receta {
  final String id;
  final String title;
  final DateTime createdAt;
  final String medicinaId;
  final String dosis;
  final String frecuencia;
  final String indicaciones;
  final String duracion;
  final String? notas;

  Receta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.medicinaId,
    required this.dosis,
    required this.frecuencia,
    required this.indicaciones,
    required this.duracion,
    this.notas,
  });

  Receta copyWith({
    String? title,
    DateTime? createdAt,
    String? medicinaId,
    String? dosis,
    String? frecuencia,
    String? indicaciones,
    String? duracion,
    String? notas,
  }) {
    return Receta(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      medicinaId: medicinaId ?? this.medicinaId,
      dosis: dosis ?? this.dosis,
      frecuencia: frecuencia ?? this.frecuencia,
      indicaciones: indicaciones ?? this.indicaciones,
      duracion: duracion ?? this.duracion,
      notas: notas ?? this.notas,
    );
  }

  factory Receta.fromJson(Map<String, dynamic> json) {
  return Receta(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    medicinaId: json['medicinaId'] as String,
    dosis: json['dosis'] as String,
    frecuencia: json['frecuencia'] as String,
    indicaciones: json['indicaciones'] as String,
    duracion: json['duracion'] as String,
    notas: json['notas'] as String?,
  );
}
}
