import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';

class _Brand {
  static const primary = PdfColor.fromInt(0xFF2563EB);
  static const primaryDark = PdfColor.fromInt(0xFF1D4ED8);
  static const accent = PdfColor.fromInt(0xFF3B82F6);
  static const accentSoft = PdfColor.fromInt(0xFFEFF6FF);
  static const surface = PdfColor.fromInt(0xFFFFFFFF);
  static const ink = PdfColor.fromInt(0xFF0B0808);
  static const muted = PdfColor.fromInt(0xFF0B0808);
  static const border = PdfColor.fromInt(0xFFE2E8F0);
}

class ExpedientePdfBuilder {
  static Future<Uint8List> buildPdf({
    required Paciente paciente,
    required ExpedientePrintOptions options,
    Odontograma? odontograma,
    List<Odontograma> historialOdontogramas = const [],
    List<dynamic> evaluaciones = const [],
    List<dynamic> tratamientos = const [],
    List<dynamic> recetas = const [],
    HistorialPiezas? historialPiezas,
  }) async {
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
    );

    final pdf = pw.Document(theme: theme);
    final now = DateTime.now();
    final fechaGeneracion = fechaLargaEs(now);
    final record = paciente.record;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(32, 0, 32, 28),
        header: (context) => _buildHeader(
          paciente,
          fechaGeneracion,
          isFirstPage: context.pageNumber == 1,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 14),

          _buildSeccionDatosPaciente(paciente),
          pw.SizedBox(height: 10),

          _buildSeccionRecordClinico(paciente),
          pw.SizedBox(height: 10),

          _buildSeccionCondiciones(paciente),
          pw.SizedBox(height: 10),

          if (options.incluirOdontograma) ...[
            _buildSeccionOdontodiagramaOficial(
              odontograma,
              historialOdontogramas: historialOdontogramas,
              hp: historialPiezas,
            ),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirConsultas && record.consultas.isNotEmpty) ...[
            _buildSeccionConsultas(paciente),
            pw.SizedBox(height: 10),
          ],

