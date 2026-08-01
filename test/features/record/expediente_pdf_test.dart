import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/record_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/helpers/expediente_pdf_builder.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/widgets/generar_expediente_modal.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

const _pacienteId = '11111111-1111-1111-1111-111111111111';

Paciente _pacienteCompleto({List<Consulta>? consultas}) {
  final condicion = Condicion(
    id: 'condicion-hipertension',
    nombre: 'Hipertension controlada',
    tipo: TipoCondicion.patologica,
    categoria: CategoriaCondicion.cronica,
  );
  final diagnostico = DiagnosticoAplicado(
    id: 'diagnostico-1',
    diagnosisId: 'caries',
    severidad: SeveridadDiagnosis.moderada,
    fechaAplicacion: DateTime(2026, 7, 20),
    notas: 'Lesion oclusal',
    nombreDiagnostico: 'Caries dental',
    superficie: TipoSuperficie.oclusal,
  );
  final tratamiento = TratamientoAplicado(
    id: 'tratamiento-1',
    tratamientoId: 'resina',
    esContinuo: false,
    estaTerminado: true,
    nombreTratamiento: 'Restauracion en resina',
    superficie: TipoSuperficie.oclusal,
    precioAplicado: 987654,
    notas: 'Sin complicaciones',
    fechaEjecucion: DateTime(2026, 7, 21),
  );
  final odontograma = Odontograma(
    id: 'odontograma-1',
    consultaId: 'consulta-12345678',
    dientes: [
      Diente(
        id: 'diente-1',
        odontogramaId: 'odontograma-1',
        superficies: const [],
        diagnosis: [diagnostico],
        tratamientos: [tratamiento],
        fdiCode: 16,
      ),
    ],
  );
  final historial =
      consultas ??
      [
        Consulta(
          id: 'evaluacion-12345678',
          pacienteId: _pacienteId,
          doctorId: 'doctor-1',
          fecha: DateTime(2026, 7, 20),
          tipoAtencion: TipoAtencionClinica.evaluacion,
          motivoConsulta: 'Revision inicial',
          notas: 'Evaluacion integral',
          odontograma: odontograma,
          signosVitales: SignosVitales.valores(
            presionSistolica: 120,
            presionDiastolica: 80,
          ),
          finalizada: true,
        ),
        Consulta(
          id: 'consulta-12345678',
          pacienteId: _pacienteId,
          doctorId: 'doctor-1',
          fecha: DateTime(2026, 7, 21),
          motivoConsulta: 'Dolor al masticar',
          notas: 'Control en siete dias',
          tempCondiciones: const ['Evitar alimentos duros'],
          odontograma: odontograma,
          recetas: [
            Receta(
              id: 'receta-1',
              codigoReceta: 'RX-2026-00001',
              consultaId: 'consulta-12345678',
              pacienteId: _pacienteId,
              doctorId: 'doctor-1',
              fechaEmision: DateTime(2026, 7, 21),
              items: const [
                ItemReceta(
                  nombreMedicamento: 'Amoxicilina',
                  medicamentoId: 'medicina-1',
                  dosis: '500 mg',
                  frecuencia: 'Cada 8 horas',
                  duracion: '7 dias',
                  indicacionesEspecificas: 'Tomar con alimentos',
                ),
              ],
            ),
          ],
          documentosClinicos: [
            DocumentoClinico(
              id: 'documento-87654321',
              pacienteId: _pacienteId,
              consultaId: 'consulta-12345678',
              descripcion: 'Radiografia periapical',
              tipoDocumento: TipoDocumento.radiografia,
              fechaCreacion: DateTime(2026, 7, 21),
              urlArchivo:
                  'https://storage.invalid/private?token=SECRETO-NO-IMPRIMIR',
            ),
          ],
          finalizada: true,
          tienePreFactura: true,
        ),
      ];

  return Paciente(
    id: _pacienteId,
    nombre: 'Ana',
    apellido: 'Rodriguez',
    birthDate: DateTime(1990, 5, 12),
    govID: '001-1234567-8',
    contactos: [
      Contacto(
        email: 'ana@example.com',
        numeroTelefono: '809-555-0101',
        direccion: 'Santo Domingo',
      ),
      Contacto(
        email: '',
        numeroTelefono: '809-555-0199',
        direccion: '',
        esEmergencia: true,
      ),
    ],
    estatus: EstatusPersona.activo,
    genero: Genero.femenino,
    record: Record(
      id: 'record-1',
      pacienteId: _pacienteId,
      tipoSangre: TipoSangre.oPositivo,
      consultas: historial,
      condiciones: [condicion],
      detallesCondiciones: [
        RecordCondicion(
          id: 'detalle-1',
          recordId: 'record-1',
          condicionId: condicion.id!,
          condicion: condicion,
          medicamento: 'Losartan',
          dosis: '50 mg',
          frecuencia: 'Cada 24 horas',
          notas: 'Vigilar presion antes del procedimiento',
          activo: true,
        ),
      ],
      cirugiasPrevias: const ['Apendicectomia'],
      historialFamiliar: 'Diabetes materna',
    ),
    trabajo: 'Docente',
    referencia: 'Dra. Perez',
    citas: const [],
    tipoPaciente: TipoPaciente.integrado,
    peso: 64.5,
    altura: 165,
  );
}

