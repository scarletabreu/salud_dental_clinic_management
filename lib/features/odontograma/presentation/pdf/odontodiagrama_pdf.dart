import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';

Future<Uint8List> generarOdontodiagramaPdf({
  required Uint8List diagramaPng,
  required String nombrePaciente,
  required DateTime fecha,
  PdfPageFormat formato = PdfPageFormat.a4,
  pw.ThemeData? tema,
  String logoAssetPath = 'assets/images/logo.png',
}) async {
  final theme =
      tema ??
      pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );

  final documento = pw.Document(theme: theme);
  final imagen = pw.MemoryImage(diagramaPng);

  final doradoPrincipal = PdfColor.fromHex('#C5A059');
  final doradoSuave = PdfColor.fromHex('#F9F5EB');
  final tintaPrincipal = PdfColor.fromHex('#0F172A');
  final grisTexto = PdfColor.fromHex('#64748B');
  final grisLinea = PdfColor.fromHex('#E2E8F0');
  final fondoTarjeta = PdfColor.fromHex('#F8FAFC');

  pw.MemoryImage? logoImage;
  try {
    final logoData = await rootBundle.load(logoAssetPath);
    logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (_) {}

  documento.addPage(
    pw.Page(
      pageFormat: formato,
      theme: theme,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.SizedBox(
                      width: 44,
                      height: 44,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLÍNICA SALUD DENTAL INTEGRAL',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: tintaPrincipal,
                          letterSpacing: -0.2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Centro de Especialidades Odontológicas',
                        style: pw.TextStyle(fontSize: 9, color: grisTexto),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: doradoSuave,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'ODONTODIAGRAMA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: doradoPrincipal,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Fecha: ${fechaCortaEs(fecha.toLocal())}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: grisTexto,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 14),
          pw.Divider(thickness: 1, color: grisLinea),
          pw.SizedBox(height: 12),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: fondoTarjeta,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: grisLinea, width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'PACIENTE: ',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: grisTexto,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  nombrePaciente,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: tintaPrincipal,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: grisLinea, width: 0.8),
              ),
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Image(imagen, fit: pw.BoxFit.contain),
              ),
            ),
          ),

          pw.SizedBox(height: 16),

          pw.Divider(thickness: 0.8, color: grisLinea),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Documento generado clínicamente por Salud Dental App',
                style: pw.TextStyle(fontSize: 8, color: grisTexto),
              ),
              pw.Text(
                'Página 1 de 1',
                style: pw.TextStyle(fontSize: 8, color: grisTexto),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return documento.save();
}

String nombreArchivoOdontodiagrama(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return 'odontodiagrama_${fecha.year}$mes$dia.pdf';
}
