import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Todo lo que SD-142 exige conservar de un hallazgo: tipo, estado, fecha,
/// consulta, doctor y notas.
DiagnosticoAplicado _caries({
  TipoSuperficie? superficie,
  String? consultaId = 'c-hoy',
  String? doctorId = 'doc-1',
  DateTime? fecha,
}) => DiagnosticoAplicado(
  id: 'da-1',
  diagnosisId: 'dx-caries',
  severidad: SeveridadDiagnosis.moderada,
  fechaAplicacion: fecha ?? DateTime(2026, 6, 12),
  notas: 'Lesión activa',
  consultaId: consultaId,
  superficie: superficie,
  doctorId: doctorId,
  nombreDiagnostico: 'Caries oclusal',
  claveOdontograma: 'cariada',
);

TratamientoAplicado _resina({
  TipoSuperficie? superficie,
  bool terminado = true,
  String? consultaId = 'c-hoy',
}) => TratamientoAplicado(
  id: 'ta-1',
  tratamientoId: 't-resina',
  esContinuo: false,
  estaTerminado: terminado,
  superficie: superficie,
  consultaId: consultaId,
  notas: 'Sin incidencias',
  nombreTratamiento: 'Resina compuesta',
  claveOdontograma: 'restaurada',
  doctorEjecutaId: 'doc-2',
  fechaEjecucion: DateTime(2026, 7, 25),
);

ItemPlanTratamiento _actividad({
  TipoSuperficie? superficie,
  EstadoItemPlan estado = EstadoItemPlan.aceptado,
}) => ItemPlanTratamiento(
  id: 'ip-1',
  planId: 'p-1',
  tratamientoId: 't-corona',
  superficie: superficie,
  estado: estado,
  notas: 'A convenir con el paciente',
  doctorProponeId: 'doc-1',
  fechaPropuesta: DateTime(2026, 7, 20),
  nombreTratamiento: 'Corona',
);

Diente _diente({
  List<DiagnosticoAplicado> diagnosis = const [],
  List<TratamientoAplicado> tratamientos = const [],
  List<DiagnosticoAplicado> diagnosticosHistoricos = const [],
  List<TratamientoAplicado> tratamientosHistoricos = const [],
  bool ausente = false,
}) => Diente(
  odontogramaId: 'o-1',
  fdiCode: 36,
  superficies: [
    for (final t in TipoSuperficie.values)
      Superficie(dienteId: 'd-1', tipoSuperficie: t),
  ],
  diagnosis: diagnosis,
  tratamientos: tratamientos,
  diagnosticosHistoricos: diagnosticosHistoricos,
  tratamientosHistoricos: tratamientosHistoricos,
  estaAusente: ausente,
);

