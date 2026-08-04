class ExpedientePrintOptions {
  final bool incluirOdontograma;
  final bool incluirEvaluaciones;
  final bool incluirConsultas;
  final bool incluirTratamientos;
  final bool incluirRecetas;
  final bool incluirDocumentosReferenciados;

  const ExpedientePrintOptions({
    this.incluirOdontograma = true,
    this.incluirEvaluaciones = true,
    this.incluirConsultas = true,
    this.incluirTratamientos = true,
    this.incluirRecetas = true,
    this.incluirDocumentosReferenciados = true,
  });
}
