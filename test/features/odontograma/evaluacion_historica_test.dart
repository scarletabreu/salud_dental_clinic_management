import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

/// Datasource que devuelve las filas ya ordenadas como las devuelve Postgres:
/// de la consulta más reciente a la más antigua.
class _DatasourceDoble extends _Vacio implements ConsultaRemoteDatasource {
  final List<Map<String, dynamic>> diagnosticos;
  final List<Map<String, dynamic>> evaluaciones;
  String? pacienteRecibido;
  String? exclusionRecibida;

  _DatasourceDoble({
    this.diagnosticos = const [],
    this.evaluaciones = const [],
  });

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosticosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) async {
    pacienteRecibido = pacienteId;
    exclusionRecibida = excluyendoConsultaId;
    return diagnosticos;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEvaluacionesPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) async => evaluaciones;
}

/// Una fila de `diagnosticos_aplicados` como llega del embed de Supabase.
Map<String, dynamic> _fila({
  required String consultaId,
  required int fdi,
  required String clave,
  String? superficie,
}) => {
  'diagnosis_id': 'diag-$clave',
  'severidad': 'moderada',
  'fecha_aplicacion': DateTime(2026, 1, 10).toIso8601String(),
  'notas': '',
  'consulta_id': consultaId,
  'superficie': superficie,
  'diagnosis': {'nombre': clave, 'clave_odontograma': clave},
  'diente': {'fdi_code': fdi},
};

class _RepoQueFalla extends _Vacio implements ConsultaRepository {
  @override
  Future<List<Consulta>> getHistorialPaciente(String pacienteId) async =>
      throw Exception('sin red');
}

class _RepoVacio extends _Vacio implements ConsultaRepository {
  @override
  Future<List<Consulta>> getHistorialPaciente(String pacienteId) async =>
      const [];
}

class _PacienteRepoDoble extends _Vacio implements IPacienteRepository {
  @override
  Future<Either<Failure, Paciente>> getPacienteById(String id) async => Right(
    Paciente(
      id: id,
      nombre: 'Ana',
      apellido: 'Pérez',
      birthDate: DateTime(1990, 1, 1),
      govID: '001-0000000-0',
      contactos: const [],
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      record: Record(
        pacienteId: id,
        tipoSangre: TipoSangre.desconocido,
        condiciones: const [],
        cirugiasPrevias: const [],
        historialFamiliar: '',
      ),
      trabajo: '',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
  );
}

class _CitaRepoDoble extends _Vacio implements CitaRepository {}

void main() {
  group('ConsultaRepositoryImpl.getEvaluacionHistorica', () {
    test('consolida los diagnósticos anteriores del paciente', () async {
      final datasource = _DatasourceDoble(
        diagnosticos: [
          _fila(
            consultaId: 'c-nueva',
            fdi: 16,
            clave: 'restaurada',
            superficie: 'oclusal',
          ),
          _fila(consultaId: 'c-vieja', fdi: 16, clave: 'cariada'),
          _fila(consultaId: 'c-vieja', fdi: 36, clave: 'perdida'),
        ],
        evaluaciones: [
          {
            'evaluacion_clinica': {
              'tejidos_blandos': {'lengua': 'Sin alteración'},
            },
          },
          {
            'evaluacion_clinica': {
              'tejidos_blandos': {'lengua': 'Úlcera', 'encias': 'Gingivitis'},
            },
          },
        ],
      );
      final repo = ConsultaRepositoryImpl(remoteDataSource: datasource);

      final historica = await repo.getEvaluacionHistorica(
        'pac-1',
        excluyendoConsultaId: 'consulta-de-hoy',
      );

      expect(datasource.pacienteRecibido, 'pac-1');
      expect(datasource.exclusionRecibida, 'consulta-de-hoy');
      // Sobre la pieza 16 gana la consulta más reciente.
      final restaurada = historica.de(16).single;
      expect(restaurada.estado, EstadoClinicoDental.restaurada);
      expect(restaurada.superficies, {TipoSuperficie.oclusal});
      // Lo que solo dijo la consulta antigua se conserva.
      expect(historica.de(36).single.estado, EstadoClinicoDental.perdida);
      expect(historica.tejidosBlandos[TejidoBlando.lengua], 'Sin alteración');
      expect(historica.tejidosBlandos[TejidoBlando.encias], 'Gingivitis');
    });

    test('una pieza guarda todo lo que dijo la consulta que manda', () async {
      final repo = ConsultaRepositoryImpl(
        remoteDataSource: _DatasourceDoble(
          diagnosticos: [
            _fila(
              consultaId: 'c-nueva',
              fdi: 16,
              clave: 'cariada',
              superficie: 'oclusal',
            ),
            _fila(
              consultaId: 'c-nueva',
              fdi: 16,
              clave: 'cariada',
              superficie: 'mesial',
            ),
            _fila(
              consultaId: 'c-nueva',
              fdi: 16,
              clave: 'pulpectomia_pulpotomia',
            ),
          ],
        ),
      );

      final hallazgos = await repo.getEvaluacionHistorica('pac-1');

      expect(hallazgos.de(16), hasLength(2));
      expect(
        hallazgos
            .de(16)
            .firstWhere((h) => h.estado == EstadoClinicoDental.cariada)
            .superficies,
        {TipoSuperficie.oclusal, TipoSuperficie.mesial},
      );
    });

    test('un paciente sin consultas previas no tiene capa histórica', () async {
      final repo = ConsultaRepositoryImpl(remoteDataSource: _DatasourceDoble());

      final historica = await repo.getEvaluacionHistorica('pac-1');

      expect(historica.estaVacia, isTrue);
    });

    test('un diagnóstico sin clave del catálogo no se dibuja', () async {
      final repo = ConsultaRepositoryImpl(
        remoteDataSource: _DatasourceDoble(
          diagnosticos: [
            {
              'diagnosis_id': 'diag-sin-clave',
              'severidad': 'leve',
              'fecha_aplicacion': DateTime(2026, 1, 10).toIso8601String(),
              'notas': '',
              'consulta_id': 'c-vieja',
              'diagnosis': {'nombre': 'Sensibilidad'},
              'diente': {'fdi_code': 48},
            },
            _fila(consultaId: 'c-vieja', fdi: 48, clave: 'extraccion_indicada'),
          ],
        ),
      );

      final historica = await repo.getEvaluacionHistorica('pac-1');

      expect(
        historica.de(48).single.estado,
        EstadoClinicoDental.extraccionIndicada,
      );
    });
  });

  group('PacienteCubit y el historial', () {
    test('un fallo al leer el historial se marca en el estado', () async {
      final cubit = PacienteCubit(
        _PacienteRepoDoble(),
        _RepoQueFalla(),
        _CitaRepoDoble(),
      );
      addTearDown(cubit.close);

      await cubit.loadById('pac-1');

      final estado = cubit.state as PacienteDetailLoaded;
      expect(estado.historialNoDisponible, isTrue);
      expect(estado.paciente.record.consultas, isEmpty);
    });

    test('un historial vacío no se marca como fallo', () async {
      final cubit = PacienteCubit(
        _PacienteRepoDoble(),
        _RepoVacio(),
        _CitaRepoDoble(),
      );
      addTearDown(cubit.close);

      await cubit.loadById('pac-1');

      final estado = cubit.state as PacienteDetailLoaded;
      expect(estado.historialNoDisponible, isFalse);
      expect(estado.paciente.record.consultas, isEmpty);
    });
  });
}
