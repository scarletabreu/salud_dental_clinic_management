import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
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

/// Dibuja el glifo de una pieza con sus hallazgos encima.
class GlifoPiezaPainter extends CustomPainter {
  final GlifoPieza glifo;
  final List<HallazgoDental> hallazgos;
  final Color trazo;
  final Color papel;

  /// Realce de foco/hover; no forma parte del dibujo clínico.
  final Color? resalte;

  const GlifoPiezaPainter({
    required this.glifo,
    required this.hallazgos,
    required this.trazo,
    required this.papel,
    this.resalte,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lado = math.min(size.width, size.height);
    final exterior = glifo.contornoExterior(lado);
    final interior = glifo.contornoInterior(lado);

    canvas.drawPath(exterior, Paint()..color = papel);

    if (resalte != null) {
      canvas.drawPath(exterior, Paint()..color = resalte!);
    }

    _pintarSuperficies(canvas, lado);

    final lapiz = Paint()
      ..color = trazo
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, lado * 0.028)
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(exterior, lapiz);
    canvas.drawPath(interior, lapiz);
    for (final (desde, hasta) in glifo.separadores(lado)) {
      canvas.drawLine(desde, hasta, lapiz);
    }

    _pintarMarcasDePieza(canvas, lado, exterior);
  }

  void _pintarSuperficies(Canvas canvas, double lado) {
    final porSuperficie = <TipoSuperficie, Color>{};
    for (final hallazgo in hallazgos) {
      if (hallazgo.estado.marca != MarcaClinica.relleno) continue;
      for (final superficie in hallazgo.superficies) {
        porSuperficie[superficie] = hallazgo.estado.tinta;
      }
    }
    if (porSuperficie.isEmpty) return;

    final regiones = glifo.regiones(lado);
    porSuperficie.forEach((superficie, tinta) {
      final region = regiones[superficie];
      if (region == null) return;
      canvas.drawPath(region, Paint()..color = tinta.withValues(alpha: 0.72));
    });
  }

  void _pintarMarcasDePieza(Canvas canvas, double lado, Path exterior) {
    for (final hallazgo in hallazgos) {
      final estado = hallazgo.estado;
      if (estado.marca == MarcaClinica.relleno) {
        // Una clave por superficie sin superficies anotadas cubre la pieza.
        if (hallazgo.esPiezaCompleta) {
          canvas.drawPath(
            exterior,
            Paint()..color = estado.tinta.withValues(alpha: 0.72),
          );
        }
        continue;
      }
      dibujarMarcaClinica(
        canvas,
        lado: lado,
        marca: estado.marca,
        tinta: estado.tinta,
        recorte: exterior,
      );
    }
  }

  @override
  bool shouldRepaint(GlifoPiezaPainter old) =>
      old.trazo != trazo ||
      old.papel != papel ||
      old.resalte != resalte ||
      old.glifo.fdi != glifo.fdi ||
      !listEquals(old.hallazgos, hallazgos);
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
      canvas.drawPath(path, Paint()..color = tinta.withValues(alpha: 0.72));

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

/// Símbolo de una clave, dibujado con el mismo trazo que el diagrama.
class MarcaClinicaIcono extends StatelessWidget {
  final MarcaClinica marca;
  final Color tinta;
  final double lado;
  final Color trazo;

  const MarcaClinicaIcono({
    super.key,
    required this.marca,
    required this.tinta,
    required this.trazo,
    this.lado = 16,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(lado),
    painter: _MarcaIconoPainter(marca: marca, tinta: tinta, trazo: trazo),
  );
}

class _MarcaIconoPainter extends CustomPainter {
  final MarcaClinica marca;
  final Color tinta;
  final Color trazo;

  const _MarcaIconoPainter({
    required this.marca,
    required this.tinta,
    required this.trazo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lado = math.min(size.width, size.height);
    final marco = Path()..addRect(Rect.fromLTWH(0, 0, lado, lado));
    canvas.drawPath(marco, Paint()..color = const Color(0xFFFFFFFF));
    dibujarMarcaClinica(
      canvas,
      lado: lado,
      marca: marca,
      tinta: tinta,
      recorte: marco,
    );
    canvas.drawPath(
      marco,
      Paint()
        ..color = trazo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MarcaIconoPainter old) =>
      old.marca != marca || old.tinta != tinta || old.trazo != trazo;
}
