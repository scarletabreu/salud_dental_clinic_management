import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Fracción del lado en la que empieza el recuadro central del glifo. Es la
/// proporción del dibujo impreso: un marco de caras axiales alrededor de la
/// cara oclusal.
const double _a = 0.30;
const double _b = 1 - _a;

/// Geometría del glifo de una pieza: el cuadrado con recuadro interior de la
/// dentición permanente o el círculo con núcleo de la temporal, subdividido en
/// las cinco superficies que se anotan en el papel.
class GlifoPieza {
  final int fdi;
  final bool temporal;
  final bool superior;

  /// La línea media queda a la derecha del glifo, así que la cara mesial
  /// también. Depende del hemicampo en el que se dibuje la pieza.
  final bool mesialALaDerecha;

  const GlifoPieza({
    required this.fdi,
    required this.temporal,
    required this.superior,
    required this.mesialALaDerecha,
  });

  TipoSuperficie get _central => superficieCentral(fdi);
  TipoSuperficie get _lingual => superficieLingual(superior);

  /// Superficie de la banda superior del dibujo. En el maxilar la cara
  /// vestibular mira hacia fuera de la arcada, es decir hacia arriba del papel;
  /// en la mandíbula pasa lo contrario.
  TipoSuperficie get _arriba => superior ? TipoSuperficie.vestibular : _lingual;
  TipoSuperficie get _abajo => superior ? _lingual : TipoSuperficie.vestibular;
  TipoSuperficie get _izquierda =>
      mesialALaDerecha ? TipoSuperficie.distal : TipoSuperficie.mesial;
  TipoSuperficie get _derecha =>
      mesialALaDerecha ? TipoSuperficie.mesial : TipoSuperficie.distal;

  /// Las cinco superficies del glifo, en orden de dibujo.
  List<TipoSuperficie> get superficies => [
    _arriba,
    _abajo,
    _izquierda,
    _derecha,
    _central,
  ];

  /// Superficie bajo un punto local, para que un toque sobre el glifo anote
  /// exactamente la cara que el doctor señaló.
  TipoSuperficie? superficieEn(Offset punto, double lado) {
    if (lado <= 0) return null;
    final x = punto.dx / lado;
    final y = punto.dy / lado;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    if (x >= _a && x <= _b && y >= _a && y <= _b) return _central;
    if (y < x && y < 1 - x) return _arriba;
    if (y > x && y > 1 - x) return _abajo;
    if (x < y && x < 1 - y) return _izquierda;
    return _derecha;
  }

  Path contornoExterior(double lado) {
    final rect = Rect.fromLTWH(0, 0, lado, lado);
    return temporal ? (Path()..addOval(rect)) : (Path()..addRect(rect));
  }

  Path contornoInterior(double lado) {
    final rect = Rect.fromLTWH(
      _a * lado,
      _a * lado,
      (_b - _a) * lado,
      (_b - _a) * lado,
    );
    return temporal ? (Path()..addOval(rect)) : (Path()..addRect(rect));
  }

  /// Recorte de cada superficie, ya ajustado al contorno del glifo.
  Map<TipoSuperficie, Path> regiones(double lado) {
    final exterior = contornoExterior(lado);
    final interior = contornoInterior(lado);
    double p(double v) => v * lado;

    final poligonos = <TipoSuperficie, List<Offset>>{
      _arriba: [
        Offset.zero,
        Offset(p(1), 0),
        Offset(p(_b), p(_a)),
        Offset(p(_a), p(_a)),
      ],
      _abajo: [
        Offset(0, p(1)),
        Offset(p(1), p(1)),
        Offset(p(_b), p(_b)),
        Offset(p(_a), p(_b)),
      ],
      _izquierda: [
        Offset.zero,
        Offset(p(_a), p(_a)),
        Offset(p(_a), p(_b)),
        Offset(0, p(1)),
      ],
      _derecha: [
        Offset(p(1), 0),
        Offset(p(_b), p(_a)),
        Offset(p(_b), p(_b)),
        Offset(p(1), p(1)),
      ],
    };

    return {
      for (final entry in poligonos.entries)
        entry.key: Path.combine(
          PathOperation.difference,
          Path.combine(
            PathOperation.intersect,
            Path()..addPolygon(entry.value, true),
            exterior,
          ),
          interior,
        ),
      _central: interior,
    };
  }

  /// Los cuatro trazos que separan las caras axiales entre sí.
  List<(Offset, Offset)> separadores(double lado) {
    double p(double v) => v * lado;
    if (!temporal) {
      return [
        (Offset.zero, Offset(p(_a), p(_a))),
        (Offset(p(1), 0), Offset(p(_b), p(_a))),
        (Offset(0, p(1)), Offset(p(_a), p(_b))),
        (Offset(p(1), p(1)), Offset(p(_b), p(_b))),
      ];
    }
    final centro = Offset(lado / 2, lado / 2);
    final rExterior = lado / 2;
    final rInterior = (_b - _a) * lado / 2;
    return [
      for (final grados in [45, 135, 225, 315])
        (
          centro + Offset.fromDirection(grados * math.pi / 180, rInterior),
          centro + Offset.fromDirection(grados * math.pi / 180, rExterior),
        ),
    ];
  }
}

