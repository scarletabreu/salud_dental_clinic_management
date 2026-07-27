import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaModel extends Receta {
  RecetaModel({
    super.id,
    required super.title,
    required super.createdAt,
    required super.medicinaId,
    required super.dosis,
    required super.frecuencia,
    required super.indicaciones,
    required super.duracion,
    super.notas,
  });

  /// Lee una fila de `recetas` sin asumir que trae las columnas del formato
  /// antiguo (una medicina por fila).
  ///
  /// La tabla ya convive con el formato de SD-153: una receta es una cabecera
  /// con `codigo_receta` y sus medicinas dentro del jsonb `items_receta`, y
  /// entonces `titulo`, `dosis`, `medicina_id`, etc. quedan NULL por diseño.
  /// Con los casts no-nulos anteriores esas filas lanzaban `TypeError`, y como
  /// el parseo ocurre dentro del guard del repositorio, una sola receta así
  /// tumbaba el listado completo de consultas con un error sin detalle.
  factory RecetaModel.fromJson(Map<String, dynamic> json) {
    String texto(String clave, [String? alterna]) =>
        (json[clave] ?? (alterna != null ? json[alterna] : null)) as String? ??
        '';

    return RecetaModel(
      id: json['id'] as String?,
      // Sin `titulo`, el código de receta es el identificador que el doctor
      // reconoce; es preferible a una tarjeta sin encabezado.
      title: [
        texto('titulo', 'title'),
        texto('codigo_receta'),
      ].firstWhere((v) => v.isNotEmpty, orElse: () => ''),
      createdAt: _fecha(json['created_at'] ?? json['createdAt']),
      medicinaId: texto('medicina_id', 'medicinaId'),
      dosis: texto('dosis'),
      frecuencia: texto('frecuencia'),
      indicaciones: texto('indicaciones'),
      duracion: texto('duracion'),
      notas: json['notas'] as String?,
    );
  }

  static DateTime _fecha(dynamic valor) {
    final texto = valor as String?;
    if (texto == null) return DateTime.now();
    return DateTime.tryParse(texto)?.toLocal() ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'titulo': title,
      'created_at': createdAt.toIso8601String(),
      'medicina_id': medicinaId,
      'dosis': dosis,
      'frecuencia': frecuencia,
      'indicaciones': indicaciones,
      'notas': notas,
      'duracion': duracion,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory RecetaModel.fromEntity(Receta receta) {
    return RecetaModel(
      id: receta.id,
      title: receta.title,
      createdAt: receta.createdAt,
      medicinaId: receta.medicinaId,
      dosis: receta.dosis,
      frecuencia: receta.frecuencia,
      indicaciones: receta.indicaciones,
      duracion: receta.duracion,
      notas: receta.notas,
    );
  }
}