void main() {
  _pruebasOdontodiagrama();
  test(
    'genera el expediente completo, paginado y sin datos financieros',
    () async {
      final paciente = _pacienteCompleto();
      final odontograma = paciente.record.consultas.first.odontograma;

      final bytes = await ExpedientePdfBuilder.buildPdf(
        paciente: paciente,
        options: const ExpedientePrintOptions(incluirOdontograma: true),
        odontograma: odontograma,
        historialOdontogramas: [odontograma!],
        generadoEn: DateTime(2026, 7, 26),
        theme: pw.ThemeData(),
        compress: false,
      );
      final raw = latin1.decode(bytes, allowInvalid: true);

      expect(bytes.length, greaterThan(5000));
      expect(raw, startsWith('%PDF-'));
      expect(raw, contains('(EVALUACIONES)'));
      expect(raw, contains('(CONSULTAS)'));
      expect(raw, contains('(TRATAMIENTOS)'));
      expect(raw, contains('(RECETAS)'));
      expect(raw, contains('(DOCUMENTOS)'));
      expect(raw, contains('Losartan'));
      expect(raw, contains('(26)'));
      expect(raw, contains('(julio)'));
      expect(raw, isNot(contains('SECRETO-NO-IMPRIMIR')));
      expect(raw, isNot(contains('987654')));
      expect(raw, isNot(contains('PRE-FACTURA')));
    },
  );

  test('soporta un historial largo en varias paginas', () async {
    final consultas = List.generate(
      180,
      (i) => Consulta(
        id: 'consulta-${i.toString().padLeft(8, '0')}',
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        fecha: DateTime(2026, 7, 25).subtract(Duration(days: i)),
        motivoConsulta: 'Seguimiento clinico $i',
        notas: List.filled(60, 'observacion').join(' '),
        finalizada: true,
      ),
    );

    final bytes = await ExpedientePdfBuilder.buildPdf(
      paciente: _pacienteCompleto(consultas: consultas),
      options: const ExpedientePrintOptions(incluirOdontograma: false),
      generadoEn: DateTime(2026, 7, 26),
      theme: pw.ThemeData(),
      compress: false,
    );
    final raw = latin1.decode(bytes, allowInvalid: true);
    final paginas = RegExp(r'/Type\s*/Page\b').allMatches(raw).length;

    expect(paginas, greaterThan(20));
  });

  testWidgets('ofrece exactamente expediente con o sin odontograma', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GenerarExpedienteModal(paciente: _pacienteCompleto()),
        ),
      ),
    );

    expect(find.text('Expediente con odontograma'), findsOneWidget);
    expect(find.text('Expediente sin odontograma'), findsOneWidget);
    expect(find.textContaining('Consulta Específica'), findsNothing);
    expect(find.byKey(const Key('generar_expediente_pdf')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expediente_sin_odontograma')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

/// Defecto D6a (QA 1 ago 2026). El odontodiagrama del expediente **nunca**
/// pintó una marca: se armaba con un `_objToMap` que probaba `toJson()` sobre
/// las entidades, y `OdontogramaModel.toJson()` no emite `dientes` mientras que
/// `HistorialPiezas` ni siquiera tiene `toJson`. Las 52 piezas evaluaban a
/// vacío siempre. Al ser todo `dynamic`, ningún test lo delataba.
///
/// La prueba es diferencial a propósito: los símbolos y los colores del
/// diagrama son operadores de dibujo, no texto, así que lo que se afirma es que
/// una boca con hallazgos **no** produce el mismo diagrama que una boca sana.
void _pruebasOdontodiagrama() {
  Paciente pacienteConOdontograma(List<Diente> dientes) {
    final odontograma = Odontograma(
      id: 'odontograma-marcas',
      consultaId: 'consulta-marcas',
      dientes: dientes,
    );
    final consulta = Consulta(
      id: 'consulta-marcas',
      pacienteId: _pacienteId,
      doctorId: 'doctor-1',
      fecha: DateTime(2026, 7, 20),
      tipoAtencion: TipoAtencionClinica.consulta,
      motivoConsulta: 'Revision',
      odontograma: odontograma,
    );
    return Paciente(
      id: _pacienteId,
      nombre: 'Zoila',
      apellido: 'Perez',
      birthDate: DateTime(1995, 5, 5),
      govID: '001-0000000-0',
      contactos: const <Contacto>[],
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      tipoPaciente: TipoPaciente.integrado,
      trabajo: '',
      referencia: '',
      record: Record(
        pacienteId: _pacienteId,
        tipoSangre: TipoSangre.oPositivo,
        condiciones: const <Condicion>[],
        cirugiasPrevias: const [],
        historialFamiliar: '',
        consultas: [consulta],
      ),
      citas: const [],
    );
  }

  Future<Uint8List> pdfDe(Paciente paciente) async {
    final odontograma = paciente.record.consultas.first.odontograma!;
    return ExpedientePdfBuilder.buildPdf(
      paciente: paciente,
      options: const ExpedientePrintOptions(incluirOdontograma: true),
      odontograma: odontograma,
      historialOdontogramas: [odontograma],
      generadoEn: DateTime(2026, 7, 26),
      theme: pw.ThemeData(),
      compress: false,
    );
  }

  test('el odontodiagrama pinta las marcas de las piezas', () async {
    final sano = pacienteConOdontograma([
      Diente(
        id: 'diente-sano',
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 16,
      ),
    ]);
    final conCaries = pacienteConOdontograma([
      Diente(
        id: 'diente-caries',
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 16,
        diagnosis: [
          DiagnosticoAplicado(
            id: 'dx-1',
            diagnosisId: 'caries',
            severidad: SeveridadDiagnosis.moderada,
            fechaAplicacion: DateTime(2026, 7, 20),
            notas: '',
            nombreDiagnostico: 'Caries dental',
            superficie: TipoSuperficie.oclusal,
          ),
        ],
      ),
    ]);

    final bytesSano = await pdfDe(sano);
    final bytesConCaries = await pdfDe(conCaries);

    expect(
      bytesConCaries.length,
      isNot(bytesSano.length),
      reason:
          'una caries oclusal en la pieza 16 debe cambiar el diagrama; si los '
          'dos PDF son idénticos es que el odontodiagrama sigue vacío',
    );
  });

  test('una pieza ausente estampa su símbolo', () async {
    final sano = pacienteConOdontograma([
      Diente(
        id: 'diente-presente',
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 26,
      ),
    ]);
    final ausente = pacienteConOdontograma([
      Diente(
        id: 'diente-ausente',
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 26,
        estaAusente: true,
      ),
    ]);

    expect((await pdfDe(ausente)).length, isNot((await pdfDe(sano)).length));
  });

  Future<Uint8List> soloDiagrama(Paciente paciente) async {
    final odontograma = paciente.record.consultas.first.odontograma!;
    return ExpedientePdfBuilder.buildPdf(
      paciente: paciente,
      options: const ExpedientePrintOptions(
        incluirOdontograma: true,
        incluirEvaluaciones: false,
        incluirConsultas: false,
        incluirTratamientos: false,
        incluirRecetas: false,
        incluirDocumentosReferenciados: false,
      ),
      odontograma: odontograma,
      historialOdontogramas: [odontograma],
      generadoEn: DateTime(2026, 7, 26),
      theme: pw.ThemeData(),
      compress: false,
    );
  }

  test('el PDF pinta un procedimiento desconocido en su superficie', () async {
    final sano = pacienteConOdontograma([
      Diente(
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 16,
      ),
    ]);
    final tratado = pacienteConOdontograma([
      Diente(
        odontogramaId: 'odontograma-marcas',
        superficies: const [],
        fdiCode: 16,
        tratamientos: [
          TratamientoAplicado(
            tratamientoId: 'procedimiento-sin-clave',
            esContinuo: false,
            estaTerminado: true,
            nombreTratamiento: 'Procedimiento especial',
            superficie: TipoSuperficie.mesial,
          ),
        ],
      ),
    ]);

    expect(
      (await soloDiagrama(tratado)).length,
      isNot((await soloDiagrama(sano)).length),
      reason: 'todo procedimiento por superficie debe alterar el diagrama',
    );
  });

  test('el PDF pinta la pieza completa y no solo su centro', () async {
    Paciente conTratamiento(TipoSuperficie? superficie) =>
        pacienteConOdontograma([
          Diente(
            odontogramaId: 'odontograma-marcas',
            superficies: const [],
            fdiCode: 36,
            tratamientos: [
              TratamientoAplicado(
                tratamientoId: 'procedimiento-sin-clave',
                esContinuo: false,
                estaTerminado: true,
                nombreTratamiento: 'Procedimiento especial',
                superficie: superficie,
              ),
            ],
          ),
        ]);

    expect(
      (await soloDiagrama(conTratamiento(null))).length,
      isNot(
        (await soloDiagrama(conTratamiento(TipoSuperficie.oclusal))).length,
      ),
      reason:
          'pieza completa y cara oclusal no pueden producir el mismo dibujo',
    );
  });

  test('lo registrado sin pieza aparece en el expediente', () async {
    final paciente = pacienteConOdontograma(const <Diente>[]);
    final conGeneral = Paciente(
      id: paciente.id,
      nombre: paciente.nombre,
      apellido: paciente.apellido,
      birthDate: paciente.birthDate,
      govID: paciente.govID,
      contactos: paciente.contactos,
      estatus: paciente.estatus,
      genero: paciente.genero,
      tipoPaciente: paciente.tipoPaciente,
      trabajo: paciente.trabajo,
      referencia: paciente.referencia,
      citas: paciente.citas,
      record: Record(
        pacienteId: _pacienteId,
        tipoSangre: TipoSangre.oPositivo,
        condiciones: const <Condicion>[],
        cirugiasPrevias: const [],
        historialFamiliar: '',
        consultas: [
          Consulta(
            id: 'consulta-general',
            pacienteId: _pacienteId,
            doctorId: 'doctor-1',
            fecha: DateTime(2026, 7, 20),
            tipoAtencion: TipoAtencionClinica.consulta,
            motivoConsulta: 'Limpieza',
            tratamientosGenerales: [
              TratamientoAplicado(
                id: 'ta-general',
                tratamientoId: 'profilaxis',
                esContinuo: false,
                estaTerminado: true,
                nombreTratamiento: 'Profilaxis dental',
                fechaEjecucion: DateTime(2026, 7, 20),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await ExpedientePdfBuilder.buildPdf(
      paciente: conGeneral,
      options: const ExpedientePrintOptions(),
      generadoEn: DateTime(2026, 7, 26),
      theme: pw.ThemeData(),
      compress: false,
    );
    final raw = latin1.decode(bytes, allowInvalid: true);

    expect(raw, contains('Profilaxis'));
    // El flujo de contenido del PDF emite una palabra por operador de texto,
    // así que se buscan los tokens sueltos y no la frase completa.
    expect(
      raw,
      allOf(contains('(Sin)'), contains('(pieza)')),
      reason:
          'un tratamiento sin pieza se guardaba con diente_id NULL y no salía '
          'en ninguna lectura (defecto D5)',
    );
  });
}
