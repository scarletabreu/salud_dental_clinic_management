import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_arch_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';

Consulta _consulta({
  required String id,
  required DateTime fecha,
  EvaluacionOdontologica evaluacion = EvaluacionOdontologica.vacia,
}) => Consulta(
  id: id,
  pacienteId: 'pac-1',
  doctorId: 'doc-1',
  fecha: fecha,
  odontograma: Odontograma(
    id: 'odo-$id',
    consultaId: id,
    evaluacion: evaluacion,
    dientes: [
      for (final fdi in kFdiPermanentes)
        Diente(
          odontogramaId: 'odo-$id',
          fdiCode: fdi,
          superficies: superficiesParaFdi(fdi)
              .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
              .toList(),
        ),
    ],
  ),
);

Future<void> _montar(
  WidgetTester tester, {
  required List<Consulta> consultas,
  bool historialNoDisponible = false,
  ThemeData? tema,
}) async {
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: tema ?? AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OdontogramArchWidget(
            consultas: consultas,
            historialNoDisponible: historialNoDisponible,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    vistaOdontogramaPreferida.value = VistaOdontograma.formulario;
  });

  group('OdontogramArchWidget', () {
    testWidgets('un paciente con consultas muestra su odontograma', (
      tester,
    ) async {
      await _montar(
        tester,
        consultas: [
          _consulta(
            id: 'c1',
            fecha: DateTime(2026, 7, 20),
            evaluacion: EvaluacionOdontologica.vacia.alternar(
              16,
              EstadoClinicoDental.cariada,
            ),
          ),
        ],
      );

      expect(
        find.text('Este paciente aún no tiene consultas con odontograma.'),
        findsNothing,
      );
      expect(find.byType(SelectorVistaOdontograma), findsOneWidget);
      expect(find.byKey(const ValueKey('pieza_16')), findsOneWidget);
    });

    testWidgets('el selector cambia entre formulario y arcada', (tester) async {
      await _montar(
        tester,
        consultas: [_consulta(id: 'c1', fecha: DateTime(2026, 7, 20))],
      );

      expect(find.byType(OdontodiagramaWidget), findsOneWidget);
      expect(find.byType(OdontogramWidget), findsNothing);

      await tester.tap(find.text('Arcada'));
      await tester.pumpAndSettle();

      expect(find.byType(OdontogramWidget), findsOneWidget);
      expect(find.byType(OdontodiagramaWidget), findsNothing);
    });

    testWidgets('la consulta más reciente arrastra lo anotado en las previas', (
      tester,
    ) async {
      await _montar(
        tester,
        consultas: [
          _consulta(
            id: 'nueva',
            fecha: DateTime(2026, 7, 24),
            evaluacion: EvaluacionOdontologica.vacia.alternar(
              16,
              EstadoClinicoDental.cariada,
            ),
          ),
          _consulta(
            id: 'vieja',
            fecha: DateTime(2026, 1, 10),
            evaluacion: EvaluacionOdontologica.vacia.alternar(
              36,
              EstadoClinicoDental.perdida,
            ),
          ),
        ],
      );

      final diagrama = tester.widget<OdontodiagramaWidget>(
        find.byType(OdontodiagramaWidget),
      );
      expect(diagrama.evaluacion.de(16).single.estado, EstadoClinicoDental.cariada);
      expect(
        diagrama.historico.de(36).single.estado,
        EstadoClinicoDental.perdida,
        reason: 'lo de la consulta anterior debe verse como capa histórica',
      );
      // Lo anotado hoy no se repite en tenue.
      expect(diagrama.historico.de(16), isEmpty);
    });

    testWidgets('un fallo de carga no se disfraza de paciente sin consultas', (
      tester,
    ) async {
      await _montar(tester, consultas: const [], historialNoDisponible: true);

      expect(find.text('No se pudo cargar el historial clínico.'), findsOneWidget);
      expect(
        find.text('Este paciente aún no tiene consultas con odontograma.'),
        findsNothing,
      );
    });

    testWidgets('un paciente realmente sin consultas lo dice así', (
      tester,
    ) async {
      await _montar(tester, consultas: const []);

      expect(
        find.text('Este paciente aún no tiene consultas con odontograma.'),
        findsOneWidget,
      );
      expect(find.text('No se pudo cargar el historial clínico.'), findsNothing);
    });

    testWidgets('la vista general consolida todas las consultas', (
      tester,
    ) async {
      await _montar(
        tester,
        consultas: [
          _consulta(
            id: 'nueva',
            fecha: DateTime(2026, 7, 24),
            evaluacion: EvaluacionOdontologica.vacia.alternar(
              16,
              EstadoClinicoDental.cariada,
            ),
          ),
          _consulta(
            id: 'vieja',
            fecha: DateTime(2026, 1, 10),
            evaluacion: EvaluacionOdontologica.vacia.alternar(
              36,
              EstadoClinicoDental.perdida,
            ),
          ),
        ],
      );

      await tester.tap(find.text('Vista General'));
      await tester.pumpAndSettle();

      final diagrama = tester.widget<OdontodiagramaWidget>(
        find.byType(OdontodiagramaWidget),
      );
      expect(diagrama.evaluacion.de(16).single.estado, EstadoClinicoDental.cariada);
      expect(diagrama.evaluacion.de(36).single.estado, EstadoClinicoDental.perdida);
    });

    testWidgets('el expediente se dibuja también en tema oscuro', (
      tester,
    ) async {
      await _montar(
        tester,
        tema: AppTheme.dark,
        consultas: [_consulta(id: 'c1', fecha: DateTime(2026, 7, 20))],
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pieza_16')), findsOneWidget);
    });
  });
}