/// Dibuja el glifo de una pieza con lo anotado hoy encima.
///
/// Una sola capa a plena tinta: lo de esta consulta. Los antecedentes ya no se
/// estampan en tinta tenue sobre la pieza —con una boca muy tratada el papel
/// se llenaba de marcas repetidas—; se leen en la ficha de la pieza al tocarla.
///
/// Son tres dibujos distintos sobre el mismo glifo:
/// - [superficies] tiñe cada cara con la tinta de lo que tiene. Es lo que hace
///   visible desde fuera un tratamiento por cara, tenga clave del papel o no.
/// - [piezaCompleta] tiñe el glifo entero por lo mismo, cuando lo anotado no
///   cuelga de una cara (un implante, una prótesis).
/// - [hallazgos] estampa los símbolos de las claves que afectan a la pieza
///   entera (la `X` de pérdida, el `⊙` de un conducto).
class GlifoPiezaPainter extends CustomPainter {
  final GlifoPieza glifo;

  /// Lo que tiñe cada cara, ya resuelto por quien dibuja: una cara solo puede
  /// mostrar una cosa y la elección de cuál es clínica, no del pintor.
  final Map<TipoSuperficie, MarcaClinicaPieza> superficies;

  /// Lo anotado sobre la pieza entera **sin clave del papel**, ya resuelto a
  /// una sola marca. Lo que sí tiene clave viaja por [hallazgos] y estampa su
  /// símbolo; esto es el resto del catálogo, que sin tinte no se vería.
  final MarcaClinicaPieza? piezaCompleta;

  final List<HallazgoDental> hallazgos;
  final PaletaOdontodiagrama paleta;

  /// Realce de foco/hover; no forma parte del dibujo clínico.
  final Color? resalte;

  const GlifoPiezaPainter({
    required this.glifo,
    required this.hallazgos,
    required this.paleta,
    this.superficies = const {},
    this.piezaCompleta,
    this.resalte,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lado = math.min(size.width, size.height);
    final exterior = glifo.contornoExterior(lado);
    final interior = glifo.contornoInterior(lado);

    canvas.drawPath(exterior, Paint()..color = paleta.papel);

    if (resalte != null) {
      canvas.drawPath(exterior, Paint()..color = resalte!);
    }

    _pintarPiezaCompleta(canvas, exterior);
    _pintarSuperficies(canvas, lado);

    final lapiz = Paint()
      ..color = paleta.trazo
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, lado * 0.028)
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(exterior, lapiz);
    canvas.drawPath(interior, lapiz);
    for (final (desde, hasta) in glifo.separadores(lado)) {
      canvas.drawLine(desde, hasta, lapiz);
    }

    _pintarMarcasDePieza(canvas, lado, exterior, hallazgos);
  }

  /// Tiñe el glifo entero por lo anotado sobre la pieza sin clave del papel.
  ///
  /// Va debajo de las caras: si además hay algo anotado en una cara concreta,
  /// esa cara manda, igual que en el mapa de superficies de la ficha.
  void _pintarPiezaCompleta(Canvas canvas, Path exterior) {
    final marca = piezaCompleta;
    if (marca == null) return;
    final estilo = paleta.estiloDe(marca.tintaClinica, marca.procedencia);
    if (estilo.alfaRelleno <= 0) return;
    canvas.drawPath(exterior, Paint()..color = estilo.relleno);
  }

  /// Tiñe cada cara anotada con la tinta de lo que tiene y la firmeza de su
  /// procedencia, exactamente igual que el mapa de caras de la ficha.
  ///
  /// Antes esto solo miraba las claves del papel, así que un tratamiento por
  /// cara —una reconstrucción oclusal— no se veía en el diagrama y había que
  /// abrir la pieza para enterarse de que estaba tratada.
  void _pintarSuperficies(Canvas canvas, double lado) {
    if (superficies.isEmpty) return;

    final regiones = glifo.regiones(lado);
    superficies.forEach((superficie, marca) {
      final region = regiones[superficie];
      if (region == null) return;
      final estilo = paleta.estiloDe(marca.tintaClinica, marca.procedencia);
      if (estilo.alfaRelleno > 0) {
        canvas.drawPath(region, Paint()..color = estilo.relleno);
      }
    });
  }

