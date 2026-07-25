/// Identidades que la base asignó durante el guardado clínico.
///
/// Sellarlas en memoria evita que el siguiente autoguardado vuelva a insertar
/// una misma marca dental con otro id.
class ResultadoGuardadoOdontograma {
  final Map<int, List<String>> tratamientosPorFdi;
  final Map<int, List<String>> diagnosticosPorFdi;

  const ResultadoGuardadoOdontograma({
    this.tratamientosPorFdi = const {},
    this.diagnosticosPorFdi = const {},
  });

  bool get isEmpty => tratamientosPorFdi.isEmpty && diagnosticosPorFdi.isEmpty;
}
