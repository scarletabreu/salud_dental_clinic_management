class TratamientoAplicado {
  final String id;
  final String tratamientoId;
  final String? tratamientoPadreId;
  final bool esContinuo;
  final bool estaTerminado;

  TratamientoAplicado({
    required this.id,
    required this.tratamientoId,
    this.tratamientoPadreId,
    required this.esContinuo,
    required this.estaTerminado,
  });

  TratamientoAplicado copyWith({
    String? tratamientoId,
    String? tratamientoPadreId,
    bool? esContinuo,
    bool? estaTerminado,
  }) {
    return TratamientoAplicado(
      id: id,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      tratamientoPadreId: tratamientoPadreId ?? this.tratamientoPadreId,
      esContinuo: esContinuo ?? this.esContinuo,
      estaTerminado: estaTerminado ?? this.estaTerminado,
    );
  }
}
