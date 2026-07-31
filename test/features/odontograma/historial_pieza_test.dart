import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

// ─────────────────────────────────────────────
//  Dobles y ayudantes
// ─────────────────────────────────────────────

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

class _DatasourceDoble extends _Vacio implements ConsultaRemoteDatasource {
  final List<Map<String, dynamic>> diagnosticos;
  final List<Map<String, dynamic>> tratamientos;
  final List<Map<String, dynamic>> itemsPlan;
  final List<Map<String, dynamic>> consultas;
  final List<Map<String, dynamic>> doctores;

  bool? anuladosEnDiagnosticos;
  bool? anuladosEnTratamientos;
  String? exclusionRecibida;

  _DatasourceDoble({
    this.diagnosticos = const [],
    this.tratamientos = const [],
    this.itemsPlan = const [],
    this.consultas = const [],
    this.doctores = const [],
  });

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosticosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  }) async {
    anuladosEnDiagnosticos = incluyendoAnulados;
    exclusionRecibida = excluyendoConsultaId;
    return diagnosticos;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  }) async {
    anuladosEnTratamientos = incluyendoAnulados;
    return tratamientos;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchItemsPlanPorPaciente(
    String pacienteId,
  ) async => itemsPlan;

  @override
  Future<List<Map<String, dynamic>>> fetchReferenciasConsultasPaciente(
    String pacienteId,
  ) async => consultas;

  @override
  Future<List<Map<String, dynamic>>> fetchNombresDoctores(
    List<String> ids,
  ) async => doctores;
}

/// Una consulta como la devuelve el índice del historial.
Map<String, dynamic> _consulta({
  required String id,
  required DateTime fecha,
  String motivo = 'Control',
  String tipo = 'consulta',
  String doctorId = 'doc-1',
}) => {
  'id': id,
  'fecha': fecha.toIso8601String(),
  'motivo_consulta': motivo,
  'tipo_atencion': tipo,
  'doctor_id': doctorId,
};

DiagnosticoAplicado _hallazgo({
  String id = 'da-1',
  String consultaId = 'c-1',
  DateTime? fecha,
  DateTime? anuladoEn,
  String? doctorId = 'doc-1',
}) => DiagnosticoAplicado(
  id: id,
  diagnosisId: 'dx',
  severidad: SeveridadDiagnosis.moderada,
  fechaAplicacion: fecha ?? DateTime(2026, 1, 10),
  notas: 'Cara oclusal reblandecida',
  consultaId: consultaId,
  superficie: TipoSuperficie.oclusal,
  doctorId: doctorId,
  nombreDiagnostico: 'Caries oclusal',
  claveOdontograma: 'cariada',
  anuladoEn: anuladoEn,
);

TratamientoAplicado _ejecucion({
  String id = 'ta-1',
  String consultaId = 'c-1',
  DateTime? fecha,
  DateTime? anuladoEn,
  bool terminado = true,
  double? precio = 1500,
}) => TratamientoAplicado(
  id: id,
  tratamientoId: 't-1',
  esContinuo: false,
  estaTerminado: terminado,
  consultaId: consultaId,
  superficie: TipoSuperficie.oclusal,
  precioAplicado: precio,
  nombreTratamiento: 'Resina compuesta',
  fechaAplicacion: fecha ?? DateTime(2026, 1, 10),
  doctorEjecutaId: 'doc-1',
  anuladoEn: anuladoEn,
);

ItemPlanTratamiento _actividad({
  String id = 'ip-1',
  String? consultaOrigenId = 'c-1',
  EstadoItemPlan estado = EstadoItemPlan.aceptado,
  DateTime? fecha,
  DateTime? anuladoEn,
}) => ItemPlanTratamiento(
  id: id,
  planId: 'p-1',
  tratamientoId: 't-1',
  fdiDiente: 36,
  superficie: TipoSuperficie.oclusal,
  estado: estado,
  precioEstimado: 2000,
  nombreTratamiento: 'Resina compuesta',
  fechaPropuesta: fecha ?? DateTime(2026, 1, 10),
  doctorProponeId: 'doc-1',
  consultaOrigenId: consultaOrigenId,
  anuladoEn: anuladoEn,
);

