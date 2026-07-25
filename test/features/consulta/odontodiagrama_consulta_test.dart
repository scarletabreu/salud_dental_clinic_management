import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/finalizar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/workspace_consulta.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/get_condiciones_paciente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';

const _consultaId = '33333333-3333-3333-3333-333333333333';
const _pacienteId = '11111111-1111-1111-1111-111111111111';

Consulta _consultaConOdontograma({
  EvaluacionOdontologica evaluacion = EvaluacionOdontologica.vacia,
  EvaluacionOdontologica historico = EvaluacionOdontologica.vacia,
}) => Consulta(
  id: _consultaId,
  pacienteId: _pacienteId,
  doctorId: '22222222-2222-2222-2222-222222222222',
  fecha: DateTime(2026, 7, 24),
  odontograma: Odontograma(
    id: 'odo-1',
    consultaId: _consultaId,
    evaluacion: evaluacion,
    evaluacionHistorica: historico,
    dientes: [
      for (final fdi in kFdiPermanentes)
        Diente(
          odontogramaId: 'odo-1',
          fdiCode: fdi,
          superficies: superficiesParaFdi(fdi)
              .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
              .toList(),
        ),
    ],
  ),
);

/// Repositorio de consulta que recuerda el odontograma que se le manda guardar.
class _ConsultaRepositorioEspia implements ConsultaRepository {
  Odontograma? guardado;
  int escrituras = 0;
  final Consulta consulta;

  _ConsultaRepositorioEspia(this.consulta);

  @override
  Future<Consulta?> getDetalleConsulta(String id) async => consulta;

  @override
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    required List<Receta> recetas,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  }) async {
    escrituras++;
    guardado = odontograma;
    return const ResultadoGuardadoOdontograma();
  }

  @override
  Future<Map<String, TratamientoAplicadoDetalle>>
  getDetalleTratamientosAplicados(List<String> ids) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa en el test');
}

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CrearConsultaDoble extends _Vacio implements CrearConsultaUseCase {}

class _FinalizarConsultaDoble extends _Vacio
    implements FinalizarConsultaUseCase {}

class _StorageDoble extends _Vacio implements SupabaseStorageHelper {}

class _CitaRepositorioDoble extends _Vacio implements CitaRepository {}

class _TratamientoRepositorioDoble extends _Vacio
    implements TratamientoRepository {
  @override
  Future<List<Tratamiento>> getCatalogoTratamientos() async => const [];
}

class _DiagnosticoRepositorioDoble extends _Vacio
    implements DiagnosisRepository {
  @override
  Future<List<Diagnosis>> getCatalogoCompleto() async => [
    Diagnosis(
      id: 'diag-caries',
      nombre: 'Cariada',
      descripcion: '',
      severidadDefault: SeveridadDiagnosis.moderada,
      alcance: Alcance.puntual,
      categoria: CategoriaDiagnosis.caries,
      claveOdontograma: 'cariada',
    ),
  ];
}

class _CondicionesDoble extends _Vacio implements GetCondicionesPaciente {
  @override
  Future<List<Condicion>> call(String pacienteId) async => const [];
}

