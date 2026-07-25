import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';

/// Arma la hoja imprimible del odontodiagrama a partir de la captura del
/// widget. No vuelve a dibujar el diagrama: incrusta la misma imagen que el
/// doctor tiene en pantalla, así la hoja y el expediente no pueden divergir.
Future<Uint8List> generarOdontodiagramaPdf({
  required Uint8List diagramaPng,
  required String nombrePaciente,
  required DateTime fecha,
  PdfPageFormat formato = PdfPageFormat.a4,
  pw.ThemeData? tema,
}) async {
  // Las fuentes por defecto del PDF no llevan acentos; sin Open Sans un
  // apellido como «Rodríguez» sale roto. Los tests inyectan su propio tema
  // para no depender de la red.
  final theme =
      tema ??
      pw.ThemeData.withFont(
        base: await PdfGoogleFonts.openSansRegular(),
        bold: await PdfGoogleFonts.openSansBold(),
      );

  final documento = pw.Document(theme: theme);
  final imagen = pw.MemoryImage(diagramaPng);

  documento.addPage(
    pw.Page(
      pageFormat: formato,
      theme: theme,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'ODONTODIAGRAMA',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '$nombrePaciente · ${fechaLargaEs(fecha)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 14),
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.Image(imagen, fit: pw.BoxFit.contain),
            ),
          ),
        ],
      ),
    ),
  );

  return documento.save();
}

/// Nombre sugerido del archivo, con la fecha de la consulta.
String nombreArchivoOdontodiagrama(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return 'odontodiagrama_${fecha.year}$mes$dia.pdf';
}