          if (options.incluirEvaluaciones && evaluaciones.isNotEmpty) ...[
            _buildSeccionEvaluaciones(evaluaciones),
            pw.SizedBox(height: 10),
          ],
          if (options.incluirTratamientos && tratamientos.isNotEmpty) ...[
            _buildSeccionTratamientos(tratamientos),
            pw.SizedBox(height: 10),
          ],
          if (options.incluirRecetas && recetas.isNotEmpty) ...[
            _buildSeccionRecetas(recetas),
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
  }) {
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
                    size: 30,
                    bg: PdfColors.white,
                    tooth: _Brand.primary,
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
                      p.govID,
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

  static pw.Widget _buildFooter(pw.Context context) {
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
              pw.Expanded(child: _dato('Cédula / Documento', p.govID)),
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

  static pw.Widget _buildSeccionCondiciones(Paciente p) {
    final condiciones = p.record.conditions;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('3', 'CONDICIONES MÉDICAS Y ALERGIAS'),
          pw.SizedBox(height: 8),
          if (condiciones.isEmpty)
            pw.Text(
              'Sin condiciones médicas registradas.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            )
          else
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: condiciones
                  .map(
                    (c) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _Brand.accentSoft,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _Brand.accent, width: 0.6),
                      ),
                      child: pw.Text(
                        c.nombre,
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: _Brand.primaryDark,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
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
                    _buildLeyendaItem(PdfColors.blueGrey800, 'Ejecutado'),
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

  static Map<String, dynamic>? _objToMap(dynamic obj) {
    if (obj == null) return null;
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) return Map<String, dynamic>.from(obj);
    try {
      final res = obj.toJson();
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    try {
      final res = obj.toMap();
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return null;
  }

  static _EstadoPiezaResultado _evaluarEstadoPieza(
    int fdi,
    List<Odontograma> lista,
    HistorialPiezas? hp,
  ) {
    final res = _EstadoPiezaResultado();
    final fdiStr = '$fdi';
    if (hp != null) {
      final mapHp = _objToMap(hp);
      if (mapHp != null) {
        final piezasList = mapHp['piezas'] ?? mapHp['historial'] ?? [];
        if (piezasList is Iterable) {
          for (final p in piezasList) {
            final pMap = _objToMap(p);
            if (pMap != null &&
                '${pMap['fdiCode'] ?? pMap['fdi_code'] ?? pMap['fdi'] ?? pMap['numero']}' ==
                    fdiStr) {
              _procesarRelacionesDePieza(pMap, res);
              return res;
            }
          }
        }
      }
    }

    for (final o in lista) {
      if (o == null) continue;
      final oMap = _objToMap(o);
      if (oMap == null) continue;

      final dientesList = oMap['dientes'] ?? oMap['piezas'] ?? [];

      if (dientesList is Iterable) {
        for (final diente in dientesList) {
          final dMap = _objToMap(diente);
          if (dMap != null &&
              '${dMap['fdi_code'] ?? dMap['fdiCode'] ?? dMap['numero']}' ==
                  fdiStr) {
            _procesarRelacionesDePieza(dMap, res);
            break;
          }
        }
      }
    }

    return res;
  }

  static void _procesarRelacionesDePieza(
    Map<String, dynamic> pMap,
    _EstadoPiezaResultado res,
  ) {
    if (pMap['esta_ausente'] == true || pMap['estaAusente'] == true) {
      res.simbolo = 'X';
      res.colorSimbolo = PdfColors.red800;
    }

    final diagnosticos =
        pMap['diagnosis'] ??
        pMap['diagnosticos'] ??
        pMap['diagnosticos_aplicados'];
    if (diagnosticos is Iterable) {
      for (final d in diagnosticos) {
        final dMap = _objToMap(d);
        if (dMap != null)
          _procesarHallazgoRelacional(dMap, res, esDiagnostico: true);
      }
    }

    final tratamientos = pMap['tratamientos'] ?? pMap['tratamientos_aplicados'];
    if (tratamientos is Iterable) {
      for (final t in tratamientos) {
        final tMap = _objToMap(t);
        if (tMap != null)
          _procesarHallazgoRelacional(tMap, res, esDiagnostico: false);
      }
    }
  }

  static void _procesarHallazgoRelacional(
    Map<String, dynamic> map,
    _EstadoPiezaResultado res, {
    required bool esDiagnostico,
  }) {
    // Extraer el nombre del tratamiento o diagnóstico de la relación anidada.
    // Ejemplo de supabase: map['tratamiento']['nombre'] o map['diagnosis']['nombre']
    String nombre = '${map['nombre'] ?? ''}';

    if (nombre.isEmpty && map['diagnosis'] is Map) {
      nombre = '${_objToMap(map['diagnosis'])?['nombre'] ?? ''}';
    }
    if (nombre.isEmpty && map['tratamiento'] is Map) {
      nombre = '${_objToMap(map['tratamiento'])?['nombre'] ?? ''}';
    }
    if (nombre.isEmpty) {
      nombre = esDiagnostico ? 'caries' : 'restauración';
    }

    final estadoStr = nombre.toLowerCase();

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

    final superficie = map['superficie'];
    if (superficie is String && superficie.isNotEmpty) {
      _aplicarColorSuperficie(superficie, estadoStr, res);
    } else {
      _aplicarColorSuperficie('oclusal', estadoStr, res);
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
    } else if (v.contains('restaurad') ||
        v.contains('restaura') ||
        v.contains('azul') ||
        v.contains('resina') ||
        v.contains('amalgama') ||
        v.contains('restauración')) {
      col = PdfColors.blue;
    }

    if (col != PdfColors.white) {
      if (k.contains('vest') || k == 'v' || k == 'top')
        res.superficies['vestibular'] = col;
      else if (k.contains('ling') ||
          k.contains('palat') ||
          k == 'l' ||
          k == 'p' ||
          k == 'bottom')
        res.superficies['lingual'] = col;
      else if (k.contains('mes') || k == 'm' || k == 'left')
        res.superficies['mesial'] = col;
      else if (k.contains('dist') || k == 'd' || k == 'right')
        res.superficies['distal'] = col;
      else if (k.contains('ocl') ||
          k.contains('inc') ||
          k == 'o' ||
          k == 'i' ||
          k == 'center')
        res.superficies['oclusal'] = col;
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
                  : '—';
              final esUltimo = idx == listaTejidos.length - 1;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: idx % 2 == 1 ? _Brand.surface : PdfColors.white,
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
                        fontStyle: textoValor == '—'
                            ? pw.FontStyle.italic
                            : pw.FontStyle.normal,
                        color: textoValor == '—'
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

  static pw.Widget _buildSeccionConsultas(Paciente p) {
    final consultas = p.record.consultas;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
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
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'HISTORIAL DE CONSULTAS Y CITAS',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: _Brand.primaryDark,
                  borderRadius: pw.BorderRadius.circular(7),
                ),
                child: pw.Text(
                  '${consultas.length} registro(s)',
                  style: pw.TextStyle(
                    fontSize: 6.8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.Table(
          border: const pw.TableBorder(
            left: pw.BorderSide(color: _Brand.border, width: 0.7),
            right: pw.BorderSide(color: _Brand.border, width: 0.7),
            bottom: pw.BorderSide(color: _Brand.border, width: 0.7),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.3),
            3: pw.FlexColumnWidth(3.0),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: _Brand.accentSoft,
                border: pw.Border(
                  bottom: pw.BorderSide(color: _Brand.border, width: 0.7),
                ),
              ),
              children: [
                _thConsulta('FECHA'),
                _thConsulta('CÓDIGO REF.'),
                _thConsulta('ESTADO'),
                _thConsulta('NOTAS DE LA CONSULTA'),
              ],
            ),

            ...consultas.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;

              final rawId = c.id ?? '';
              final shortId = rawId.length >= 8
                  ? '#${rawId.substring(0, 8).toUpperCase()}'
                  : (rawId.isNotEmpty ? '#$rawId' : 'S/N');

              final esUltimo = idx == consultas.length - 1;
              final estadoStr = c.finalizada
                  ? 'Finalizada'
                  : (c.finalizada == false ? 'Pendiente' : 'En Proceso');

              final textoNotas = (c.notas != null && c.notas!.trim().isNotEmpty)
                  ? c.notas!.trim()
                  : '—';

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: idx % 2 == 1 ? _Brand.surface : PdfColors.white,
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
                      vertical: 5,
                    ),
                    child: pw.Text(
                      fechaLargaEs(c.fecha),
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      shortId,
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _Brand.primary,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: _estadoBadge(estadoStr, c.finalizada),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      textoNotas,
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontStyle: textoNotas == '—'
                            ? pw.FontStyle.italic
                            : pw.FontStyle.normal,
                        color: textoNotas == '—'
                            ? PdfColors.grey600
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _thConsulta(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _Brand.primaryDark,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.Widget _estadoBadge(String estado, bool? finalizada) {
    final color = finalizada == true
        ? PdfColors.green700
        : (finalizada == false ? PdfColors.orange800 : _Brand.muted);
    final bg = finalizada == true
        ? const PdfColor.fromInt(0xFFE6F6EC)
        : (finalizada == false
              ? const PdfColor.fromInt(0xFFFCEFDD)
              : _Brand.accentSoft);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        estado,
        style: pw.TextStyle(
          fontSize: 6.8,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildListaSeccion(String titulo, List<dynamic> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _toothBadge(size: 15),
              pw.SizedBox(width: 6),
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _Brand.primaryDark,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          ...items.map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(top: 3, right: 5),
                    decoration: const pw.BoxDecoration(
                      color: _Brand.accent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      e.toString(),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSeccionEvaluaciones(List<dynamic> evaluaciones) =>
      _buildListaSeccion('EVALUACIONES CLÍNICAS', evaluaciones);

  static pw.Widget _buildSeccionTratamientos(List<dynamic> tratamientos) =>
      _buildListaSeccion('TRATAMIENTOS APLICADOS', tratamientos);

  static pw.Widget _buildSeccionRecetas(List<dynamic> recetas) =>
      _buildListaSeccion('RECETAS PRESCRITAS', recetas);
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
