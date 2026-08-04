import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

HallazgoDental _caries(Set<TipoSuperficie> superficies) => HallazgoDental(
  estado: EstadoClinicoDental.cariada,
  superficies: superficies,
);

TratamientoAplicado _tratamiento({TipoSuperficie? superficie}) =>
    TratamientoAplicado(
      tratamientoId: 't-1',
      esContinuo: false,
      estaTerminado: false,
      superficie: superficie,
    );

Diente _diente({
  List<TratamientoAplicado> tratamientos = const [],
  List<TratamientoAplicado> historicos = const [],
  bool ausente = false,
}) => Diente(
  odontogramaId: 'o-1',
  fdiCode: 16,
  superficies: [
    for (final t in TipoSuperficie.values)
      Superficie(dienteId: 'd-1', tipoSuperficie: t),
  ],
  tratamientos: tratamientos,
  tratamientosHistoricos: historicos,
  estaAusente: ausente,
);

void main() {
  group('capa histórica del odontodiagrama', () {
    test('una caries nueva no esconde la caries previa de otra cara', () {
      final historico = _caries({TipoSuperficie.distal});
      final hoy = _caries({TipoSuperficie.mesial});

      final restantes = hallazgosRestantes([historico], [hoy]);

      // La lesión previa en distal sigue en la boca: tiene que verse.
      expect(restantes.single.superficies, {TipoSuperficie.distal});
    });

    test('la misma cara anotada hoy sí tapa a la histórica', () {
      final restantes = hallazgosRestantes(
        [
          _caries({TipoSuperficie.mesial}),
        ],
        [
          _caries({TipoSuperficie.mesial}),
        ],
      );

      expect(restantes, isEmpty);
    });

    test('de varias caras históricas solo se descuentan las repetidas', () {
      final restantes = hallazgosRestantes(
        [
          _caries({TipoSuperficie.mesial, TipoSuperficie.oclusal}),
        ],
        [
          _caries({TipoSuperficie.mesial}),
        ],
      );

      expect(restantes.single.superficies, {TipoSuperficie.oclusal});
    });

    test('una clave de pieza completa tapa cualquier cara histórica', () {
      final restantes = hallazgosRestantes(
        [
          _caries({TipoSuperficie.mesial}),
        ],
        [const HallazgoDental(estado: EstadoClinicoDental.cariada)],
      );

      expect(restantes, isEmpty);
    });

    test(
      'una cara anotada hoy no tapa la clave histórica de pieza completa',
      () {
        final restantes = hallazgosRestantes(
          [const HallazgoDental(estado: EstadoClinicoDental.perdida)],
          [
            _caries({TipoSuperficie.mesial}),
          ],
        );

        expect(restantes.single.estado, EstadoClinicoDental.perdida);
      },
    );

    test('EvaluacionOdontologica.menos resta por superficie', () {
      final historica = const EvaluacionOdontologica().conHallazgos(16, [
        _caries({TipoSuperficie.distal}),
      ]);
      final hoy = const EvaluacionOdontologica().conHallazgos(16, [
        _caries({TipoSuperficie.mesial}),
      ]);

      expect(historica.menos(hoy).de(16).single.superficies, {
        TipoSuperficie.distal,
      });
    });
  });

  group('marcaDeSuperficie', () {
    test('la cara tratada en esta consulta se marca como ejecutada', () {
      final diente = _diente(
        tratamientos: [_tratamiento(superficie: TipoSuperficie.oclusal)],
      );

      expect(
        marcaDeSuperficieDelDiente(diente, TipoSuperficie.oclusal)?.procedencia,
        ProcedenciaMarca.ejecutado,
      );
      expect(marcaDeSuperficieDelDiente(diente, TipoSuperficie.mesial), isNull);
    });

    test('un tratamiento de pieza completa no pinta ninguna cara', () {
      final diente = _diente(tratamientos: [_tratamiento()]);

      for (final cara in TipoSuperficie.values) {
        expect(marcaDeSuperficieDelDiente(diente, cara), isNull);
      }
    });

    test('la cara tratada en consultas anteriores se marca como histórica', () {
      final diente = _diente(
        historicos: [_tratamiento(superficie: TipoSuperficie.vestibular)],
      );

      expect(
        marcaDeSuperficieDelDiente(
          diente,
          TipoSuperficie.vestibular,
        )?.procedencia,
        ProcedenciaMarca.historico,
      );
    });

    test('lo de hoy manda sobre lo histórico en la misma cara', () {
      final diente = _diente(
        tratamientos: [_tratamiento(superficie: TipoSuperficie.oclusal)],
        historicos: [_tratamiento(superficie: TipoSuperficie.oclusal)],
      );

      expect(
        marcaDeSuperficieDelDiente(diente, TipoSuperficie.oclusal)?.procedencia,
        ProcedenciaMarca.ejecutado,
      );
    });

    test('un diente ausente no pinta caras', () {
      final diente = _diente(
        tratamientos: [_tratamiento(superficie: TipoSuperficie.oclusal)],
        ausente: true,
      );

      expect(
        marcaDeSuperficieDelDiente(diente, TipoSuperficie.oclusal),
        isNull,
      );
    });
  });
}
