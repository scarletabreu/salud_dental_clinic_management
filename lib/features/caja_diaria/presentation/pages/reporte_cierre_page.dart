import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  const ReporteCierrePage({
    super.key,
    required this.resumen,
    required this.montoContado,
    required this.diferencia,
    required this.fechaCierre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de cierre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
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
        icon: const Icon(Icons.done),
        label: const Text('Finalizar'),
      ),
    );
  }

  Future<Uint8List> _generarPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final formatoFecha = DateFormat('dd/MM/yyyy hh:mm a');
    final cuadra = diferencia == 0;

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de cierre de caja',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Fecha: ${formatoFecha.format(fechaCierre)}'),
              pw.SizedBox(height: 16),

              pw.Text(
                'Totales por método de pago',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Método de pago', 'Total'],
                data: resumen.totalesPorMetodoPago.entries
                    .map((e) => [e.key, 'RD\$ ${e.value.toStringAsFixed(2)}'])
                    .toList(),
              ),
              pw.SizedBox(height: 16),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total ingresos: RD\$ ${resumen.totalIngresos.toStringAsFixed(2)}',
                  ),
                  pw.Text(
                    'Total egresos: RD\$ ${resumen.totalEgresos.toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Monto esperado: RD\$ ${resumen.montoEsperado.toStringAsFixed(2)}',
              ),
              pw.Text('Monto contado: RD\$ ${montoContado.toStringAsFixed(2)}'),
              pw.Text(
                cuadra
                    ? 'Diferencia: cuadra'
                    : 'Diferencia: RD\$ ${diferencia.abs().toStringAsFixed(2)} '
                          '(${diferencia < 0 ? "faltante" : "sobrante"})',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: cuadra ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Movimientos del día',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Hora', 'Tipo', 'Método', 'Descripción', 'Monto'],
                data: resumen.movimientos
                    .map(
                      (m) => [
                        DateFormat('hh:mm a').format(m.fecha),
                        m.tipo.name.toUpperCase(),
                        m.metodoPago,
                        m.descripcion,
                        'RD\$ ${m.monto.toStringAsFixed(2)}',
                      ],
                    )
                    .toList(),
              ),

              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma de quien cierra'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma de supervisión'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
