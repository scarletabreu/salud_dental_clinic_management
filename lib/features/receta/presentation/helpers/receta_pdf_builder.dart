import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaPdfBuilder {
  static Future<Uint8List> buildPdf({
    required Receta receta,
    required Paciente paciente,
  }) async {
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
    );

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader(receta),
              pw.SizedBox(height: 16),

              // Datos Paciente y Médico
              _buildInfoSection(receta, paciente),
              pw.SizedBox(height: 20),

              // Título Prescripción
              pw.Text(
                'Rp. / PRECRIPCIÓN MÉDICA',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1D4ED8),
                ),
              ),
              pw.SizedBox(height: 8),

              // Tabla Renglones
              _buildItemsTable(receta),
              pw.SizedBox(height: 16),

              // Indicaciones Generales
              if (receta.indicacionesGenerales?.trim().isNotEmpty == true) ...[
                pw.Text(
                  'INDICACIONES GENERALES:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    receta.indicacionesGenerales!,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // Justificación
              if (receta.justificacionContraindicaciones?.trim().isNotEmpty ==
                  true) ...[
                pw.Text(
                  'JUSTIFICACIÓN MÉDICA:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
                pw.Text(
                  receta.justificacionContraindicaciones!,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Firma y Sello
              _buildFirmaSection(receta),
              pw.SizedBox(height: 10),

              // Pie de página
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'Clínica Salud Dental Integral · Documento Clínico Oficial · Conservar para Farmacia',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Receta r) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Clínica Salud Dental Integral',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF2563EB),
              ),
            ),
            pw.Text(
              'Atención Odontológica Especializada',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              'Teléfono: (809) 555-0199',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(0xFF2563EB)),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                r.codigoReceta,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2563EB),
                ),
              ),
              pw.Text(
                'Fecha: ${fechaCortaEs(r.fechaEmision)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoSection(Receta r, Paciente p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PACIENTE:',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  '${p.nombre} ${p.apellido}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Cédula: ${p.govID}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DOCTOR PRESCRIPTOR:',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  r.doctorNombre ?? 'Dr. Odontólogo Responsable',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Especialidad Odontológica',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Receta r) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFF6FF),
          ),
          children: [
            _th('MEDICAMENTO / PRESENTACIÓN'),
            _th('DOSIS'),
            _th('FRECUENCIA'),
            _th('DURACIÓN'),
            _th('CANTIDAD'),
          ],
        ),
        ...r.items.map((item) {
          final concatNombre = item.presentacionConcentracion.isNotEmpty
              ? '${item.nombreMedicamento} (${item.presentacionConcentracion})'
              : item.nombreMedicamento;

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      concatNombre,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (item.viaAdministracion.isNotEmpty)
                      pw.Text(
                        'Vía: ${item.viaAdministracion}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (item.indicacionesEspecificas?.isNotEmpty == true)
                      pw.Text(
                        'Nota: ${item.indicacionesEspecificas}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              _td(item.dosis),
              _td(item.frecuencia),
              _td(item.duracion),
              _td(item.cantidadIndicada.isEmpty ? '—' : item.cantidadIndicada),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF1D4ED8),
        ),
      ),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _buildFirmaSection(Receta r) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Estado de Receta: ${r.estado.name.toUpperCase()}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            if (r.motivoAnulacion != null)
              pw.Text(
                'Nota: ${r.motivoAnulacion}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.red800),
              ),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(
              r.doctorNombre ?? 'Firma del Odontólogo',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Sello y Exequátur Profesional',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }
}
