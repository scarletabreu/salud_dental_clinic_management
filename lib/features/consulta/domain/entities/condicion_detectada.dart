import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

/// Condición de catálogo descubierta durante la consulta (HFX-CLIN-003).
///
/// Antes esto era una línea de texto libre en `temp_condiciones`: quedaba
/// escrita y no participaba en nada. Ahora apunta al catálogo, y por eso entra
/// de inmediato en las contraindicaciones y en el motor de alertas, sin esperar
/// a que alguien la copie al expediente. El texto libre sigue existiendo como
/// complemento, no como única representación.
class CondicionDetectada {
  final String? id;
  final String condicionId;

  /// Poblada cuando la lista viene del catálogo; sirve para pintar el nombre
  /// sin volver a consultarlo.
  final Condicion? condicion;

  final SeveridadCondicion severidad;
  final String? notas;
  final DateTime detectadaEn;

  /// El doctor confirma que pasa a formar parte del historial permanente. Sin
  /// esta confirmación la condición vale para hoy, pero no se escribe en el
  /// expediente al cerrar.
  final bool incorporarAlExpediente;

  CondicionDetectada({
    this.id,
    required this.condicionId,
    this.condicion,
    this.severidad = SeveridadCondicion.moderada,
    this.notas,
    DateTime? detectadaEn,
    this.incorporarAlExpediente = false,
  }) : detectadaEn = detectadaEn ?? DateTime.now();

  String get nombre => condicion?.nombre ?? 'Condición';

  CondicionDetectada copyWith({
    String? id,
    Condicion? condicion,
    SeveridadCondicion? severidad,
    String? notas,
    bool? incorporarAlExpediente,
  }) => CondicionDetectada(
    id: id ?? this.id,
    condicionId: condicionId,
    condicion: condicion ?? this.condicion,
    severidad: severidad ?? this.severidad,
    notas: notas ?? this.notas,
    detectadaEn: detectadaEn,
    incorporarAlExpediente:
        incorporarAlExpediente ?? this.incorporarAlExpediente,
  );

  Map<String, dynamic> toPayload() => {
    if (id != null) 'id': id,
    'condicion_id': condicionId,
    'severidad': severidad.dbValue,
    if (notas != null && notas!.trim().isNotEmpty) 'notas': notas!.trim(),
    'detectada_en': detectadaEn.toUtc().toIso8601String(),
    'incorporar_al_expediente': incorporarAlExpediente,
  };

  factory CondicionDetectada.fromJson(
    Map<String, dynamic> json, {
    Condicion? condicion,
  }) => CondicionDetectada(
    id: json['id'] as String?,
    condicionId: json['condicion_id'] as String? ?? '',
    condicion: condicion,
    severidad: SeveridadCondicion.porValor(json['severidad'] as String?),
    notas: json['notas'] as String?,
    detectadaEn:
        DateTime.tryParse(json['detectada_en'] as String? ?? '') ??
        DateTime.now(),
    incorporarAlExpediente:
        (json['incorporar_al_expediente'] as bool?) ?? false,
  );
}

enum SeveridadCondicion {
  leve('leve', 'Leve'),
  moderada('moderada', 'Moderada'),
  severa('severa', 'Severa');

  const SeveridadCondicion(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static SeveridadCondicion porValor(String? valor) => SeveridadCondicion.values
      .firstWhere((s) => s.dbValue == valor, orElse: () => moderada);
}
