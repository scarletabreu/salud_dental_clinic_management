import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';

Future<Uint8List> generarReciboPdf(
  ReciboPago recibo, {
  PdfPageFormat formato = PdfPageFormat.a4,
}) async {
  final fuente = await PdfGoogleFonts.openSansRegular();
  final fuenteNegrita = await PdfGoogleFonts.openSansBold();
  final documento = pw.Document(
    title: 'Recibo de pago ${recibo.numero}',
    author: recibo.clinica.nombre,
    subject: 'Constancia de pago no fiscal',
  );
  final azul = PdfColor.fromHex('#1769AA');
  final tinta = PdfColor.fromHex('#172033');
  final gris = PdfColor.fromHex('#667085');
  final linea = PdfColor.fromHex('#D9E2EC');
  final fondo = PdfColor.fromHex('#F4F8FB');

  documento.addPage(
    pw.MultiPage(
      pageFormat: formato,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: fuente, bold: fuenteNegrita),
      header: (context) => pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 44,
                height: 44,
                decoration: pw.BoxDecoration(
                  color: azul,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'SD',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      recibo.clinica.nombre,
                      style: pw.TextStyle(
                        color: tinta,
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      recibo.clinica.descripcion,
                      style: pw.TextStyle(color: gris, fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RECIBO DE PAGO',
                    style: pw.TextStyle(
                      color: azul,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '#${recibo.numero}',
                    style: pw.TextStyle(color: gris),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: linea),
          pw.SizedBox(height: 14),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: linea),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Constancia de pago · No es comprobante fiscal DGII',
                style: pw.TextStyle(color: gris, fontSize: 8),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(color: gris, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _bloqueDatos(
                titulo: 'Paciente',
                filas: [
                  ('Nombre', recibo.paciente.fullName),
                  (
                    'Cédula',
                    recibo.paciente.govID.isEmpty ? '-' : recibo.paciente.govID,
                  ),
                ],
                tinta: tinta,
                gris: gris,
                fondo: fondo,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _bloqueDatos(
                titulo: 'Pago y consulta',
                filas: [
                  (
                    'Fecha',
                    '${fechaLargaEs(recibo.pago.fecha.toLocal())} · ${_hora(recibo.pago.fecha)}',
                  ),
                  ('Consulta', '#${recibo.consultaNumero}'),
                  ('Método', recibo.pago.metodoPago.name),
                ],
                tinta: tinta,
                gris: gris,
                fondo: fondo,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'DESGLOSE DE LA CUENTA',
          style: pw.TextStyle(
            color: gris,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: linea, width: 0.6),
            bottom: pw.BorderSide(color: linea),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: fondo),
              children: [
                _celda('Descripción', tinta, negrita: true),
                _celda('Cant.', tinta, negrita: true, alinearDerecha: true),
                _celda('Precio', tinta, negrita: true, alinearDerecha: true),
                _celda('Importe', tinta, negrita: true, alinearDerecha: true),
              ],
            ),
            for (final item in recibo.cuenta.itemCuentas)
              pw.TableRow(
                children: [
                  _celda(item.descripcion, tinta),
                  _celda('${item.cantidad}', tinta, alinearDerecha: true),
                  _celda(
                    formatMoneda(item.precioUnitario),
                    tinta,
                    alinearDerecha: true,
                  ),
                  _celda(
                    formatMoneda(item.precioTotal),
                    tinta,
                    alinearDerecha: true,
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 240,
            child: pw.Column(
              children: [
                _total(
                  'Total de la cuenta',
                  recibo.cuenta.montoTotal,
                  tinta,
                  gris,
                ),
                _total('Pagado anteriormente', recibo.pagadoAntes, tinta, gris),
                pw.SizedBox(height: 7),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: pw.BoxDecoration(
                    color: azul,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PAGO RECIBIDO',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        formatMoneda(recibo.pago.monto),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                _total(
                  'Balance pendiente',
                  recibo.saldoDespues,
                  tinta,
                  gris,
                  negrita: true,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 28),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: linea),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Este documento acredita el pago indicado. No constituye factura ni comprobante fiscal para fines de la DGII.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: gris, fontSize: 8.5),
          ),
        ),
      ],
    ),
  );

  return documento.save();
}

pw.Widget _bloqueDatos({
  required String titulo,
  required List<(String, String)> filas,
  required PdfColor tinta,
  required PdfColor gris,
  required PdfColor fondo,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: fondo,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo.toUpperCase(),
          style: pw.TextStyle(
            color: gris,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 7),
        for (final fila in filas) ...[
          pw.Text(fila.$1, style: pw.TextStyle(color: gris, fontSize: 7.5)),
          pw.SizedBox(height: 1),
          pw.Text(
            fila.$2,
            style: pw.TextStyle(
              color: tinta,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
        ],
      ],
    ),
  );
}

pw.Widget _celda(
  String texto,
  PdfColor color, {
  bool negrita = false,
  bool alinearDerecha = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    child: pw.Text(
      texto,
      textAlign: alinearDerecha ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        color: color,
        fontSize: 8.5,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _total(
  String etiqueta,
  double monto,
  PdfColor tinta,
  PdfColor gris, {
  bool negrita = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(etiqueta, style: pw.TextStyle(color: gris, fontSize: 8.5)),
        pw.Text(
          formatMoneda(monto),
          style: pw.TextStyle(
            color: tinta,
            fontSize: 9,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

String _hora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}
