import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

/// Captura lo que el repositorio manda a persistir.
class _DatasourceEspia extends _Vacio implements ConsultaRemoteDatasource {
  Map<int, Map<String, dynamic>>? dientesRecibidos;
  ResultadoGuardadoOdontograma respuesta = const ResultadoGuardadoOdontograma();

  @override
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Map<int, Map<String, dynamic>> dientesPorFdi,
    required List<Map<String, dynamic>> recetas,
    required Map<String, dynamic> evaluacionOdontologica,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  }) async {
    dientesRecibidos = dientesPorFdi;
    return respuesta;
  }
}

Odontograma _odontogramaCon(Diente diente) =>
    Odontograma(consultaId: 'c-1', dientes: [diente]);

Future<Map<String, dynamic>> _guardar(
  _DatasourceEspia datasource,
  Diente diente,
) async {
  final repo = ConsultaRepositoryImpl(remoteDataSource: datasource);
  await repo.guardarResultadoConsulta(
    consultaId: 'c-1',
    pacienteId: 'p-1',
    odontograma: _odontogramaCon(diente),
    recetas: const [],
  );
  return datasource.dientesRecibidos![diente.fdiCode]!;
}

void main() {
  group('guardarResultadoConsulta · lo que llega a la base de datos', () {
    test(
      'la justificación clínica de una contraindicación se persiste',
      () async {
        final datasource = _DatasourceEspia();
        final diente = Diente(
          odontogramaId: 'o-1',
          fdiCode: 16,
          superficies: const [],
          tratamientos: [
            TratamientoAplicado(
              tratamientoId: 't-1',
              esContinuo: false,
              estaTerminado: false,
              superficie: TipoSuperficie.oclusal,
              precioAplicado: 1500,
              notas: 'Paciente anticoagulado; se procede con hemostasia local.',
            ),
          ],
        );

        final enviado = await _guardar(datasource, diente);
        final tratamiento = (enviado['tratamientos'] as List).single;

        // Es el registro que respalda al doctor si el caso se revisa.
        expect(
          tratamiento['notas'],
          'Paciente anticoagulado; se procede con hemostasia local.',
        );
        expect(tratamiento['superficie'], 'oclusal');
        expect(tratamiento['precio_aplicado'], 1500);
      },
    );

    test('un diente marcado como ausente se persiste', () async {
      final datasource = _DatasourceEspia();
      final diente = Diente(
        odontogramaId: 'o-1',
        fdiCode: 36,
        superficies: const [],
        estaAusente: true,
        observaciones: 'Ausente de larga data.',
      );

      final enviado = await _guardar(datasource, diente);

      expect(enviado['esta_ausente'], isTrue);
      expect(enviado['observaciones'], 'Ausente de larga data.');
    });

    test(
      'un diente sin tratamientos igual viaja, para poder marcarlo',
      () async {
        final datasource = _DatasourceEspia();
        final diente = Diente(
          odontogramaId: 'o-1',
          fdiCode: 21,
          superficies: const [],
        );

        final enviado = await _guardar(datasource, diente);

        expect(enviado['esta_ausente'], isFalse);
        expect(enviado['tratamientos'], isEmpty);
      },
    );

    test(
      'un tratamiento ya persistido viaja con su id, para actualizarlo en vez '
      'de duplicarlo',
      () async {
        final datasource = _DatasourceEspia();
        final diente = Diente(
          odontogramaId: 'o-1',
          fdiCode: 16,
          superficies: const [],
          tratamientos: [
            TratamientoAplicado(
              id: 'ta-existente',
              tratamientoId: 't-1',
              esContinuo: false,
              estaTerminado: true,
            ),
            TratamientoAplicado(
              tratamientoId: 't-2',
              esContinuo: false,
              estaTerminado: false,
            ),
          ],
        );

        final enviado = await _guardar(datasource, diente);
        final tratamientos = enviado['tratamientos'] as List;

        expect(tratamientos.first['id'], 'ta-existente');
        // El nuevo no lleva id: lo asigna la base de datos al insertarlo.
        expect(tratamientos.last.containsKey('id'), isFalse);
      },
    );

    test(
      'un diagnóstico conserva pieza, cara, fecha y origen al guardarse',
      () async {
        final datasource = _DatasourceEspia();
        final diente = Diente(
          odontogramaId: 'o-1',
          fdiCode: 74,
          superficies: const [],
          diagnosis: [
            DiagnosticoAplicado(
              diagnosisId: 'diag-caries',
              severidad: SeveridadDiagnosis.moderada,
              fechaAplicacion: DateTime.utc(2026, 7, 24, 10),
              notas: 'Lesión profunda',
              superficie: TipoSuperficie.oclusal,
              origen: OrigenMarcaOdontograma.preexistente,
            ),
          ],
        );

        final enviado = await _guardar(datasource, diente);
        final diagnostico = (enviado['diagnosticos'] as List).single;

        expect(diagnostico['diagnosis_id'], 'diag-caries');
        expect(diagnostico['superficie'], 'oclusal');
        expect(diagnostico['origen'], 'preexistente');
        expect(diagnostico['fecha_aplicacion'], contains('2026-07-24'));
      },
    );
  });
}