void main() {
  group('HistorialPiezas.consolidar', () {
    test('agrupa por visita y ordena de la más reciente a la más antigua', () {
      final historial = HistorialPiezas.consolidar(
        diagnosticos: {
          36: [_hallazgo(consultaId: 'c-vieja', fecha: DateTime(2026, 1, 10))],
        },
        tratamientos: {
          36: [_ejecucion(consultaId: 'c-nueva', fecha: DateTime(2026, 6, 12))],
        },
        consultas: {
          'c-vieja': ReferenciaConsulta(
            id: 'c-vieja',
            fecha: DateTime(2026, 1, 10),
          ),
          'c-nueva': ReferenciaConsulta(
            id: 'c-nueva',
            fecha: DateTime(2026, 6, 12),
          ),
        },
      );

      final pieza = historial[36]!;
      expect(pieza.visitas, hasLength(2));
      expect(pieza.visitas.first.consulta?.id, 'c-nueva');
      expect(pieza.visitas.last.consulta?.id, 'c-vieja');
      expect(pieza.totalEventos, 2);
    });

    test('una consulta nueva sin nada en la pieza no borra lo anterior', () {
      // Es la regla del ticket: consolidar la situación actual del paciente
      // no puede perder eventos. La consulta de hoy no anota nada sobre el 36
      // y su historia tiene que seguir contando lo de enero.
      final historial = HistorialPiezas.consolidar(
        diagnosticos: {
          36: [_hallazgo(consultaId: 'c-enero')],
        },
        tratamientos: const {},
        consultas: {
          'c-enero': ReferenciaConsulta(
            id: 'c-enero',
            fecha: DateTime(2026, 1, 10),
          ),
          'c-hoy': ReferenciaConsulta(
            id: 'c-hoy',
            fecha: DateTime(2026, 7, 26),
          ),
        },
      );

      expect(historial[36]!.totalEventos, 1);
      expect(historial[36]!.visitas.single.consulta?.id, 'c-enero');
    });

    test('dentro de una visita cuenta evaluado, planificado y ejecutado', () {
      final historial = HistorialPiezas.consolidar(
        diagnosticos: {
          36: [_hallazgo()],
        },
        tratamientos: {
          36: [_ejecucion()],
        },
        itemsPlan: {
          36: [_actividad()],
        },
        consultas: {
          'c-1': ReferenciaConsulta(id: 'c-1', fecha: DateTime(2026, 1, 10)),
        },
      );

      final ejes = historial[36]!.visitas.single.eventos
          .map((e) => e.procedencia)
          .toList();
      expect(ejes, [
        ProcedenciaMarca.evaluado,
        ProcedenciaMarca.planificado,
        ProcedenciaMarca.ejecutado,
      ]);
    });

    test('distingue lo activo, lo finalizado y lo anulado', () {
      final historial = HistorialPiezas.consolidar(
        tratamientos: {
          36: [
            _ejecucion(id: 'ta-activo', terminado: false),
            _ejecucion(id: 'ta-final', terminado: true),
            _ejecucion(id: 'ta-anulado', anuladoEn: DateTime(2026, 2, 1)),
          ],
        },
        consultas: {
          'c-1': ReferenciaConsulta(id: 'c-1', fecha: DateTime(2026, 1, 10)),
        },
      );

      final porId = {
        for (final evento in historial[36]!.eventos) evento.id: evento,
      };
      expect(porId['ta-activo']!.estado, 'En proceso');
      expect(porId['ta-final']!.estado, 'Ejecutado');
      expect(porId['ta-anulado']!.estado, 'Anulado');
      expect(porId['ta-anulado']!.anulada, isTrue);
      expect(porId['ta-anulado']!.vigente, isFalse);
    });

    test(
      'el precio ejecutado se conserva y el del plan queda como estimado',
      () {
        final historial = HistorialPiezas.consolidar(
          tratamientos: {
            36: [_ejecucion(precio: 1500)],
          },
          itemsPlan: {
            36: [_actividad()],
          },
          consultas: {
            'c-1': ReferenciaConsulta(id: 'c-1', fecha: DateTime(2026, 1, 10)),
          },
        );

        final pieza = historial[36]!;
        final ejecutado = pieza.eventos.firstWhere(
          (e) => e.procedencia == ProcedenciaMarca.ejecutado,
        );
        final planificado = pieza.eventos.firstWhere(
          (e) => e.procedencia == ProcedenciaMarca.planificado,
        );

        expect(ejecutado.precio, 1500);
        expect(planificado.precio, 2000);
        // Solo lo ejecutado suma: el estimado del plan nunca es un cargo.
        expect(pieza.totalEjecutado, 1500);
      },
    );

    test('lo anulado no suma al total ejecutado de la pieza', () {
      final historial = HistorialPiezas.consolidar(
        tratamientos: {
          36: [
            _ejecucion(id: 'ta-1', precio: 1500),
            _ejecucion(
              id: 'ta-2',
              precio: 900,
              anuladoEn: DateTime(2026, 2, 1),
            ),
          ],
        },
        consultas: {
          'c-1': ReferenciaConsulta(id: 'c-1', fecha: DateTime(2026, 1, 10)),
        },
      );

      expect(historial[36]!.totalEjecutado, 1500);
      expect(historial[36]!.totalEventos, 2, reason: 'lo anulado sigue ahí');
    });

    test('un evento sin consulta conocida se agrupa por su día', () {
      final historial = HistorialPiezas.consolidar(
        itemsPlan: {
          36: [_actividad(consultaOrigenId: null)],
        },
      );

      final visita = historial[36]!.visitas.single;
      expect(visita.consulta, isNull);
      expect(visita.fecha, DateTime(2026, 1, 10));
      expect(visita.eventos, hasLength(1));
    });
  });

  group('ConsultaRepositoryImpl.getHistorialPiezas', () {
    test('arma la línea de tiempo con los tres ejes y las anulaciones', () async {
      final datasource = _DatasourceDoble(
        consultas: [
          _consulta(
            id: 'c-1',
            fecha: DateTime(2026, 1, 10),
            motivo: 'Dolor al masticar',
            tipo: 'evaluacion',
          ),
          _consulta(id: 'c-2', fecha: DateTime(2026, 6, 12)),
        ],
        diagnosticos: [
          {
            'id': 'da-1',
            'diagnosis_id': 'dx',
            'severidad': 'moderada',
            'fecha_aplicacion': DateTime(2026, 1, 10).toIso8601String(),
            'notas': '',
            'consulta_id': 'c-1',
            'superficie': 'oclusal',
            'diagnosis': {
              'nombre': 'Caries oclusal',
              'clave_odontograma': 'cariada',
            },
            'diente': {'fdi_code': 36},
            'consulta': {'doctor_id': 'doc-1'},
          },
        ],
        tratamientos: [
          {
            'id': 'ta-1',
            'tratamiento_id': 't-1',
            'es_continuo': false,
            'esta_terminado': true,
            'consulta_id': 'c-2',
            'superficie': 'oclusal',
            'precio_aplicado': 1500,
            'estado': 'aplicado',
            'created_at': DateTime(2026, 6, 12).toIso8601String(),
            'deleted_at': DateTime(2026, 6, 20).toIso8601String(),
            'tratamiento': {'nombre': 'Resina compuesta'},
            'diente': {'fdi_code': 36},
          },
        ],
        itemsPlan: [
          {
            'id': 'ip-1',
            'plan_id': 'p-1',
            'tratamiento_id': 't-1',
            'estado': 'aceptado',
            'precio_estimado': 2000,
            'superficie': 'oclusal',
            'fecha_propuesta': DateTime(2026, 1, 10).toIso8601String(),
            'tratamiento': {'nombre': 'Resina compuesta'},
            'diente': {'fdi_code': 36},
            'plan': {'consulta_origen_id': 'c-1'},
          },
        ],
        doctores: [
          {
            'id': 'doc-1',
            'usuarios': {
              'personas': {'nombre': 'Ana', 'apellido': 'Pérez'},
            },
          },
        ],
      );

      final historial = await ConsultaRepositoryImpl(
        remoteDataSource: datasource,
      ).getHistorialPiezas('pac-1');

      // Los dos ejes con borrado lógico se piden con las anulaciones incluidas:
      // sin eso, retirar un tratamiento lo borraría de la historia.
      expect(datasource.anuladosEnDiagnosticos, isTrue);
      expect(datasource.anuladosEnTratamientos, isTrue);
      // Nada de exclusiones: el historial incluye la consulta en curso.
      expect(datasource.exclusionRecibida, isNull);

      final pieza = historial[36]!;
      expect(pieza.visitas, hasLength(2));

      final reciente = pieza.visitas.first;
      expect(reciente.consulta?.id, 'c-2');
      expect(reciente.eventos.single.estado, 'Anulado');
      expect(reciente.eventos.single.precio, 1500);

      final antigua = pieza.visitas.last;
      expect(antigua.consulta?.motivo, 'Dolor al masticar');
      expect(antigua.consulta?.tipoAtencion, TipoAtencionClinica.evaluacion);
      expect(antigua.eventos.map((e) => e.procedencia), [
        ProcedenciaMarca.evaluado,
        ProcedenciaMarca.planificado,
      ]);

      expect(historial.nombreDoctor('doc-1'), 'Dr. Ana Pérez');
    });

    test(
      'sin plan legible el historial sale igual con los otros ejes',
      () async {
        final datasource = _DatasourcePlanRoto(
          consultas: [_consulta(id: 'c-1', fecha: DateTime(2026, 1, 10))],
          diagnosticos: [
            {
              'id': 'da-1',
              'diagnosis_id': 'dx',
              'severidad': 'leve',
              'fecha_aplicacion': DateTime(2026, 1, 10).toIso8601String(),
              'notas': '',
              'consulta_id': 'c-1',
              'diagnosis': {'nombre': 'Caries', 'clave_odontograma': 'cariada'},
              'diente': {'fdi_code': 36},
            },
          ],
        );

        final historial = await ConsultaRepositoryImpl(
          remoteDataSource: datasource,
        ).getHistorialPiezas('pac-1');

        expect(historial[36]!.totalEventos, 1);
      },
    );
  });
}

/// Datasource cuyo eje de plan falla: el historial no puede caerse por él.
class _DatasourcePlanRoto extends _DatasourceDoble {
  _DatasourcePlanRoto({super.consultas, super.diagnosticos});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsPlanPorPaciente(
    String pacienteId,
  ) async => throw Exception('sin red');
}
