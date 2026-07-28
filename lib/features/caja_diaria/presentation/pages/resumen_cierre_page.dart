import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';

class ReporteCierrePage extends StatelessWidget {
  final ResumenCierre resumen;
  final double montoContado;
  final double diferencia;
  final DateTime fechaCierre;
  final String logoAssetPath;

  const ReporteCierrePage({
    super.key,
    required this.resumen,
    required this.montoContado,
    required this.diferencia,
    required this.fechaCierre,
    this.logoAssetPath = 'assets/images/logo.png',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Cierre de Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir Reporte',
            onPressed: () =>
                Printing.layoutPdf(onLayout: (format) => _generarPdf(format)),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generarPdf(format),
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        icon: const Icon(Icons.done_rounded),
        label: const Text('Finalizar'),
      ),
    );
  }

  Future<Uint8List> _generarPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final formatoFecha = DateFormat('dd/MM/yyyy hh:mm a');
    final formatoHora = DateFormat('hh:mm a');
    final cuadra = diferencia == 0;

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load(logoAssetPath);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
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
                        pw.Container(
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
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Centro de Especialidades Odontológicas',
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColors.grey700,
                            ),
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),
                        child: pw.Text(
                          'CIERRE DE CAJA',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Fecha: ${formatoFecha.format(fechaCierre)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(thickness: 1, color: PdfColors.blue900),
              pw.SizedBox(height: 12),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _bloqueMonto(
                          'TOTAL INGRESOS',
                          'RD\$ ${resumen.totalIngresos.toStringAsFixed(2)}',
                          PdfColors.green800,
                        ),
                        _bloqueMonto(
                          'TOTAL EGRESOS',
                          'RD\$ ${resumen.totalEgresos.toStringAsFixed(2)}',
                          PdfColors.red800,
                        ),
                        _bloqueMonto(
                          'MONTO ESPERADO',
                          'RD\$ ${resumen.montoEsperado.toStringAsFixed(2)}',
                          PdfColors.blue900,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Monto Contado en Arqueo: RD\$ ${montoContado.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            color: cuadra
                                ? PdfColors.green50
                                : (diferencia < 0
                                      ? PdfColors.red50
                                      : PdfColors.amber50),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                            border: pw.Border.all(
                              color: cuadra
                                  ? PdfColors.green300
                                  : (diferencia < 0
                                        ? PdfColors.red300
                                        : PdfColors.amber300),
                            ),
                          ),
                          child: pw.Text(
                            cuadra
                                ? 'DIFERENCIA: CUADRADO'
                                : 'DIFERENCIA: RD\$ ${diferencia.abs().toStringAsFixed(2)} (${diferencia < 0 ? "FALTANTE" : "SOBRANTE"})',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: cuadra
                                  ? PdfColors.green900
                                  : (diferencia < 0
                                        ? PdfColors.red900
                                        : PdfColors.amber900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'DESGLOSE POR MÉTODO DE PAGO',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Método de Pago', 'Total Recaudado'],
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
                data: resumen.totalesPorMetodoPago.entries
                    .map(
                      (e) => [
                        e.key.toUpperCase(),
                        'RD\$ ${e.value.toStringAsFixed(2)}',
                      ],
                    )
                    .toList(),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'MOVIMIENTOS DEL DÍA',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Table.fromTextArray(
                  headers: ['Hora', 'Tipo', 'Descripción', 'Monto'],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellHeight: 18,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerRight,
                  },
                  data: resumen.movimientos
                      .map(
                        (m) => [
                          formatoHora.format(m.fecha),
                          m.tipo.name.toUpperCase(),
                          m.descripcion.isNotEmpty ? m.descripcion : '-',
                          'RD\$ ${m.monto.toStringAsFixed(2)}',
                        ],
                      )
                      .toList(),
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 170,
                        height: 1,
                        color: PdfColors.grey800,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Firma de quien cierra',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 170,
                        height: 1,
                        color: PdfColors.grey800,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Firma de supervisión',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Documento generado clínicamente por Salud Dental App',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _bloqueMonto(String etiqueta, String valor, PdfColor colorValor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          etiqueta,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: colorValor,
          ),
        ),
      ],
    );
  }
}
