class TipoContraindicacion {
  final String key;
  final String label;

  const TipoContraindicacion({
    required this.key,
    required this.label,
  });

  String get name => label;

  static const absoluta = TipoContraindicacion(key: 'absoluta', label: 'Absoluta');
  static const relativa = TipoContraindicacion(key: 'relativa', label: 'Relativa');

  static const List<TipoContraindicacion> values = [absoluta, relativa];

  static TipoContraindicacion fromKey(String key, {TipoContraindicacion? orElse}) {
    return values.firstWhere(
      (v) => v.key == key,
      orElse: () => orElse ?? relativa,
    );
  } 

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoContraindicacion && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}