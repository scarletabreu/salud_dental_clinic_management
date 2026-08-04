import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';

Future<Uint8List> generarReciboPdf(
  ReciboPago recibo, {
  PdfPageFormat formato = PdfPageFormat.a4,
  String logoAssetPath = 'assets/images/logo.png',
}) async {
  final fuente = await PdfGoogleFonts.openSansRegular();
  final fuenteNegrita = await PdfGoogleFonts.openSansBold();

  final documento = pw.Document(
    title: 'Recibo de pago ${recibo.numero}',
    author: 'Clínica Salud Dental Integral',
    subject: 'Constancia de pago no fiscal',
  );

  final doradoPrincipal = PdfColor.fromHex('#C5A059');
  final doradoSuave = PdfColor.fromHex('#F9F5EB');
  final tintaPrincipal = PdfColor.fromHex('#0F172A');
  final grisTexto = PdfColor.fromHex('#64748B');
  final grisLinea = PdfColor.fromHex('#E2E8F0');
  final fondoTarjeta = PdfColor.fromHex('#F8FAFC');

  final esTermico = formato.width < 100 * PdfPageFormat.mm;

  pw.MemoryImage? logoImage;
  try {
    final logoData = await rootBundle.load(logoAssetPath);
    logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (_) {}

  // ==========================================
  // FORMATO TÉRMICO (80mm)
  // ==========================================
  if (esTermico) {
    documento.addPage(
      pw.Page(
        pageFormat: formato,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        theme: pw.ThemeData.withFont(base: fuente, bold: fuenteNegrita),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(width: 38, height: 38, child: pw.Image(logoImage)),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                'CLÍNICA SALUD DENTAL INTEGRAL',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: tintaPrincipal,
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Centro de Especialidades Odontológicas',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(color: grisTexto, fontSize: 7.5),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: doradoSuave,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'RECIBO DE PAGO #${recibo.numero}',
                  style: pw.TextStyle(
                    color: doradoPrincipal,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: grisLinea, thickness: 0.8),
              pw.SizedBox(height: 6),

              _filaTermica(
                'Paciente:',
                recibo.paciente.fullName,
                tintaPrincipal,
                grisTexto,
              ),
              if (recibo.paciente.govID.isNotEmpty)
                _filaTermica(
                  'Cédula:',
                  recibo.paciente.govID,
                  tintaPrincipal,
                  grisTexto,
                ),
              _filaTermica(
                'Consulta:',
                '#${recibo.consultaNumero}',
                tintaPrincipal,
                grisTexto,
              ),
              _filaTermica(
                'Fecha:',
                '${fechaCortaEs(recibo.pago.fecha.toLocal())} ${_hora(recibo.pago.fecha)}',
                tintaPrincipal,
                grisTexto,
              ),
              _filaTermica(
                'Método:',
                recibo.pago.metodoPago.name,
                tintaPrincipal,
                grisTexto,
              ),

              pw.SizedBox(height: 8),
              pw.Divider(color: grisLinea, thickness: 0.5),
              pw.SizedBox(height: 6),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'DESGLOSE DE LA CUENTA',
                  style: pw.TextStyle(
                    color: grisTexto,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),

              for (final item in recibo.cuenta.itemCuentas) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item.cantidad}x ${item.descripcion}',
                        style: pw.TextStyle(color: tintaPrincipal, fontSize: 8),
                      ),
                    ),
                    pw.Text(
                      formatMoneda(item.precioTotal),
                      style: pw.TextStyle(
                        color: tintaPrincipal,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(color: grisLinea, thickness: 0.5),
              pw.SizedBox(height: 6),

              _totalTermico(
                'Total de la cuenta:',
                recibo.cuenta.montoTotal,
                tintaPrincipal,
                grisTexto,
              ),
              _totalTermico(
                'Pagado anteriormente:',
                recibo.pagadoAntes,
                tintaPrincipal,
                grisTexto,
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: doradoPrincipal,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PAGO RECIBIDO',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatMoneda(recibo.pago.monto),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              _totalTermico(
                'Balance pendiente:',
                recibo.saldoDespues,
                tintaPrincipal,
                grisTexto,
                destacado: true,
              ),

              pw.SizedBox(height: 14),
              pw.Text(
                'Constancia de pago · No es comprobante fiscal DGII',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(color: grisTexto, fontSize: 6.5),
              ),
            ],
          );
        },
      ),
    );

    return documento.save();
  }

  // ==========================================
  // FORMATO ESTÁNDAR (A4 / Hoja Normal)
  // ==========================================
  documento.addPage(
    pw.MultiPage(
      pageFormat: formato,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: fuente, bold: fuenteNegrita),
      header: (context) => pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(width: 44, height: 44, child: pw.Image(logoImage)),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLÍNICA SALUD DENTAL INTEGRAL',
                      style: pw.TextStyle(
                        color: tintaPrincipal,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Centro de Especialidades Odontológicas',
                      style: pw.TextStyle(color: grisTexto, fontSize: 9),
                    ),
                  ],
                ),
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
                      'RECIBO DE PAGO',
                      style: pw.TextStyle(
                        color: doradoPrincipal,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '#${recibo.numero}',
                    style: pw.TextStyle(
                      color: grisTexto,
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: grisLinea, thickness: 1),
          pw.SizedBox(height: 16),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: grisLinea, thickness: 0.8),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Constancia de pago · No es comprobante fiscal DGII',
                style: pw.TextStyle(color: grisTexto, fontSize: 8),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(color: grisTexto, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        // 1. BLOQUES DE INFORMACIÓN (Paciente / Pago)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _bloqueInformacion(
                titulo: 'DATOS DEL PACIENTE',
                filas: [
                  ('Nombre', recibo.paciente.fullName),
                  (
                    'Cédula',
                    recibo.paciente.govID.isEmpty ? '—' : recibo.paciente.govID,
                  ),
                ],
                tinta: tintaPrincipal,
                gris: grisTexto,
                fondo: fondoTarjeta,
                borde: grisLinea,
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: _bloqueInformacion(
                titulo: 'DETALLES DE CONSULTA',
                filas: [
                  (
                    'Fecha',
                    '${fechaLargaEs(recibo.pago.fecha.toLocal())} · ${_hora(recibo.pago.fecha)}',
                  ),
                  ('Consulta', '#${recibo.consultaNumero}'),
                  ('Método', recibo.pago.metodoPago.name),
                ],
                tinta: tintaPrincipal,
                gris: grisTexto,
                fondo: fondoTarjeta,
                borde: grisLinea,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 22),

        // 2. TÍTULO DESGLOSE
        pw.Text(
          'DESGLOSE DE LA CUENTA',
          style: pw.TextStyle(
            color: grisTexto,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 8),

        // 3. TABLA MODERNA Y ELEGANTE
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: grisLinea, width: 0.8),
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: grisLinea, width: 0.6),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              // Cabecera suave
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: fondoTarjeta,
                  borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(8),
                  ),
                ),
                children: [
                  _celdaTabla(
                    'Descripción',
                    grisTexto,
                    negrita: true,
                    paddingVertical: 8,
                  ),
                  _celdaTabla(
                    'Cant.',
                    grisTexto,
                    negrita: true,
                    alinearDerecha: true,
                    paddingVertical: 8,
                  ),
                  _celdaTabla(
                    'Precio',
                    grisTexto,
                    negrita: true,
                    alinearDerecha: true,
                    paddingVertical: 8,
                  ),
                  _celdaTabla(
                    'Importe',
                    grisTexto,
                    negrita: true,
                    alinearDerecha: true,
                    paddingVertical: 8,
                  ),
                ],
              ),
              // Filas de ítems
              for (final item in recibo.cuenta.itemCuentas)
                pw.TableRow(
                  children: [
                    _celdaTabla(
                      item.descripcion,
                      tintaPrincipal,
                      paddingVertical: 9,
                    ),
                    _celdaTabla(
                      '${item.cantidad}',
                      tintaPrincipal,
                      alinearDerecha: true,
                      paddingVertical: 9,
                    ),
                    _celdaTabla(
                      formatMoneda(item.precioUnitario),
                      tintaPrincipal,
                      alinearDerecha: true,
                      paddingVertical: 9,
                    ),
                    _celdaTabla(
                      formatMoneda(item.precioTotal),
                      tintaPrincipal,
                      alinearDerecha: true,
                      paddingVertical: 9,
                    ),
                  ],
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // 4. TOTALES Y BLOQUE DESTACADO DE PAGO
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 260,
            child: pw.Column(
              children: [
                _lineaTotal(
                  'Total de la cuenta',
                  recibo.cuenta.montoTotal,
                  tintaPrincipal,
                  grisTexto,
                ),
                pw.SizedBox(height: 4),
                _lineaTotal(
                  'Pagado anteriormente',
                  recibo.pagadoAntes,
                  tintaPrincipal,
                  grisTexto,
                ),
                pw.SizedBox(height: 10),

                // Tarjeta dorada redondeada para Pago Recibido
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: doradoPrincipal,
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
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        formatMoneda(recibo.pago.monto),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 13.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),
                _lineaTotal(
                  'Balance pendiente',
                  recibo.saldoDespues,
                  tintaPrincipal,
                  grisTexto,
                  destacado: true,
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 28),

        // 5. NOTA ACLARATORIA ENMARCADA
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: fondoTarjeta,
            border: pw.Border.all(color: grisLinea, width: 0.8),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Este documento acredita el pago indicado. No constituye factura ni comprobante fiscal para fines de la DGII.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: grisTexto, fontSize: 8, height: 1.3),
          ),
        ),
      ],
    ),
  );

  return documento.save();
}

