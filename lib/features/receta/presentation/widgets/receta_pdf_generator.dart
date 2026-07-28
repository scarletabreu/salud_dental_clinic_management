import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaPdfGenerator {
  static Future<Uint8List> generatePdf({
    required Receta receta,
    required String pacienteNombre,
    String? doctorNombre,
    String? doctorTelefono,
    String? doctorCelular,
    String? doctorEmail,
    String direccionFija = 'Emilio Prudhomme #27, Bella Vista, Stgo. R.D.',
    String logoAssetPath = 'assets/images/logo.png',
  }) async {
    final pdf = pw.Document();

    final docNombreFinal =
        doctorNombre ?? receta.doctorNombre ?? 'Dr. Odontólogo';

    // 🌟 Colores alineados a la marca Dorado Champagne & Slate
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. ENCABEZADO CON LOGO Y CÓDIGO DE RECETA
              // ==========================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 48,
                          height: 48,
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
                              color: tintaPrincipal,
                              letterSpacing: -0.2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Centro de Especialidades Odontológicas',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: grisTexto,
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: doradoSuave,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          receta.codigoReceta.isNotEmpty
                              ? receta.codigoReceta
                              : 'RECETA MÉDICA',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: doradoPrincipal,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Emisión: ${fechaCortaEs(receta.fechaEmision.toLocal())}',
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

              // ==========================================
              // 2. DATOS DEL PACIENTE Y DOCTOR
              // ==========================================
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: fondoTarjeta,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: grisLinea, width: 0.8),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PACIENTE',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: grisTexto,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            pacienteNombre,
                            style: pw.TextStyle(
                              fontSize: 11.5,
                              fontWeight: pw.FontWeight.bold,
                              color: tintaPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      height: 24,
                      width: 1,
                      color: grisLinea,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DOCTOR(A) TRATANTE',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: grisTexto,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            docNombreFinal,
                            style: pw.TextStyle(
                              fontSize: 11.5,
                              fontWeight: pw.FontWeight.bold,
                              color: tintaPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // ==========================================
              // 3. PRESCRIPCIÓN MÉDICA
              // ==========================================
              pw.Text(
                'PRESCRIPCIÓN MÉDICA',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: grisTexto,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 8),

              for (var i = 0; i < receta.items.length; i++) ...[
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: grisLinea, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${i + 1}. ${receta.items[i].nombreMedicamento}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: tintaPrincipal,
                            ),
                          ),
                          if (receta
                              .items[i]
                              .presentacionConcentracion
                              .isNotEmpty)
                            pw.Text(
                              receta.items[i].presentacionConcentracion,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: grisTexto,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dosis: ${receta.items[i].dosis}  |  Vía: ${receta.items[i].viaAdministracion}  |  Frecuencia: ${receta.items[i].frecuencia}  |  Duración: ${receta.items[i].duracion}',
                        style: pw.TextStyle(fontSize: 9, color: tintaPrincipal),
                      ),
                      if (receta.items[i].cantidadIndicada.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Cantidad a despachar: ${receta.items[i].cantidadIndicada}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: doradoPrincipal,
                          ),
                        ),
                      ],
                      if ((receta.items[i].indicacionesEspecificas ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Nota: ${receta.items[i].indicacionesEspecificas!.trim()}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontStyle: pw.FontStyle.italic,
                            color: grisTexto,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if ((receta.indicacionesGenerales ?? '').trim().isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: fondoTarjeta,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: grisLinea, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Indicaciones Generales:',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: grisTexto,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        receta.indicacionesGenerales!.trim(),
                        style: pw.TextStyle(fontSize: 9, color: tintaPrincipal),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // ==========================================
              // 4. PIE DE PÁGINA (DIRECCIÓN, CONTACTOS Y FIRMA)
              // ==========================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Lado Izquierdo: Dirección fija y contactos resueltos
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        direccionFija,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: tintaPrincipal,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _construirLineaTelefonos(doctorTelefono, doctorCelular),
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: tintaPrincipal,
                        ),
                      ),
                      if (doctorEmail != null && doctorEmail.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          doctorEmail,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: doradoPrincipal,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Lado Derecho: Firma y Sello Odontológico
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 160,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: grisTexto, width: 1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        docNombreFinal,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: tintaPrincipal,
                        ),
                      ),
                      pw.Text(
                        'Firma y Sello Odontológico',
                        style: pw.TextStyle(fontSize: 8, color: grisTexto),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _construirLineaTelefonos(String? tel, String? cel) {
    final partes = <String>[];
    if (tel != null && tel.isNotEmpty) partes.add('Tel.: $tel');
    if (cel != null && cel.isNotEmpty) partes.add('Cel.: $cel');
    if (partes.isEmpty) return 'Tel.: (809) 000-0000';
    return partes.join('  •  ');
  }
}