class _PacienteCubitDoble extends Cubit<PacienteState>
    implements PacienteCubit {
  _PacienteCubitDoble() : super(PacienteLoading());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ConsultaCubit _cubit(_ConsultaRepositorioEspia repo) => ConsultaCubit(
  _CrearConsultaDoble(),
  _FinalizarConsultaDoble(),
  _StorageDoble(),
  _CitaRepositorioDoble(),
  repo,
);

void main() {
  group('Persistencia del odontodiagrama', () {
    test(
      'se guarda junto al resto de la consulta, en una sola escritura',
      () async {
        final repo = _ConsultaRepositorioEspia(_consultaConOdontograma());
        final cubit = _cubit(repo);
        addTearDown(cubit.close);

        await cubit.reanudarConsulta(consultaId: _consultaId);
        expect(cubit.state, isA<ConsultaIniciada>());

        cubit.actualizarEvaluacionOdontologica(
          EvaluacionOdontologica.vacia
              .alternar(
                16,
                EstadoClinicoDental.cariada,
                superficie: TipoSuperficie.oclusal,
              )
              .conTejido(TejidoBlando.lengua, 'Sin alteración aparente'),
        );

        await cubit.guardarParcial();

        expect(repo.escrituras, 1);
        final json = repo.guardado!.evaluacionToJson();
        expect(json['hallazgos'], isEmpty);
        expect(json['tejidos_blandos'], {'lengua': 'Sin alteración aparente'});
      },
    );

    test('reanudar una consulta recupera lo anotado antes', () async {
      final previa = EvaluacionOdontologica.vacia.alternar(
        48,
        EstadoClinicoDental.extraccionIndicada,
      );
      final repo = _ConsultaRepositorioEspia(
        _consultaConOdontograma(evaluacion: previa),
      );
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await cubit.reanudarConsulta(consultaId: _consultaId);

      final estado = cubit.state as ConsultaIniciada;
      expect(
        estado.consulta.odontograma!.evaluacion.de(48).single.estado,
        EstadoClinicoDental.extraccionIndicada,
      );
    });
  });

  group('WorkspaceConsulta', () {
    late _ConsultaRepositorioEspia repo;
    late ConsultaCubit cubit;

    setUp(() {
      // La vista elegida se recuerda durante la sesión, así que cada test debe
      // partir del mismo estado.
      vistaOdontogramaPreferida.value = VistaOdontograma.formulario;
      if (sl.isRegistered<TratamientoRepository>()) {
        sl.unregister<TratamientoRepository>();
      }
      if (sl.isRegistered<GetCondicionesPaciente>()) {
        sl.unregister<GetCondicionesPaciente>();
      }
      sl.registerFactory<TratamientoRepository>(
        _TratamientoRepositorioDoble.new,
      );
      sl.registerFactory<GetCondicionesPaciente>(_CondicionesDoble.new);
      sl.registerFactory<DiagnosisRepository>(_DiagnosticoRepositorioDoble.new);
      repo = _ConsultaRepositorioEspia(_consultaConOdontograma());
      cubit = _cubit(repo);
    });

    tearDown(() async {
      await cubit.close();
      if (sl.isRegistered<TratamientoRepository>()) {
        sl.unregister<TratamientoRepository>();
      }
      if (sl.isRegistered<GetCondicionesPaciente>()) {
        sl.unregister<GetCondicionesPaciente>();
      }
      if (sl.isRegistered<DiagnosisRepository>()) {
        sl.unregister<DiagnosisRepository>();
      }
    });

    Future<void> montar(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await cubit.reanudarConsulta(consultaId: _consultaId);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ConsultaCubit>.value(value: cubit),
              BlocProvider<PacienteCubit>(create: (_) => _PacienteCubitDoble()),
            ],
            child: const Scaffold(body: WorkspaceConsulta(citaId: 'cita-1')),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ofrece las dos vistas y solo dibuja la elegida', (
      tester,
    ) async {
      await montar(tester);

      // Una sola tarjeta con el conmutador, no dos diagramas apilados.
      expect(find.byType(SelectorVistaOdontograma), findsOneWidget);
      expect(find.text('Formulario'), findsOneWidget);
      expect(find.text('Arcada'), findsOneWidget);

      // La vista por defecto es el formulario del papel.
      expect(find.text('ODONTODIAGRAMA'), findsOneWidget);
      expect(find.byType(OdontogramWidget), findsNothing);

      await tester.tap(find.text('Arcada'));
      await tester.pumpAndSettle();

      expect(find.byType(OdontogramWidget), findsOneWidget);
      expect(find.text('ODONTODIAGRAMA'), findsNothing);
    });

    testWidgets('el odontodiagrama anterior del paciente llega a la vista', (
      tester,
    ) async {
      final previo = EvaluacionOdontologica.vacia.alternar(
        36,
        EstadoClinicoDental.perdida,
      );
      repo = _ConsultaRepositorioEspia(
        _consultaConOdontograma(historico: previo),
      );
      await cubit.close();
      cubit = _cubit(repo);

      await montar(tester);

      final diagrama = tester.widget<OdontodiagramaWidget>(
        find.byType(OdontodiagramaWidget),
      );
      expect(
        diagrama.historico.de(36).single.estado,
        EstadoClinicoDental.perdida,
      );
      // La capa histórica se anuncia, para que el trazo tenue no se confunda
      // con algo anotado hoy.
      expect(
        find.text('El trazo tenue viene de consultas anteriores.'),
        findsOneWidget,
      );
    });

    testWidgets('anotar una pieza llega al estado de la consulta', (
      tester,
    ) async {
      await montar(tester);

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pump();

      final estado = cubit.state as ConsultaIniciada;
      final diagnostico = estado.consulta.odontograma!.dientes
          .firstWhere((diente) => diente.fdiCode == 16)
          .diagnosis
          .single;
      expect(diagnostico.claveOdontograma, 'cariada');
      expect(diagnostico.superficie, TipoSuperficie.oclusal);

      // Anotar deja la consulta pendiente y el autoguardado la escribe solo,
      // sin que el doctor pulse nada.
      expect(estado.guardado, EstadoGuardado.pendiente);
      await tester.pump(ConsultaCubit.esperaAutoguardado);
      await tester.pumpAndSettle();
      expect(repo.escrituras, 1);
      expect((cubit.state as ConsultaIniciada).guardado, EstadoGuardado.alDia);
    });
  });
}