  void _pintarMarcasDePieza(
    Canvas canvas,
    double lado,
    Path exterior,
    List<HallazgoDental> capa,
  ) {
    final alfa = paleta.alfaRelleno;
    for (final hallazgo in capa) {
      final estado = hallazgo.estado;
      final tinta = paleta.tintaDe(estado);
      if (estado.marca == MarcaClinica.relleno) {
        // Una clave por superficie sin superficies anotadas cubre la pieza.
        if (hallazgo.esPiezaCompleta) {
          canvas.drawPath(
            exterior,
            Paint()..color = tinta.withValues(alpha: alfa),
          );
        }
        continue;
      }
      dibujarMarcaClinica(
        canvas,
        lado: lado,
        marca: estado.marca,
        tinta: tinta,
        recorte: exterior,
        alfaRelleno: alfa,
      );
    }
  }

  @override
  bool shouldRepaint(GlifoPiezaPainter old) =>
      old.paleta != paleta ||
      old.resalte != resalte ||
      old.glifo.fdi != glifo.fdi ||
      old.piezaCompleta != piezaCompleta ||
      !listEquals(old.hallazgos, hallazgos) ||
      !mapEquals(old.superficies, superficies);
}

/// Traza una de las claves del formulario sobre un lienzo de [lado] píxeles.
/// Se reutiliza en el diagrama y en la leyenda para que el símbolo impreso y
/// el de la referencia sean el mismo dibujo.
void dibujarMarcaClinica(
  Canvas canvas, {
  required double lado,
  required MarcaClinica marca,
  required Color tinta,
  Path? recorte,
  double alfaRelleno = 0.72,
}) {
  final pincel = Paint()
    ..color = tinta
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.1, lado * 0.055)
    ..strokeCap = StrokeCap.round;
  final centro = Offset(lado / 2, lado / 2);

  switch (marca) {
    case MarcaClinica.relleno:
      final path =
          recorte ?? (Path()..addRect(Rect.fromLTWH(0, 0, lado, lado)));
      canvas.drawPath(
        path,
        Paint()..color = tinta.withValues(alpha: alfaRelleno),
      );

    case MarcaClinica.rayado:
      canvas.save();
      canvas.clipPath(
        recorte ?? (Path()..addRect(Rect.fromLTWH(0, 0, lado, lado))),
      );
      final paso = math.max(3.0, lado * 0.24);
      for (double d = -lado; d < lado * 2; d += paso) {
        canvas.drawLine(Offset(d, lado), Offset(d + lado, 0), pincel);
      }
      canvas.restore();

    case MarcaClinica.equis:
      final m = lado * 0.14;
      canvas
        ..drawLine(Offset(m, m), Offset(lado - m, lado - m), pincel)
        ..drawLine(Offset(lado - m, m), Offset(m, lado - m), pincel);

    case MarcaClinica.circuloPunto:
      canvas
        ..drawCircle(centro, lado * 0.30, pincel)
        ..drawCircle(centro, lado * 0.095, Paint()..color = tinta);

    case MarcaClinica.guion:
      canvas.drawLine(
        Offset(lado * 0.16, lado / 2),
        Offset(lado * 0.84, lado / 2),
        pincel,
      );

    case MarcaClinica.asterisco:
      final r = lado * 0.32;
      for (final grados in [90, 30, 150]) {
        final v = Offset.fromDirection(grados * math.pi / 180, r);
        canvas.drawLine(centro - v, centro + v, pincel);
      }
  }
}

/// Símbolo de una clave, dibujado con el mismo trazo y sobre el mismo papel que
/// el diagrama, para que la leyenda y el dibujo no puedan divergir.
class MarcaClinicaIcono extends StatelessWidget {
  final MarcaClinica marca;
  final PaletaOdontodiagrama paleta;

  /// Tinta explícita. Por defecto la de [estado] resuelta contra la paleta.
  final Color? tinta;
  final EstadoClinicoDental? estado;
  final double lado;

  const MarcaClinicaIcono({
    super.key,
    required this.marca,
    required this.paleta,
    this.tinta,
    this.estado,
    this.lado = 16,
  }) : assert(tinta != null || estado != null, 'Hace falta una tinta');

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(lado),
    painter: _MarcaIconoPainter(
      marca: marca,
      tinta: tinta ?? paleta.tintaDe(estado!),
      paleta: paleta,
    ),
  );
}

class _MarcaIconoPainter extends CustomPainter {
  final MarcaClinica marca;
  final Color tinta;
  final PaletaOdontodiagrama paleta;

  const _MarcaIconoPainter({
    required this.marca,
    required this.tinta,
    required this.paleta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lado = math.min(size.width, size.height);
    final marco = Path()..addRect(Rect.fromLTWH(0, 0, lado, lado));
    canvas.drawPath(marco, Paint()..color = paleta.papel);
    dibujarMarcaClinica(
      canvas,
      lado: lado,
      marca: marca,
      tinta: tinta,
      recorte: marco,
      alfaRelleno: paleta.alfaRelleno,
    );
    canvas.drawPath(
      marco,
      Paint()
        ..color = paleta.trazo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MarcaIconoPainter old) =>
      old.marca != marca || old.tinta != tinta || old.paleta != paleta;
}
