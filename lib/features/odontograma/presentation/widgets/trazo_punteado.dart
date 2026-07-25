import 'dart:ui';

/// Contornos discontinuos para el odontograma.
///
/// El trazo punteado es lo que distingue una marca planificada de una ya hecha
/// sin depender del color: sobrevive a la impresión en gris y a quien no separa
/// bien los tonos. Canvas no sabe dibujar líneas discontinuas, así que el borde
/// se recorre a mano en tramos.
const double _tramo = 3;
const double _hueco = 2.6;

/// Un segmento discontinuo entre dos puntos.
void dibujarLineaPunteada(
  Canvas canvas,
  Offset desde,
  Offset hasta,
  Paint paint, {
  double tramo = _tramo,
  double hueco = _hueco,
}) {
  final total = (hasta - desde).distance;
  if (total <= 0) return;
  final direccion = (hasta - desde) / total;
  var recorrido = 0.0;
  while (recorrido < total) {
    final fin = (recorrido + tramo).clamp(0.0, total);
    canvas.drawLine(
      desde + direccion * recorrido,
      desde + direccion * fin,
      paint,
    );
    recorrido = fin + hueco;
  }
}

/// El contorno discontinuo de un polígono cerrado.
void dibujarPoligonoPunteado(
  Canvas canvas,
  List<Offset> poligono,
  Paint paint, {
  double tramo = _tramo,
  double hueco = _hueco,
}) {
  for (var i = 0; i < poligono.length; i++) {
    dibujarLineaPunteada(
      canvas,
      poligono[i],
      poligono[(i + 1) % poligono.length],
      paint,
      tramo: tramo,
      hueco: hueco,
    );
  }
}

/// El contorno discontinuo de un rectángulo.
void dibujarRectanguloPunteado(
  Canvas canvas,
  Rect rect,
  Paint paint, {
  double tramo = _tramo,
  double hueco = _hueco,
}) => dibujarPoligonoPunteado(
  canvas,
  [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft],
  paint,
  tramo: tramo,
  hueco: hueco,
);

/// El contorno discontinuo de un trazado cualquiera, como la silueta de un
/// diente. Se recorre con [PathMetrics] porque el perfil es curvo y no se deja
/// aproximar por segmentos rectos sin perder la forma.
void dibujarContornoPunteado(
  Canvas canvas,
  Path path,
  Paint paint, {
  double tramo = _tramo,
  double hueco = _hueco,
}) {
  for (final metrica in path.computeMetrics()) {
    var recorrido = 0.0;
    while (recorrido < metrica.length) {
      final fin = (recorrido + tramo).clamp(0.0, metrica.length);
      canvas.drawPath(metrica.extractPath(recorrido, fin), paint);
      recorrido = fin + hueco;
    }
  }
}