// ==========================================
// WIDGETS AUXILIARES
// ==========================================

pw.Widget _bloqueInformacion({
  required String titulo,
  required List<(String, String)> filas,
  required PdfColor tinta,
  required PdfColor gris,
  required PdfColor fondo,
  required PdfColor borde,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: fondo,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: borde, width: 0.8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            color: gris,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 6),
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

pw.Widget _celdaTabla(
  String texto,
  PdfColor color, {
  bool negrita = false,
  bool alinearDerecha = false,
  double paddingVertical = 8,
}) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: paddingVertical),
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

pw.Widget _lineaTotal(
  String etiqueta,
  double monto,
  PdfColor tinta,
  PdfColor gris, {
  bool destacado = false,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        etiqueta,
        style: pw.TextStyle(
          color: destacado ? tinta : gris,
          fontSize: 8.5,
          fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
      pw.Text(
        formatMoneda(monto),
        style: pw.TextStyle(
          color: tinta,
          fontSize: destacado ? 9.5 : 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
}

pw.Widget _filaTermica(
  String label,
  String valor,
  PdfColor tinta,
  PdfColor gris,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: gris, fontSize: 8)),
        pw.Text(
          valor,
          style: pw.TextStyle(
            color: tinta,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _totalTermico(
  String label,
  double monto,
  PdfColor tinta,
  PdfColor gris, {
  bool destacado = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: gris, fontSize: 8.5)),
        pw.Text(
          formatMoneda(monto),
          style: pw.TextStyle(
            color: tinta,
            fontSize: destacado ? 9.5 : 8.5,
            fontWeight: pw.FontWeight.bold,
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
