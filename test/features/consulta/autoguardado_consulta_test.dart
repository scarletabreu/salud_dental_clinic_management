import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/finalizar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

class _StorageDoble extends _Vacio implements SupabaseStorageHelper {}

class _CitaRepoDoble extends _Vacio implements CitaRepository {}

class _ConsultaRepoDoble extends _Vacio implements ConsultaRepository {
  _ConsultaRepoDoble({required this.consulta});

  final Consulta consulta;

  int guardados = 0;
  Odontograma? ultimoOdontograma;
  Map<int, List<String>> idsADevolver = const {};
  bool falla = false;

  @override
  Future<Consulta?> getDetalleConsulta(String id) async => consulta;

  @override
  Future<Map<int, List<String>>> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    required List recetas,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  }) async {
    guardados++;
    ultimoOdontograma = odontograma;
    if (falla) throw Exception('sin red');
    return idsADevolver;
  }
}

Consulta _consultaEnCurso({bool finalizada = false}) => Consulta(
  id: 'c-1',
  pacienteId: 'p-1',
  doctorId: 'd-1',
  fecha: DateTime(2026, 7, 24),
  finalizada: finalizada,
  odontograma: Odontograma(
    consultaId: 'c-1',
    dientes: [
      Diente(odontogramaId: 'o-1', fdiCode: 16, superficies: const []),
    ],
  ),
);

ConsultaCubit _cubitCon(_ConsultaRepoDoble repo) => ConsultaCubit(
  CrearConsultaUseCase(repo),
  FinalizarConsultaUseCase(repo),
  _StorageDoble(),
  _CitaRepoDoble(),
  repo,
);

final _resina = Tratamiento(
  id: 't-1',
  nombre: 'Resina compuesta',
  descripcion: '',
  costo: 2500,
  alcance: Alcance.puntual,
  contraindicaciones: const [],
);

void main() {
  group('autoguardado de la consulta', () {
    test('un cambio queda pendiente y se guarda solo', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

      // Sin tocar nada más: el trabajo aún no está a salvo y se avisa.
      expect(
        (cubit.state as ConsultaIniciada).guardado,
        EstadoGuardado.pendiente,
      );
      expect(repo.guardados, 0);

      await Future<void>.delayed(
        ConsultaCubit.esperaAutoguardado + const Duration(milliseconds: 200),
      );

      expect(repo.guardados, 1);
      expect((cubit.state as ConsultaIniciada).guardado, EstadoGuardado.alDia);
      expect(repo.ultimoOdontograma!.dientes.single.tratamientos, hasLength(1));
    });

    test('los ids que devuelve la BD se sellan sobre el estado', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
        ..idsADevolver = {
          16: ['ta-1'],
        };
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);
      await cubit.guardarParcial();

      final tratamiento = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single
          .tratamientos
          .single;
      // Con el id sellado, el siguiente guardado actualiza esa fila en vez de
      // insertar un duplicado.
      expect(tratamiento.id, 'ta-1');
    });

    test('si el guardado falla, el trabajo sigue en memoria y se avisa', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())..falla = true;
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);
      await cubit.guardarParcial();

      final estado = cubit.state as ConsultaIniciada;
      expect(estado.guardado, EstadoGuardado.fallido);
      // Lo importante: no se perdió nada y el doctor sigue en su consulta.
      expect(estado.consulta.odontograma!.dientes.single.tratamientos, hasLength(1));
    });

    test('una consulta ya finalizada no se puede reanudar', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso(finalizada: true));
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);

      await cubit.reanudarConsulta(consultaId: 'c-1');

      expect(cubit.state, isA<ConsultaError>());
      expect(
        (cubit.state as ConsultaError).message,
        contains('ya fue finalizada'),
      );
    });
  });
}