void main() {
  group('procedencia de una marca', () {
    test('cada eje clínico se lee con su propia procedencia', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(
          diagnosis: [_caries(superficie: TipoSuperficie.oclusal)],
          tratamientos: [_resina(superficie: TipoSuperficie.mesial)],
          diagnosticosHistoricos: [
            _caries(superficie: TipoSuperficie.distal, consultaId: 'c-vieja'),
          ],
        ),
        itemsPlan: [_actividad(superficie: TipoSuperficie.vestibular)],
      );

      final porProcedencia = {for (final m in marcas) m.procedencia};
      expect(porProcedencia, {
        ProcedenciaMarca.evaluado,
        ProcedenciaMarca.ejecutado,
        ProcedenciaMarca.planificado,
        ProcedenciaMarca.historico,
      });
    });

    test(
      'un hallazgo conserva tipo, estado, fecha, consulta, doctor y notas',
      () {
        final marca = marcasDePieza(
          fdi: 36,
          diente: _diente(
            diagnosis: [_caries(superficie: TipoSuperficie.oclusal)],
          ),
        ).single;

        expect(marca.clave, EstadoClinicoDental.cariada);
        expect(marca.titulo, 'Caries oclusal');
        expect(marca.superficie, TipoSuperficie.oclusal);
        expect(marca.estado, 'Moderado');
        expect(marca.fecha, DateTime(2026, 6, 12));
        expect(marca.consultaId, 'c-hoy');
        expect(marca.doctorId, 'doc-1');
        expect(marca.notas, 'Lesión activa');
      },
    );

    test('una ejecución conserva el doctor que la hizo y cuándo', () {
      final marca = marcasDePieza(
        fdi: 36,
        diente: _diente(
          tratamientos: [_resina(superficie: TipoSuperficie.mesial)],
        ),
      ).single;

      expect(marca.procedencia, ProcedenciaMarca.ejecutado);
      expect(marca.doctorId, 'doc-2');
      expect(marca.fecha, DateTime(2026, 7, 25));
      expect(marca.estado, 'Terminado');
    });

    test(
      'la ausencia de la pieza se anota como pérdida de la pieza entera',
      () {
        final marca = marcasDePieza(
          fdi: 36,
          diente: _diente(ausente: true),
        ).single;

        expect(marca.clave, EstadoClinicoDental.perdida);
        expect(marca.esPiezaCompleta, isTrue);
      },
    );
  });

  group('procedimiento sin clave en el catálogo', () {
    TratamientoAplicado corona() => TratamientoAplicado(
      tratamientoId: 't-corona',
      esContinuo: false,
      estaTerminado: false,
      superficie: TipoSuperficie.oclusal,
      nombreTratamiento: 'Corona de porcelana',
    );

    test('no se disfraza de «Otro»', () {
      final marca = marcasDePieza(
        fdi: 36,
        diente: _diente(tratamientos: [corona()]),
      ).single;

      expect(marca.clave, isNull);
      expect(marca.tipo, TipoMarcaClinica.procedimiento);
      expect(marca.titulo, 'Corona de porcelana');
    });

    test('se tiñe de azul, como el trabajo hecho sobre la pieza', () {
      final marca = marcasDePieza(
        fdi: 36,
        diente: _diente(tratamientos: [corona()]),
      ).single;

      expect(marca.tintaClinica, TintaClinica.azul);
    });

    test('un hallazgo sin clave se tiñe de rojo', () {
      final sinClave = DiagnosticoAplicado(
        diagnosisId: 'dx',
        severidad: SeveridadDiagnosis.leve,
        fechaAplicacion: DateTime(2026, 7, 25),
        notas: '',
        superficie: TipoSuperficie.mesial,
        nombreDiagnostico: 'Sensibilidad',
      );

      final marca = marcasDePieza(
        fdi: 36,
        diente: _diente(diagnosis: [sinClave]),
      ).single;

      expect(marca.clave, isNull);
      expect(marca.tintaClinica, TintaClinica.roja);
    });

    test('sigue tiñendo su cara aunque no tenga clave', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(tratamientos: [corona()]),
      );

      expect(
        marcaDeSuperficie(marcas, TipoSuperficie.oclusal)?.titulo,
        'Corona de porcelana',
      );
    });
  });

  group('qué tiñe cada cara', () {
    test('lo ejecutado hoy manda sobre lo evaluado en la misma cara', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(
          diagnosis: [_caries(superficie: TipoSuperficie.oclusal)],
          tratamientos: [_resina(superficie: TipoSuperficie.oclusal)],
        ),
      );

      final marca = marcaDeSuperficie(marcas, TipoSuperficie.oclusal);
      expect(marca?.procedencia, ProcedenciaMarca.ejecutado);
      // El color sale de la clave: una restauración es azul, no «tratado».
      expect(marca?.clave, EstadoClinicoDental.restaurada);
    });

    test('lo evaluado hoy manda sobre el antecedente de la misma cara', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(
          diagnosis: [_caries(superficie: TipoSuperficie.oclusal)],
          diagnosticosHistoricos: [
            _caries(superficie: TipoSuperficie.oclusal, consultaId: 'c-vieja'),
          ],
        ),
      );

      expect(
        marcaDeSuperficie(marcas, TipoSuperficie.oclusal)?.procedencia,
        ProcedenciaMarca.evaluado,
      );
    });

    test('una marca de pieza completa no tiñe ninguna cara', () {
      final marcas = marcasDePieza(fdi: 36, diente: _diente(ausente: true));

      for (final cara in TipoSuperficie.values) {
        expect(marcaDeSuperficie(marcas, cara), isNull);
      }
    });

    test('una actividad rechazada se lista pero no tiñe la cara', () {
      final marcas = marcasDePieza(
        fdi: 36,
        itemsPlan: [
          _actividad(
            superficie: TipoSuperficie.vestibular,
            estado: EstadoItemPlan.rechazado,
          ),
        ],
      );

      expect(marcas.single.procedencia, ProcedenciaMarca.planificado);
      expect(marcas.single.vigente, isFalse);
      expect(marcaDeSuperficie(marcas, TipoSuperficie.vestibular), isNull);
    });

    test('lo planificado tiñe la cara mientras no haya nada hecho', () {
      final marcas = marcasDePieza(
        fdi: 36,
        itemsPlan: [_actividad(superficie: TipoSuperficie.vestibular)],
      );

      expect(
        marcaDeSuperficie(marcas, TipoSuperficie.vestibular)?.procedencia,
        ProcedenciaMarca.planificado,
      );
    });
  });

  group('antecedentes sin entidades cargadas', () {
    test('la proyección del odontodiagrama sirve de respaldo', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(),
        hallazgosHistoricos: const [
          HallazgoDental(
            estado: EstadoClinicoDental.restaurada,
            superficies: {TipoSuperficie.distal},
          ),
        ],
      );

      expect(marcas.single.procedencia, ProcedenciaMarca.historico);
      expect(marcas.single.superficie, TipoSuperficie.distal);
    });

    test('con entidades cargadas no se duplica con la proyección', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(
          diagnosticosHistoricos: [
            _caries(superficie: TipoSuperficie.distal, consultaId: 'c-vieja'),
          ],
        ),
        hallazgosHistoricos: const [
          HallazgoDental(
            estado: EstadoClinicoDental.cariada,
            superficies: {TipoSuperficie.distal},
          ),
        ],
      );

      // Gana la entidad, que es la única que trae fecha, consulta y doctor.
      expect(marcas, hasLength(1));
      expect(marcas.single.consultaId, 'c-vieja');
      expect(marcas.single.doctorId, 'doc-1');
    });
  });

  group('marca que describe la pieza entera', () {
    test('gana la procedencia más firme', () {
      final marcas = marcasDePieza(
        fdi: 36,
        diente: _diente(
          diagnosis: [_caries(superficie: TipoSuperficie.oclusal)],
          tratamientos: [_resina(superficie: TipoSuperficie.mesial)],
        ),
      );

      expect(marcaDominante(marcas)?.procedencia, ProcedenciaMarca.ejecutado);
    });

    test('una pieza sin nada anotado no tiene marca dominante', () {
      expect(marcaDominante(marcasDePieza(fdi: 36, diente: _diente())), isNull);
    });
  });
}
