class ItemReceta {
  final String? id;
  final String? medicamentoId;
  final String nombreMedicamento;
  final String presentacionConcentracion;
  final String dosis;
  final String viaAdministracion;
  final String frecuencia;
  final String duracion;
  final String cantidadIndicada;
  final String? indicacionesEspecificas;

  const ItemReceta({
    this.id,
    this.medicamentoId,
    required this.nombreMedicamento,
    this.presentacionConcentracion = '',
    required this.dosis,
    this.viaAdministracion = 'vía oral',
    required this.frecuencia,
    required this.duracion,
    this.cantidadIndicada = '',
    this.indicacionesEspecificas,
  });

  ItemReceta copyWith({
    String? id,
    String? medicamentoId,
    String? nombreMedicamento,
    String? presentacionConcentracion,
    String? dosis,
    String? viaAdministracion,
    String? frecuencia,
    String? duracion,
    String? cantidadIndicada,
    String? indicacionesEspecificas,
  }) {
    return ItemReceta(
      id: id ?? this.id,
      medicamentoId: medicamentoId ?? this.medicamentoId,
      nombreMedicamento: nombreMedicamento ?? this.nombreMedicamento,
      presentacionConcentracion:
          presentacionConcentracion ?? this.presentacionConcentracion,
      dosis: dosis ?? this.dosis,
      viaAdministracion: viaAdministracion ?? this.viaAdministracion,
      frecuencia: frecuencia ?? this.frecuencia,
      duracion: duracion ?? this.duracion,
      cantidadIndicada: cantidadIndicada ?? this.cantidadIndicada,
      indicacionesEspecificas:
          indicacionesEspecificas ?? this.indicacionesEspecificas,
    );
  }
}
