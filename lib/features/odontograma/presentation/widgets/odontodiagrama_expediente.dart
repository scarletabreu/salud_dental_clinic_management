import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/pdf/odontodiagrama_pdf.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';

/// El odontodiagrama tal como se archiva en el expediente: solo lectura, sobre
/// papel y listo para imprimir.
///
/// La hoja impresa es una captura de esta misma vista, así que lo que el doctor
/// ve en pantalla y lo que sale por la impresora no pueden divergir.
class OdontodiagramaExpediente extends StatefulWidget {
  final EvaluacionOdontologica evaluacion;
  final String nombrePaciente;
  final DateTime fecha;

  /// Oculta el botón de imprimir, para donde el odontodiagrama es solo una
  /// referencia dentro de otra vista.
  final bool permiteImprimir;

  const OdontodiagramaExpediente({
    super.key,
    required this.evaluacion,
    required this.nombrePaciente,
    required this.fecha,
    this.permiteImprimir = true,
  });

  /// Identifica el lienzo capturable, para que los tests puedan localizarlo.
  static const lienzoKey = ValueKey('odontodiagrama-lienzo');

  @override
  State<OdontodiagramaExpediente> createState() =>
      _OdontodiagramaExpedienteState();
}

class _OdontodiagramaExpedienteState extends State<OdontodiagramaExpediente> {
  final _lienzo = GlobalKey();
  bool _generando = false;

  Future<void> _imprimir() async {
    if (_generando) return;
    setState(() => _generando = true);
    try {
      final png = await capturarLienzo(_lienzo);
      await Printing.layoutPdf(
        name: nombreArchivoOdontodiagrama(widget.fecha),
        onLayout: (formato) => generarOdontodiagramaPdf(
          diagramaPng: png,
          nombrePaciente: widget.nombrePaciente,
          fecha: widget.fecha,
          formato: formato,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo preparar el odontodiagrama para imprimir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.permiteImprimir)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _generando ? null : _imprimir,
              icon: _generando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 16),
              label: Text(_generando ? 'Preparando…' : 'Imprimir'),
              style: TextButton.styleFrom(foregroundColor: ac.primaryBlue),
            ),
          ),
        RepaintBoundary(
          key: _lienzo,
          child: OdontodiagramaPapel(
            key: OdontodiagramaExpediente.lienzoKey,
            evaluacion: widget.evaluacion,
          ),
        ),
      ],
    );
  }
}

/// Rasteriza el subárbol de un [RepaintBoundary] a PNG.
Future<Uint8List> capturarLienzo(GlobalKey lienzo, {double escala = 3}) async {
  final objeto = lienzo.currentContext?.findRenderObject();
  if (objeto is! RenderRepaintBoundary) {
    throw StateError('El odontodiagrama todavía no se ha dibujado.');
  }
  final imagen = await objeto.toImage(pixelRatio: escala);
  try {
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    if (datos == null) throw StateError('No se pudo capturar el diagrama.');
    return datos.buffer.asUint8List();
  } finally {
    imagen.dispose();
  }
}
