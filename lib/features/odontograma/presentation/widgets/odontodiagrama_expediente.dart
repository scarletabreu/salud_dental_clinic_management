import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/pdf/odontodiagrama_pdf.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';

class OdontodiagramaExpediente extends StatefulWidget {
  final EvaluacionOdontologica evaluacion;

  /// Las piezas de la consulta, que es de donde salen las marcas sin clave del
  /// formulario. La [evaluacion] sola solo puede pintar las siete claves
  /// impresas: sin esto, imprimir una consulta de reconstrucciones o implantes
  /// daba una hoja en blanco.
  final Map<int, Diente> dientes;

  /// Lo registrado sin pieza. Una consulta de sola limpieza no tiene nada que
  /// dibujar, y sin esta lista su hoja sale en blanco sin explicar por qué.
  final List<String> generales;

  final String nombrePaciente;
  final DateTime fecha;
  final bool permiteImprimir;

  const OdontodiagramaExpediente({
    super.key,
    required this.evaluacion,
    this.dientes = const {},
    this.generales = const [],
    required this.nombrePaciente,
    required this.fecha,
    this.permiteImprimir = true,
  });

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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _generando ? null : _imprimir,
                icon: _generando
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ac.primaryGreen,
                        ),
                      )
                    : Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: ac.primaryGreen,
                      ),
                label: Text(
                  _generando ? 'Preparando…' : 'Imprimir Odontodiagrama',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.primaryGreen,
                  side: BorderSide(color: ac.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        RepaintBoundary(
          key: _lienzo,
          child: OdontodiagramaPapel(
            key: OdontodiagramaExpediente.lienzoKey,
            evaluacion: widget.evaluacion,
            dientes: widget.dientes,
            generales: widget.generales,
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> capturarLienzo(GlobalKey lienzo, {double escala = 3}) async {
  final objeto = lienzo.currentContext?.findRenderObject();
  if (objeto is! RenderRepaintBoundary) {
    throw StateError(
      'El odontodiagrama todavía no se ha dibujado en pantalla.',
    );
  }
  if (objeto.debugNeedsPaint) {
    await Future.delayed(const Duration(milliseconds: 50));
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
