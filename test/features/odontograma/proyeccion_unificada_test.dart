import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

Diente _diente({
  List<DiagnosticoAplicado> diagnosticos = const [],
  List<TratamientoAplicado> tratamientos = const [],
  List<TratamientoAplicado> historicos = const [],
}) => Diente(
  odontogramaId: 'o-1',
  fdiCode: 74,
  superficies: const [],
  diagnosis: diagnosticos,
  tratamientos: tratamientos,
  tratamientosHistoricos: historicos,
);

void main() {
  group('proyección unificada del odontograma', () {
    test('las 52 piezas incluyen la temporal 74 con cinco superficies', () {
      expect(kFdiTodas, hasLength(52));
      expect(kFdiTodas, containsAll([11, 48, 51, 74, 85]));
      expect(superficiesParaFdi(74), contains(TipoSuperficie.oclusal));
      expect(superficiesParaFdi(74), contains(TipoSuperficie.lingual));
    });

    test('un tratamiento de la arcada se proyecta al formulario', () {
      final odontograma = Odontograma(
        consultaId: 'c-1',
        dientes: [
          _diente(
            tratamientos: [
              TratamientoAplicado(
                tratamientoId: 't-1',
                esContinuo: false,
                estaTerminado: false,
                superficie: TipoSuperficie.oclusal,
                claveOdontograma: 'restaurada',
              ),
            ],
          ),
        ],
      );

      final hallazgo = odontograma.evaluacionProyectada.de(74).single;
      expect(hallazgo.estado, EstadoClinicoDental.restaurada);
      expect(hallazgo.superficies, {TipoSuperficie.oclusal});
    });

    test('un tratamiento sin clave no estampa ningún símbolo en el papel', () {
      final odontograma = Odontograma(
        consultaId: 'c-1',
        dientes: [
          _diente(
            tratamientos: [
              TratamientoAplicado(
                tratamientoId: 't-corona',
                esContinuo: false,
                estaTerminado: false,
                nombreTratamiento: 'Corona de porcelana',
              ),
            ],
          ),
        ],
      );

      // «Otro» es lo que el doctor elige a propósito para algo que el programa
      // no contempla; no el cajón de lo que el catálogo aún no clasificó. Antes
      // toda corona estampaba un asterisco sobre su pieza.
      expect(odontograma.evaluacionProyectada.de(74), isEmpty);
    });

    test('un tratamiento de consultas anteriores no se dibuja en el papel', () {
      final odontograma = Odontograma(
        consultaId: 'c-1',
        dientes: [
          _diente(
            historicos: [
              // Sin clave en el catálogo: antes caía en «Otro» y estampaba un
              // asterisco sobre cada pieza con historial.
              TratamientoAplicado(
                tratamientoId: 't-viejo',
                esContinuo: false,
                estaTerminado: true,
              ),
              TratamientoAplicado(
                tratamientoId: 't-viejo-2',
                esContinuo: false,
                estaTerminado: true,
                superficie: TipoSuperficie.oclusal,
                claveOdontograma: 'restaurada',
              ),
            ],
          ),
        ],
      );

      // El historial se consulta en la ficha de la pieza, no en el dibujo.
      expect(odontograma.evaluacionProyectada.de(74), isEmpty);
      expect(odontograma.dientes.single.tratamientosHistoricos, hasLength(2));
    });

    test('pérdida normalizada deja la pieza ausente en la arcada', () {
      final diente = _diente(
        diagnosticos: [
          DiagnosticoAplicado(
            diagnosisId: 'd-perdida',
            severidad: SeveridadDiagnosis.grave,
            fechaAplicacion: DateTime(2026, 7, 24),
            notas: '',
            claveOdontograma: 'perdida',
          ),
        ],
      );

      expect(dienteEstaAusente(diente), isTrue);
      expect(statusForDiente(diente), ToothStatus.empty);
      expect(
        Odontograma(
          consultaId: 'c-1',
          dientes: [diente],
        ).evaluacionProyectada.de(74).single.estado,
        EstadoClinicoDental.perdida,
      );
    });

    test('el jsonb persistido conserva solo tejidos blandos', () {
      final odontograma = Odontograma(
        consultaId: 'c-1',
        evaluacion: EvaluacionOdontologica.vacia
            .alternar(74, EstadoClinicoDental.cariada)
            .conTejido(TejidoBlando.lengua, 'Sin lesión'),
        dientes: const [],
      );

      expect(odontograma.evaluacionToJson()['hallazgos'], isEmpty);
      expect(odontograma.evaluacionToJson()['tejidos_blandos'], {
        'lengua': 'Sin lesión',
      });
    });
  });
}
