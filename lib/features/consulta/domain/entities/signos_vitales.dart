class SignosVitales {
  final int? presionSistolica;
  final int? presionDiastolica;
  final int? pulso;
  final double? temperatura;
  final int? saturacionO2;

  const SignosVitales({
    this.presionSistolica,
    this.presionDiastolica,
    this.pulso,
    this.temperatura,
    this.saturacionO2,
  });

  bool get estaVacia =>
      presionSistolica == null &&
      presionDiastolica == null &&
      pulso == null &&
      temperatura == null &&
      saturacionO2 == null;

  factory SignosVitales.fromJson(Map<String, dynamic> json) => SignosVitales(
    presionSistolica: json['presion_sistolica'] as int?,
    presionDiastolica: json['presion_diastolica'] as int?,
    pulso: json['pulso'] as int?,
    temperatura: (json['temperatura'] as num?)?.toDouble(),
    saturacionO2: json['saturacion_o2'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'presion_sistolica': presionSistolica,
    'presion_diastolica': presionDiastolica,
    'pulso': pulso,
    'temperatura': temperatura,
    'saturacion_o2': saturacionO2,
  };
}
