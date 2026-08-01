import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/record_condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class _Brand {
  static const primary = PdfColor.fromInt(0xFFC5A059);
  static const primaryDark = PdfColor.fromInt(0xFF9E7E3B);
  static const accent = PdfColor.fromInt(0xFFD4AF37);
  static const accentSoft = PdfColor.fromInt(0xFFFDFBF7);
  static const surface = PdfColor.fromInt(0xFFFFFFFF);
  static const ink = PdfColor.fromInt(0xFF0F172A);
  static const muted = PdfColor.fromInt(0xFF64748B);
  static const border = PdfColor.fromInt(0xFFE2E8F0);
}

class ExpedientePdfBuilder {
  static Future<Uint8List> buildPdf({
    required Paciente paciente,
    required ExpedientePrintOptions options,
    Odontograma? odontograma,
    List<Odontograma> historialOdontogramas = const [],
    HistorialPiezas? historialPiezas,
    DateTime? generadoEn,
    pw.MemoryImage? logoImage,
    pw.ThemeData? theme,
    bool compress = true,
  }) async {
    pw.MemoryImage? finalLogoImage = logoImage;
    if (finalLogoImage == null) {
      try {
        final logoBytes = await rootBundle.load('assets/images/logo.png');
        finalLogoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }

    final documentTheme =
        theme ??
        pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        );

    final pdf = pw.Document(
      theme: documentTheme,
      compress: compress,
      title: 'Expediente clínico de ${paciente.nombre} ${paciente.apellido}',
      author: 'Clínica Salud Dental Integral',
      subject: 'Expediente médico',
    );
    final now = generadoEn ?? DateTime.now();
    final fechaGeneracion = fechaLargaEs(now);
    final record = paciente.record;
    final consultas = [...record.consultas]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final evaluaciones = consultas
        .where((c) => c.tipoAtencion == TipoAtencionClinica.evaluacion)
        .toList();
    final consultasClinicas = consultas
        .where((c) => c.tipoAtencion == TipoAtencionClinica.consulta)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        maxPages: 1000,
        margin: const pw.EdgeInsets.fromLTRB(32, 0, 32, 28),
        header: (context) => _buildHeader(
          paciente,
          fechaGeneracion,
          logoImage: finalLogoImage,
          isFirstPage: context.pageNumber == 1,
        ),
        footer: (context) => _buildFooter(context, logoImage: finalLogoImage),
        build: (context) => [
          pw.SizedBox(height: 14),

          _buildSeccionDatosPaciente(paciente),
          pw.SizedBox(height: 10),

          _buildSeccionRecordClinico(paciente),
          pw.SizedBox(height: 10),

          ..._buildSeccionCondiciones(paciente),
          pw.SizedBox(height: 10),

          if (options.incluirOdontograma) ...[
            _buildSeccionOdontodiagramaOficial(
              odontograma,
              historialOdontogramas: historialOdontogramas,
              hp: historialPiezas,
            ),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirEvaluaciones && evaluaciones.isNotEmpty) ...[
            ..._buildSeccionEvaluaciones(
              evaluaciones,
              logoImage: finalLogoImage,
            ),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirConsultas && consultasClinicas.isNotEmpty) ...[
            ..._buildSeccionConsultas(
              consultasClinicas,
              logoImage: finalLogoImage,
            ),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirTratamientos &&
              _tratamientosDe(consultas).isNotEmpty) ...[
            ..._buildSeccionTratamientos(consultas, logoImage: finalLogoImage),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirRecetas &&
              consultas.any((c) => c.recetas.isNotEmpty)) ...[
            ..._buildSeccionRecetas(consultas, logoImage: finalLogoImage),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirDocumentosReferenciados &&
              consultas.any((c) => c.documentosClinicos.isNotEmpty)) ...[
            ..._buildSeccionDocumentos(consultas, logoImage: finalLogoImage),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static void _paintTooth(
    PdfGraphics canvas,
    double x,
    double y,
    double size,
    PdfColor color,
  ) {
    final s = size / 100;
    double px(double v) => x + v * s;
    double py(double v) => y + v * s;

    canvas
      ..setColor(color)
      ..moveTo(px(50), py(6))
      ..curveTo(px(30), py(6), px(16), py(18), px(14), py(34))
      ..curveTo(px(12), py(48), px(20), py(56), px(23), py(68))
      ..curveTo(px(25), py(80), px(30), py(96), px(39), py(96))
      ..curveTo(px(46), py(96), px(44), py(76), px(50), py(76))
      ..curveTo(px(56), py(76), px(54), py(96), px(61), py(96))
      ..curveTo(px(70), py(96), px(75), py(80), px(77), py(68))
      ..curveTo(px(80), py(56), px(88), py(48), px(86), py(34))
      ..curveTo(px(84), py(18), px(70), py(6), px(50), py(6))
      ..closePath()
      ..fillPath();
  }

  static pw.Widget _toothBadge({
    double size = 22,
    PdfColor bg = _Brand.accentSoft,
    PdfColor tooth = _Brand.primary,
    pw.MemoryImage? logoImage,
  }) {
    if (logoImage != null) {
      return pw.Container(
        width: size,
        height: size,
        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
      );
    }

    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(color: bg, shape: pw.BoxShape.circle),
      child: pw.CustomPaint(
        size: PdfPoint(size, size),
        painter: (canvas, s) =>
            _paintTooth(canvas, s.x * 0.24, s.y * 0.18, s.x * 0.52, tooth),
      ),
    );
  }

  static pw.Widget _buildHeader(
    Paciente p,
    String fecha, {
    pw.MemoryImage? logoImage,
    required bool isFirstPage,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: const pw.BoxDecoration(
            color: _Brand.primary,
            borderRadius: pw.BorderRadius.vertical(
              bottom: pw.Radius.circular(6),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                children: [
                  _toothBadge(
                    size: 32,
                    bg: PdfColors.white,
                    tooth: _Brand.primary,
                    logoImage: logoImage,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Clínica Salud Dental Integral',
                        style: pw.TextStyle(
                          fontSize: 13.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'EXPEDIENTE CLÍNICO DE PACIENTE',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _Brand.accentSoft,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      p.govID.isEmpty ? "S/N" : p.govID,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _Brand.ink,
                      ),
                    ),
                    pw.Text(
                      'Emitido: $fecha',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Container(height: 2.5, color: _Brand.accent),
        if (isFirstPage) pw.SizedBox(height: 6),
        if (!isFirstPage) pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context, {
    pw.MemoryImage? logoImage,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(height: 6),
        pw.Container(height: 0.6, color: _Brand.border),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              children: [
                _toothBadge(
                  size: 13,
                  bg: _Brand.accentSoft,
                  tooth: _Brand.primary,
                  logoImage: logoImage,
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  'Clínica Salud Dental Integral · Registro Clínico Confidencial',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _Brand.ink,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: _Brand.accentSoft,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: _Brand.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String numero, String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _Brand.accent, width: 1.4),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 16,
            height: 16,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _Brand.primary,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              numero,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _Brand.primaryDark,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static pw.BoxDecoration _cardDecoration() => pw.BoxDecoration(
    color: _Brand.surface,
    border: pw.Border.all(color: _Brand.border, width: 0.7),
    borderRadius: pw.BorderRadius.circular(8),
  );

  static pw.Widget _buildSeccionDatosPaciente(Paciente p) {
    final fechaNac =
        '${p.birthDate.day.toString().padLeft(2, '0')}/${p.birthDate.month.toString().padLeft(2, '0')}/${p.birthDate.year}';
    final pesoStr = p.peso != null ? '${p.peso} kg' : 'No registrado';
    final alturaStr = p.altura != null ? '${p.altura} cm' : 'No registrada';

    final contactosNormales = <String>[];
    final contactosEmergencia = <String>[];

    for (final c in p.contactos) {
      final partes = <String>[];
      if (c.numeroTelefono.isNotEmpty) partes.add('Tel: ${c.numeroTelefono}');
      if (c.email.isNotEmpty) partes.add('Email: ${c.email}');
      if (c.direccion.isNotEmpty) partes.add('Dir: ${c.direccion}');

      if (partes.isNotEmpty) {
        final texto = partes.join(' | ');
        if (c.esEmergencia) {
          contactosEmergencia.add(texto);
        } else {
          contactosNormales.add(texto);
        }
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('1', 'INFORMACIÓN PERSONAL Y DE IDENTIFICACIÓN'),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _dato('Nombre completo', '${p.nombre} ${p.apellido}'),
              ),
              pw.Expanded(
                child: _dato(
                  'Cédula / Documento',
                  p.govID.isEmpty ? 'S/N' : p.govID,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(child: _dato('Fecha de Nacimiento', fechaNac)),
              pw.Expanded(child: _dato('Género', p.genero.name.toUpperCase())),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: _dato('Tipo de Paciente', p.tipoPaciente.name),
              ),
              pw.Expanded(child: _dato('Estatus', p.estatus.name)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: _dato(
                  'Ocupación / Trabajo',
                  p.trabajo.isEmpty ? 'N/A' : p.trabajo,
                ),
              ),
              pw.Expanded(
                child: _dato(
                  'Referido por',
                  p.referencia.isEmpty ? 'N/A' : p.referencia,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(child: _dato('Peso', pesoStr)),
              pw.Expanded(child: _dato('Altura', alturaStr)),
            ],
          ),

          if (contactosNormales.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(height: 0.5, color: _Brand.border),
            pw.SizedBox(height: 5),
            _dato('Información de Contacto', contactosNormales.join('  ·  ')),
          ],

          if (contactosEmergencia.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(height: 0.5, color: _Brand.border),
            pw.SizedBox(height: 5),
            _dato('Contacto de Emergencia', contactosEmergencia.join('  ·  ')),
          ],
        ],
      ),
    );
  }

  static pw.Widget _dato(String etiqueta, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          etiqueta.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 6.2,
            fontWeight: pw.FontWeight.bold,
            color: _Brand.muted,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(valor, style: const pw.TextStyle(fontSize: 8.3)),
      ],
    );
  }

  static pw.Widget _buildSeccionRecordClinico(Paciente p) {
    final r = p.record;
    final cirugias = r.surgeries.isEmpty ? 'Ninguna' : r.surgeries.join(', ');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('2', 'ANTECEDENTES Y HISTORIAL CLÍNICO'),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _dato('Tipo de Sangre', r.bloodType)),
              pw.Expanded(child: _dato('Hijos', '${r.childrenCount}')),
            ],
          ),
          pw.SizedBox(height: 5),
          _dato('Cirugías Previas', cirugias),
          pw.SizedBox(height: 5),
          _dato(
            'Historial Familiar',
            r.history.isEmpty ? 'Sin observaciones' : r.history,
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildSeccionCondiciones(Paciente p) {
    final condiciones = p.record.conditions;
    final detalles = p.record.detallesCondiciones;

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: _cardDecoration(),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionTitle('3', 'CONDICIONES MÉDICAS Y ALERGIAS'),
            if (condiciones.isEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Sin condiciones médicas registradas.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ],
        ),
      ),
      if (condiciones.isNotEmpty) pw.SizedBox(height: 4),
      for (final condicion in condiciones)
        ..._clinicalCards(
          condicion.nombre,
          _textoDetalleDe(condicion.id, detalles),
        ),
    ];
  }

  static String _textoDetalleDe(
    String? condicionId,
    List<RecordCondicion> detalles,
  ) {
    final detalle = _detalleDe(condicionId, detalles);
    return detalle == null
        ? 'Sin indicaciones adicionales registradas.'
        : _textoDetalleCondicion(detalle);
  }

  static RecordCondicion? _detalleDe(
    String? condicionId,
    List<RecordCondicion> detalles,
  ) {
    if (condicionId == null) return null;
    for (final detalle in detalles) {
      if (detalle.condicionId == condicionId) return detalle;
    }
    return null;
  }

  static String _textoDetalleCondicion(RecordCondicion detalle) {
    final partes = <String>[];
    if (detalle.activo == false) partes.add('Estado: inactiva');
    final fechaDeteccion = detalle.fechaDeteccion;
    if (fechaDeteccion != null) {
      partes.add('Detectada: ${fechaLargaEs(fechaDeteccion)}');
    }
    final medicamento = (detalle.medicamento ?? '').trim();
    final dosis = (detalle.dosis ?? '').trim();
    final frecuencia = (detalle.frecuencia ?? '').trim();
    if (medicamento.isNotEmpty) {
      final pauta = [dosis, frecuencia].where((e) => e.isNotEmpty).join(' · ');
      partes.add(
        'Medicamento/indicación: $medicamento${pauta.isEmpty ? '' : ' ($pauta)'}',
      );
    }
    final medico = (detalle.medicoTratante ?? '').trim();
    final contacto = (detalle.contactoMedico ?? '').trim();
    if (medico.isNotEmpty || contacto.isNotEmpty) {
      partes.add(
        'Médico tratante: ${medico.isEmpty ? 'No indicado' : medico}'
        '${contacto.isEmpty ? '' : ' · $contacto'}',
      );
    }
    final notas = (detalle.notas ?? '').trim();
    if (notas.isNotEmpty) partes.add('Indicaciones/notas: $notas');
    return partes.isEmpty
        ? 'Sin indicaciones adicionales registradas.'
        : partes.join('\n');
  }

  static pw.Widget _buildSeccionOdontodiagramaOficial(
    Odontograma? o, {
    List<Odontograma> historialOdontogramas = const [],
    HistorialPiezas? hp,
  }) {
    final perm1 = [18, 17, 16, 15, 14, 13, 12, 11];
    final perm2 = [21, 22, 23, 24, 25, 26, 27, 28];
    final temp1 = [55, 54, 53, 52, 51];
    final temp2 = [61, 62, 63, 64, 65];

    final temp4 = [85, 84, 83, 82, 81];
    final temp3 = [71, 72, 73, 74, 75];
    final perm4 = [48, 47, 46, 45, 44, 43, 42, 41];
    final perm3 = [31, 32, 33, 34, 35, 36, 37, 38];

    final listaOdontogramas = historialOdontogramas.isNotEmpty
        ? historialOdontogramas
        : (o != null ? [o] : <Odontograma>[]);

    final tejidosMap = o?.evaluacion.tejidosBlandos ?? {};

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            '4',
            (historialOdontogramas.isNotEmpty || hp != null)
                ? 'ODONTODIAGRAMA CONSOLIDADO HISTÓRICO'
                : 'ODONTODIAGRAMA CLÍNICO',
          ),
          pw.SizedBox(height: 8),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _Brand.border, width: 0.7),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _buildFilaPermanente(
                  perm1,
                  perm2,
                  esSuperior: true,
                  lista: listaOdontogramas,
                  hp: hp,
                ),
                pw.SizedBox(height: 4),
                _buildFilaTemporal(
                  temp1,
                  temp2,
                  esSuperior: true,
                  lista: listaOdontogramas,
                  hp: hp,
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 1,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 40),
                ),
                pw.SizedBox(height: 6),
                _buildFilaTemporal(
                  temp4,
                  temp3,
                  esSuperior: false,
                  lista: listaOdontogramas,
                  hp: hp,
                ),
                pw.SizedBox(height: 4),
                _buildFilaPermanente(
                  perm4,
                  perm3,
                  esSuperior: false,
                  lista: listaOdontogramas,
                  hp: hp,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLAVES',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _Brand.ink,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _buildLeyendaItem(PdfColors.red, 'Cariada'),
                        _buildLeyendaItem(PdfColors.blue, 'Restaura'),
                        _buildLeyendaItem(
                          PdfColors.red800,
                          'Extracción indicada',
                        ),
                        _buildLeyendaItem(PdfColors.grey700, 'Pérdida'),
                        _buildLeyendaItem(
                          PdfColors.red600,
                          'Pulpectomía · Pulpotomía',
                        ),
                        _buildLeyendaItem(PdfColors.blue700, 'No erupcionado'),
                        _buildLeyendaItem(PdfColors.grey800, 'Otro (anotar)'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROCEDENCIA',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _Brand.ink,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _buildLeyendaItem(PdfColors.grey400, 'Evaluado'),
                    pw.SizedBox(height: 3),
                    _buildLeyendaItem(PdfColors.blueGrey800, 'Ejecutado hoy'),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),
          _buildTablaTejidosBlandos(tejidosMap),
        ],
      ),
    );
  }

  /// El odontodiagrama del PDF se arma **con los campos tipados** de las
  /// entidades, no convirtiéndolas a mapas por pato.
  ///
  /// Antes esto pasaba por un `_objToMap` que probaba `toJson()`/`toMap()` y
  /// luego leía `oMap['dientes']`. `OdontogramaModel.toJson()` nunca ha emitido
  /// `dientes`, y `HistorialPiezas` ni siquiera tiene `toJson` —su campo es
  /// `porFdi`—, así que las 52 piezas evaluaban a vacío **siempre**: el
  /// odontodiagrama del expediente jamás pintó una sola marca (defecto D6a de
  /// la jornada de QA del 1 ago 2026). Al ser todo `dynamic`, ni el compilador
  /// ni ningún test lo delataban.
  static _EstadoPiezaResultado _evaluarEstadoPieza(
    int fdi,
    List<Odontograma> lista,
    HistorialPiezas? hp,
  ) {
    final res = _EstadoPiezaResultado();

    // El historial consolidado, cuando lo hay, ya trae las tres capas
    // (histórico, evaluado, planificado, ejecutado) de esa pieza.
    final historial = hp?[fdi];
    if (historial != null && !historial.estaVacio) {
      for (final marca in historial.eventos) {
        // Una fila anulada se conserva en la ficha como constancia, pero no
        // describe el estado actual de la boca: no debe teñir la cara.
        if (marca.anulada || !marca.vigente) continue;
        _procesarMarca(
          nombre: marca.titulo,
          superficie: marca.superficie?.name,
          esDiagnostico: marca.tipo == TipoMarcaClinica.hallazgo,
          res: res,
        );
      }
      return res;
    }

    for (final odontograma in lista) {
      for (final diente in odontograma.dientes) {
        if (diente.fdiCode != fdi) continue;
        _procesarPieza(diente, res);
      }
    }

    return res;
  }

  static void _procesarPieza(Diente diente, _EstadoPiezaResultado res) {
    if (diente.estaAusente) {
      res.simbolo = 'X';
      res.colorSimbolo = PdfColors.red800;
    }

    // Lo de esta consulta y lo de las anteriores pintan igual: el expediente
    // describe el estado de la boca, no en qué visita se anotó cada cosa.
    for (final diagnostico in [
      ...diente.diagnosis,
      ...diente.diagnosticosHistoricos,
    ]) {
      if (diagnostico.anuladoEn != null) continue;
      _procesarMarca(
        nombre: diagnostico.nombreDiagnostico ?? '',
        superficie: diagnostico.superficie?.name,
        esDiagnostico: true,
        res: res,
      );
    }

    for (final tratamiento in [
      ...diente.tratamientos,
      ...diente.tratamientosHistoricos,
    ]) {
      if (tratamiento.anuladoEn != null) continue;
      _procesarMarca(
        nombre: tratamiento.nombreTratamiento ?? '',
        superficie: tratamiento.superficie?.name,
        esDiagnostico: false,
        res: res,
      );
    }
  }

  static void _procesarMarca({
    required String nombre,
    required String? superficie,
    required bool esDiagnostico,
    required _EstadoPiezaResultado res,
  }) {
    final titulo = nombre.trim().isEmpty
        ? (esDiagnostico ? 'caries' : 'restauración')
        : nombre;

    final estadoStr = titulo.toLowerCase();

    if (estadoStr.contains('pulp') ||
        estadoStr.contains('endo') ||
        estadoStr.contains('conducto')) {
      res.simbolo = '⊙';
      res.colorSimbolo = PdfColors.red600;
    } else if (estadoStr.contains('erupcion') ||
        estadoStr.contains('no_erupcionado')) {
      res.simbolo = '=';
      res.colorSimbolo = PdfColors.blue700;
    } else if (estadoStr.contains('perdid') ||
        estadoStr.contains('extracc') ||
        estadoStr.contains('extraer')) {
      res.simbolo = 'X';
      res.colorSimbolo = PdfColors.red800;
    }

    // Un procedimiento ejecutado siempre tiene tinta azul, aunque su nombre
    // no coincida con las pocas palabras que conocía el formulario antiguo.
    // Los diagnósticos conservan su semántica clínica (por ejemplo, caries en
    // rojo) y no se inventa una marca para un hallazgo desconocido.
    final tinta = esDiagnostico ? estadoStr : 'procedimiento ejecutado';

    if (superficie != null && superficie.isNotEmpty) {
      _aplicarColorSuperficie(superficie, tinta, res);
      return;
    }

    // Sin cara concreta el alcance es la pieza completa. Pintar solo el centro
    // hacía que una corona o implante pareciera una intervención oclusal.
    for (final cara in const [
      'vestibular',
      'lingual',
      'mesial',
      'distal',
      'oclusal',
    ]) {
      _aplicarColorSuperficie(cara, tinta, res);
    }
  }

  static void _aplicarColorSuperficie(
    String keyStr,
    String vStr,
    _EstadoPiezaResultado res,
  ) {
    final k = keyStr.toLowerCase();
    final v = vStr.toLowerCase();
    PdfColor col = PdfColors.white;

    if (v.contains('caries') || v.contains('cariada') || v.contains('rojo')) {
      col = PdfColors.red;
    } else if (v.contains('procedimiento ejecutado') ||
        v.contains('restaurad') ||
        v.contains('restaura') ||
        v.contains('azul') ||
        v.contains('resina') ||
        v.contains('amalgama') ||
        v.contains('restauración')) {
      col = PdfColors.blue;
    }

    if (col != PdfColors.white) {
      if (k.contains('vest') || k == 'v' || k == 'top') {
        res.superficies['vestibular'] = col;
      } else if (k.contains('ling') ||
          k.contains('palat') ||
          k == 'l' ||
          k == 'p' ||
          k == 'bottom') {
        res.superficies['lingual'] = col;
      } else if (k.contains('mes') || k == 'm' || k == 'left') {
        res.superficies['mesial'] = col;
      } else if (k.contains('dist') || k == 'd' || k == 'right') {
        res.superficies['distal'] = col;
      } else if (k.contains('ocl') ||
          k.contains('inc') ||
          k == 'o' ||
          k == 'i' ||
          k == 'center') {
        res.superficies['oclusal'] = col;
      }
    }
  }

  static pw.Widget _buildFilaPermanente(
    List<int> q1,
    List<int> q2, {
    required bool esSuperior,
    required List<Odontograma> lista,
    HistorialPiezas? hp,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        ...q1.map(
          (fdi) => _buildPiezaGlifoCuadrado(
            fdi,
            esSuperior: esSuperior,
            lista: lista,
            hp: hp,
          ),
        ),
        pw.Container(
          width: 1.2,
          height: 26,
          color: PdfColors.grey600,
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        ),
        ...q2.map(
          (fdi) => _buildPiezaGlifoCuadrado(
            fdi,
            esSuperior: esSuperior,
            lista: lista,
            hp: hp,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFilaTemporal(
    List<int> q1,
    List<int> q2, {
    required bool esSuperior,
    required List<Odontograma> lista,
    HistorialPiezas? hp,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        ...q1.map(
          (fdi) => _buildPiezaGlifoCirculo(
            fdi,
            esSuperior: esSuperior,
            lista: lista,
            hp: hp,
          ),
        ),
        pw.Container(
          width: 1.2,
          height: 26,
          color: PdfColors.grey600,
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        ),
        ...q2.map(
          (fdi) => _buildPiezaGlifoCirculo(
            fdi,
            esSuperior: esSuperior,
            lista: lista,
            hp: hp,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPiezaGlifoCuadrado(
    int fdi, {
    required bool esSuperior,
    required List<Odontograma> lista,
    HistorialPiezas? hp,
  }) {
    final estado = _evaluarEstadoPieza(fdi, lista, hp);

    final numero = pw.Text(
      '$fdi',
      style: pw.TextStyle(
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
    );

    final glifo = pw.Container(
      width: 18,
      height: 18,
      margin: const pw.EdgeInsets.symmetric(horizontal: 1),
      child: pw.CustomPaint(
        painter: (canvas, size) {
          final stroke = PdfColors.blueGrey800;
          canvas.setLineWidth(0.5);

          final sup = estado.superficies;
          if (sup['oclusal'] != PdfColors.white) {
            canvas.setFillColor(sup['oclusal']!);
            canvas.drawRect(5, 5, 8, 8);
            canvas.fillPath();
          }
          if (sup['vestibular'] != PdfColors.white) {
            canvas.setFillColor(sup['vestibular']!);
            canvas.moveTo(0, 0);
            canvas.lineTo(size.x, 0);
            canvas.lineTo(13, 5);
            canvas.lineTo(5, 5);
            canvas.closePath();
            canvas.fillPath();
          }
          if (sup['lingual'] != PdfColors.white) {
            canvas.setFillColor(sup['lingual']!);
            canvas.moveTo(0, size.y);
            canvas.lineTo(size.x, size.y);
            canvas.lineTo(13, 13);
            canvas.lineTo(5, 13);
            canvas.closePath();
            canvas.fillPath();
          }
          if (sup['mesial'] != PdfColors.white) {
            canvas.setFillColor(sup['mesial']!);
            canvas.moveTo(0, 0);
            canvas.lineTo(5, 5);
            canvas.lineTo(5, 13);
            canvas.lineTo(0, size.y);
            canvas.closePath();
            canvas.fillPath();
          }
          if (sup['distal'] != PdfColors.white) {
            canvas.setFillColor(sup['distal']!);
            canvas.moveTo(size.x, 0);
            canvas.lineTo(13, 5);
            canvas.lineTo(13, 13);
            canvas.lineTo(size.x, size.y);
            canvas.closePath();
            canvas.fillPath();
          }

          canvas.setStrokeColor(stroke);
          canvas.drawRect(0, 0, size.x, size.y);
          canvas.strokePath();
          canvas.drawRect(5, 5, 8, 8);
          canvas.strokePath();
          canvas.drawLine(0, 0, 5, 5);
          canvas.drawLine(size.x, 0, 13, 5);
          canvas.drawLine(0, size.y, 5, 13);
          canvas.drawLine(size.x, size.y, 13, 13);
          canvas.strokePath();

          if (estado.simbolo == 'X') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setLineWidth(1.5);
            canvas.drawLine(1, 1, size.x - 1, size.y - 1);
            canvas.drawLine(size.x - 1, 1, 1, size.y - 1);
            canvas.strokePath();
          } else if (estado.simbolo == '⊙') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setFillColor(estado.colorSimbolo);
            canvas.setLineWidth(1.2);
            canvas.drawEllipse(9, 9, 6, 6);
            canvas.strokePath();
            canvas.drawEllipse(9, 9, 2, 2);
            canvas.fillPath();
          } else if (estado.simbolo == '=') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setLineWidth(1.2);
            canvas.drawLine(2, 6, size.x - 2, 6);
            canvas.drawLine(2, 12, size.x - 2, 12);
            canvas.strokePath();
          }
        },
      ),
    );

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: esSuperior ? [numero, glifo] : [glifo, numero],
    );
  }

  static pw.Widget _buildPiezaGlifoCirculo(
    int fdi, {
    required bool esSuperior,
    required List<Odontograma> lista,
    HistorialPiezas? hp,
  }) {
    final estado = _evaluarEstadoPieza(fdi, lista, hp);

    final numero = pw.Text(
      '$fdi',
      style: pw.TextStyle(
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
    );

    final glifo = pw.Container(
      width: 18,
      height: 18,
      margin: const pw.EdgeInsets.symmetric(horizontal: 1),
      child: pw.CustomPaint(
        painter: (canvas, size) {
          final stroke = PdfColors.blueGrey800;
          canvas.setLineWidth(0.5);

          final r = size.x / 2;

          if (estado.superficies['oclusal'] != PdfColors.white) {
            canvas.setFillColor(estado.superficies['oclusal']!);
            canvas.drawEllipse(r, r, r / 2, r / 2);
            canvas.fillPath();
          }

          canvas.setStrokeColor(stroke);
          canvas.drawEllipse(r, r, r, r);
          canvas.strokePath();
          canvas.drawEllipse(r, r, r / 2, r / 2);
          canvas.strokePath();
          canvas.drawLine(r - r / 2, r, 0, r);
          canvas.drawLine(r + r / 2, r, size.x, r);
          canvas.drawLine(r, r - r / 2, r, 0);
          canvas.drawLine(r, r + r / 2, r, size.y);
          canvas.strokePath();
          if (estado.simbolo == 'X') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setLineWidth(1.5);
            canvas.drawLine(2, 2, size.x - 2, size.y - 2);
            canvas.drawLine(size.x - 2, 2, 2, size.y - 2);
            canvas.strokePath();
          } else if (estado.simbolo == '⊙') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setFillColor(estado.colorSimbolo);
            canvas.setLineWidth(1.2);
            canvas.drawEllipse(r, r, 6, 6);
            canvas.strokePath();
            canvas.drawEllipse(r, r, 2, 2);
            canvas.fillPath();
          } else if (estado.simbolo == '=') {
            canvas.setStrokeColor(estado.colorSimbolo);
            canvas.setLineWidth(1.2);
            canvas.drawLine(2, 6, size.x - 2, 6);
            canvas.drawLine(2, 12, size.x - 2, 12);
            canvas.strokePath();
          }
        },
      ),
    );

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: esSuperior ? [numero, glifo] : [glifo, numero],
    );
  }

  static pw.Widget _buildLeyendaItem(PdfColor color, String texto) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 3),
        pw.Text(texto, style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  static pw.Widget _buildTablaTejidosBlandos(Map<dynamic, String> tejidos) {
    final listaTejidos = [
      'Labios',
      'Carrillos',
      'Encías',
      'Piso de Boca',
      'Lengua',
      'Paladar Duro',
      'Paladar Blando',
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _Brand.border, width: 0.7),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: const pw.BoxDecoration(
              borderRadius: pw.BorderRadius.vertical(
                top: pw.Radius.circular(6),
              ),
              color: _Brand.primary,
            ),
            child: pw.Text(
              'TEJIDOS BLANDOS',
              textAlign: pw.TextAlign.left,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(100),
              1: pw.FlexColumnWidth(),
            },
            children: listaTejidos.asMap().entries.map((entry) {
              final idx = entry.key;
              final etiqueta = entry.value;

              String? valorEncontrado;
              for (final e in tejidos.entries) {
                final claveNombre = e.key.toString().toLowerCase().replaceAll(
                  ' ',
                  '',
                );
                final etiquetaNombre = etiqueta.toLowerCase().replaceAll(
                  ' ',
                  '',
                );
                if (claveNombre.contains(etiquetaNombre)) {
                  valorEncontrado = e.value;
                  break;
                }
              }

              final textoValor =
                  (valorEncontrado != null && valorEncontrado.trim().isNotEmpty)
                  ? valorEncontrado
                  : '-';
              final esUltimo = idx == listaTejidos.length - 1;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: idx % 2 == 1 ? _Brand.accentSoft : PdfColors.white,
                  border: esUltimo
                      ? null
                      : const pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: pw.Text(
                      etiqueta,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _Brand.ink,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: pw.Text(
                      textoValor,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: textoValor == '-'
                            ? pw.FontStyle.italic
                            : pw.FontStyle.normal,
                        color: textoValor == '-'
                            ? PdfColors.grey600
                            : _Brand.ink,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildSeccionConsultas(
    List<Consulta> consultas, {
    pw.MemoryImage? logoImage,
  }) => [
    _clinicalSectionHeader(
      'CONSULTAS CLÍNICAS',
      consultas.length,
      logoImage: logoImage,
    ),
    pw.SizedBox(height: 4),
    for (final consulta in consultas)
      ..._clinicalCards(
        '${fechaLargaEs(consulta.fecha)} · ${_referenciaConsulta(consulta)} · '
        '${consulta.finalizada ? 'Finalizada' : 'En proceso'}',
        [
          if (_textoNoVacio(consulta.motivoConsulta) case final motivo?)
            'Motivo: $motivo',
          if (_textoNoVacio(consulta.notas) case final notas?) 'Notas: $notas',
          if (consulta.tempCondiciones.isNotEmpty)
            'Indicaciones/condiciones del día: ${consulta.tempCondiciones.join(', ')}',
          if (_signosVitales(consulta) case final signos?)
            'Signos vitales: $signos',
          if (_textoNoVacio(consulta.motivoConsulta) == null &&
              _textoNoVacio(consulta.notas) == null &&
              consulta.tempCondiciones.isEmpty &&
              _signosVitales(consulta) == null)
            'Sin notas clínicas.',
        ].join('\n'),
      ),
  ];

  static pw.Widget _clinicalSectionHeader(
    String titulo,
    int cantidad, {
    pw.MemoryImage? logoImage,
  }) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
    decoration: const pw.BoxDecoration(
      borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
      color: _Brand.primary,
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            _toothBadge(
              size: 16,
              bg: PdfColors.white,
              tooth: _Brand.primary,
              logoImage: logoImage,
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        pw.Text(
          '$cantidad registro(s)',
          style: pw.TextStyle(
            fontSize: 6.8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ],
    ),
  );

  static List<pw.Widget> _buildSeccionEvaluaciones(
    List<Consulta> evaluaciones, {
    pw.MemoryImage? logoImage,
  }) {
    final widgets = <pw.Widget>[
      _clinicalSectionHeader(
        'EVALUACIONES CLÍNICAS',
        evaluaciones.length,
        logoImage: logoImage,
      ),
      pw.SizedBox(height: 4),
    ];
    for (final evaluacion in evaluaciones) {
      final hallazgos = <String>[];
      for (final diente
          in evaluacion.odontograma?.dientes ?? const <Diente>[]) {
        for (final diagnostico in diente.diagnosis) {
          final nombre =
              _textoNoVacio(diagnostico.nombreDiagnostico) ?? 'Diagnóstico';
          final superficie = diagnostico.superficie == null
              ? ''
              : ' · ${_labelEnum(diagnostico.superficie!.name)}';
          final notas = diagnostico.notas.trim().isEmpty
              ? ''
              : ' · ${diagnostico.notas.trim()}';
          hallazgos.add(
            'Pieza ${diente.fdiCode}: $nombre$superficie$notas'
            '${diagnostico.estaAnulado ? ' · ANULADO' : ''}',
          );
        }
      }
      for (final diagnostico in evaluacion.diagnosticosGenerales) {
        final nombre =
            _textoNoVacio(diagnostico.nombreDiagnostico) ?? 'Diagnóstico';
        final notas = diagnostico.notas.trim().isEmpty
            ? ''
            : ' · ${diagnostico.notas.trim()}';
        hallazgos.add(
          'Sin pieza (general): $nombre$notas'
          '${diagnostico.estaAnulado ? ' · ANULADO' : ''}',
        );
      }
      final partes = <String>[
        if (_textoNoVacio(evaluacion.motivoConsulta) case final motivo?)
          'Motivo: $motivo',
        if (_textoNoVacio(evaluacion.notas) case final notas?)
          'Resumen: $notas',
        if (_signosVitales(evaluacion) case final signos?)
          'Signos vitales: $signos',
        if (hallazgos.isEmpty)
          'Sin hallazgos odontológicos registrados.'
        else
          'Hallazgos:\n${hallazgos.join('\n')}',
      ];
      widgets.addAll(
        _clinicalCards(
          '${fechaLargaEs(evaluacion.fecha)} · ${_referenciaConsulta(evaluacion)}',
          partes.join('\n'),
        ),
      );
    }
    return widgets;
  }

  static List<_TratamientoExpediente> _tratamientosDe(
    List<Consulta> consultas,
  ) {
    final resultados = <_TratamientoExpediente>[];
    final vistos = <String>{};
    for (final consulta in consultas) {
      for (final diente in consulta.odontograma?.dientes ?? const <Diente>[]) {
        for (final tratamiento in diente.tratamientos) {
          final clave =
              tratamiento.id ??
              '${consulta.id}|${diente.fdiCode}|${tratamiento.tratamientoId}|'
                  '${tratamiento.fechaEjecucion ?? tratamiento.fechaAplicacion}';
          if (vistos.add(clave)) {
            resultados.add(
              _TratamientoExpediente(consulta, diente, tratamiento),
            );
          }
        }
      }
      // Lo ejecutado sin pieza cuelga de la consulta, no de un diente.
      for (final tratamiento in consulta.tratamientosGenerales) {
        final clave =
            tratamiento.id ??
            '${consulta.id}|general|${tratamiento.tratamientoId}|'
                '${tratamiento.fechaEjecucion ?? tratamiento.fechaAplicacion}';
        if (vistos.add(clave)) {
          resultados.add(_TratamientoExpediente(consulta, null, tratamiento));
        }
      }
    }
    return resultados;
  }

  static List<pw.Widget> _buildSeccionTratamientos(
    List<Consulta> consultas, {
    pw.MemoryImage? logoImage,
  }) {
    final tratamientos = _tratamientosDe(consultas);
    return [
      _clinicalSectionHeader(
        'TRATAMIENTOS REALIZADOS',
        tratamientos.length,
        logoImage: logoImage,
      ),
      pw.SizedBox(height: 4),
      for (final item in tratamientos)
        ..._clinicalCards(
          '${fechaLargaEs(item.fecha)} · ${item.referenciaPieza}',
          [
            item.tratamiento.nombreTratamiento ?? 'Tratamiento',
            'Estado: ${item.tratamiento.estaAnulado ? 'Anulado' : _labelEnum(item.tratamiento.estado.dbValue)}',
            if (item.tratamiento.superficie != null)
              'Superficie: ${_labelEnum(item.tratamiento.superficie!.name)}',
            if (_textoNoVacio(item.tratamiento.notas) case final notas?)
              'Notas: $notas',
            if (_textoNoVacio(item.tratamiento.justificacionNoPlanificada)
                case final justificacion?)
              'Justificación no planificada: $justificacion',
            'Consulta: ${_referenciaConsulta(item.consulta)}',
          ].join('\n'),
        ),
    ];
  }

  static List<pw.Widget> _buildSeccionRecetas(
    List<Consulta> consultas, {
    pw.MemoryImage? logoImage,
  }) {
    final recetas = <({Consulta consulta, Receta receta})>[
      for (final consulta in consultas)
        for (final receta in consulta.recetas)
          (consulta: consulta, receta: receta),
    ];
    return [
      _clinicalSectionHeader(
        'RECETAS E INDICACIONES',
        recetas.length,
        logoImage: logoImage,
      ),
      pw.SizedBox(height: 4),
      for (final item in recetas) ...[
        for (final m in item.receta.items)
          ..._clinicalCards(
            '${fechaLargaEs(item.receta.fechaEmision)} · ${m.nombreMedicamento}'
            '${m.presentacionConcentracion.isNotEmpty ? ' (${m.presentacionConcentracion})' : ''}',
            [
              'Dosis: ${m.dosis}',
              if (m.viaAdministracion.isNotEmpty) 'Vía: ${m.viaAdministracion}',
              'Frecuencia: ${m.frecuencia}',
              'Duración: ${m.duracion}',
              if (m.cantidadIndicada.isNotEmpty)
                'Cantidad: ${m.cantidadIndicada}',
              if (_textoNoVacio(m.indicacionesEspecificas) case final ind?)
                'Indicaciones específicas: $ind',
              if (_textoNoVacio(item.receta.indicacionesGenerales)
                  case final gen?)
                'Indicaciones generales: $gen',
              if (_textoNoVacio(item.receta.justificacionContraindicaciones)
                  case final just?)
                'Justificación médica: $just',
              'Código de Receta: ${item.receta.codigoReceta.isNotEmpty ? item.receta.codigoReceta : "S/N"}',
              'Consulta: ${_referenciaConsulta(item.consulta)}',
            ].join('\n'),
          ),
      ],
    ];
  }

  static List<pw.Widget> _buildSeccionDocumentos(
    List<Consulta> consultas, {
    pw.MemoryImage? logoImage,
  }) {
    final documentos = [
      for (final consulta in consultas)
        for (final documento in consulta.documentosClinicos)
          (consulta: consulta, documento: documento),
    ];
    return [
      _clinicalSectionHeader(
        'DOCUMENTOS CLÍNICOS REFERENCIADOS',
        documentos.length,
        logoImage: logoImage,
      ),
      pw.SizedBox(height: 4),
      for (final item in documentos)
        ..._clinicalCards(
          '${fechaLargaEs(item.documento.fechaCreacion)} · '
          '${_labelEnum(item.documento.tipoDocumento.name)}',
          [
            item.documento.descripcion.trim().isEmpty
                ? 'Sin descripción.'
                : item.documento.descripcion.trim(),
            'Consulta: ${_referenciaConsulta(item.consulta)}',
            'Referencia interna: ${_referenciaDocumento(item.documento.id)}',
          ].join('\n'),
        ),
    ];
  }

  static List<pw.Widget> _clinicalCards(String titulo, String cuerpo) {
    final partes = _partirTexto(cuerpo, 1200);
    return [
      for (var i = 0; i < partes.length; i++)
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.all(8),
          decoration: _cardDecoration(),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                i == 0 ? titulo : '$titulo (continuación)',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _Brand.primaryDark,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                partes[i],
                style: const pw.TextStyle(fontSize: 7.5, height: 1.3),
              ),
            ],
          ),
        ),
    ];
  }

  static List<String> _partirTexto(String texto, int maximo) {
    if (texto.length <= maximo) return [texto];
    final partes = <String>[];
    var restante = texto;
    while (restante.length > maximo) {
      var corte = restante.lastIndexOf(RegExp(r'\s'), maximo);
      if (corte < maximo ~/ 2) corte = maximo;
      partes.add(restante.substring(0, corte).trimRight());
      restante = restante.substring(corte).trimLeft();
    }
    if (restante.isNotEmpty) partes.add(restante);
    return partes;
  }

  static String? _textoNoVacio(String? valor) {
    final limpio = valor?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static String _referenciaConsulta(Consulta consulta) {
    final id = consulta.id?.trim() ?? '';
    if (id.isEmpty) return 'S/N';
    return '#${id.substring(0, id.length.clamp(0, 8)).toUpperCase()}';
  }

  static String _referenciaDocumento(String? id) {
    final limpio = id?.trim() ?? '';
    if (limpio.isEmpty) return 'S/N';
    return '#${limpio.substring(0, limpio.length.clamp(0, 8)).toUpperCase()}';
  }

  static String _labelEnum(String valor) {
    final normalizado = valor.replaceAll('_', ' ').trim();
    if (normalizado.isEmpty) return '';
    return '${normalizado[0].toUpperCase()}${normalizado.substring(1)}';
  }

  static String? _signosVitales(Consulta consulta) {
    final signos = consulta.signosVitales;
    if (signos == null || signos.estaVacia) return null;
    return [
      if (signos.presionSistolica != null || signos.presionDiastolica != null)
        'PA ${signos.presionSistolica ?? '-'}/${signos.presionDiastolica ?? '-'} mmHg',
      if (signos.pulso != null) 'Pulso ${signos.pulso} lpm',
      if (signos.temperatura != null) 'Temp. ${signos.temperatura} °C',
      if (signos.saturacionO2 != null) 'SpO2 ${signos.saturacionO2}%',
    ].join(' · ');
  }
}

class _TratamientoExpediente {
  final Consulta consulta;

  /// `null` cuando el tratamiento no corresponde a una pieza concreta
  /// (profilaxis, fluorización de arcada). La base los guarda con
  /// `diente_id NULL` y antes el expediente no los recogía (defecto D5).
  final Diente? diente;
  final TratamientoAplicado tratamiento;

  const _TratamientoExpediente(this.consulta, this.diente, this.tratamiento);

  String get referenciaPieza =>
      diente == null ? 'Sin pieza (general)' : 'Pieza ${diente!.fdiCode}';

  DateTime get fecha =>
      tratamiento.fechaEjecucion ??
      tratamiento.fechaAplicacion ??
      consulta.fecha;
}

class _EstadoPiezaResultado {
  String? simbolo;
  PdfColor colorSimbolo = PdfColors.black;
  Map<String, PdfColor> superficies = {
    'vestibular': PdfColors.white,
    'lingual': PdfColors.white,
    'mesial': PdfColors.white,
    'distal': PdfColors.white,
    'oclusal': PdfColors.white,
  };
}
