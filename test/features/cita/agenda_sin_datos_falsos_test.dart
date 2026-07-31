import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/data/repositories/cita_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/transicion_estado_invalida.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

/// SD-161. El datasource devolvía una agenda inventada cuando la consulta
/// fallaba o venía vacía, así que un corte de red o un error de RLS se veía
/// como una agenda llena. Estas pruebas fijan el contrato contrario: la lista
/// que sale del repositorio es exactamente lo que hay en la base, y cualquier
/// fallo llega a la UI como `Failure` tipado.
class _DataSourceDoble extends Fake implements CitaRemoteDataSource {
  _DataSourceDoble({
    this.citas = const [],
    this.errorAlLeer,
    this.estadoActual,
    this.errorAlLeerEstado,
  });

  final List<CitaModel> citas;
  final Object? errorAlLeer;
  final EstadoCita? estadoActual;
  final Object? errorAlLeerEstado;

  final List<(String, EstadoCita)> estadosEscritos = [];

  @override
  Future<List<CitaModel>> fetchCitas() async {
    if (errorAlLeer != null) throw errorAlLeer!;
    return citas;
  }

  @override
  Future<EstadoCita> fetchEstadoCita(String id) async {
    if (errorAlLeerEstado != null) throw errorAlLeerEstado!;
    return estadoActual!;
  }

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    estadosEscritos.add((id, nuevoEstado));
  }
}

Doctor _doctor() => Doctor(
  id: '22222222-2222-2222-2222-222222222222',
  nombre: 'Bartolomé',
  apellido: 'Santana',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  specialty: 'Endodoncia',
  assistants: const [],
);

Persona _persona() => Persona(
  id: '11111111-1111-1111-1111-111111111111',
  nombre: 'Ana',
  apellido: 'Pérez',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: const [],
  estatus: EstatusPersona.activo,
);

CitaModel _cita() => CitaModel(
  id: '33333333-3333-3333-3333-333333333333',
  doctor: _doctor(),
  persona: _persona(),
  date: DateTime(2026, 8, 12, 9),
  duracionMinutos: 30,
  esEmergencia: false,
  estado: EstadoCita.programada,
);

void main() {
  tearDown(() => guardConnectivityCheck = null);

  group('getCitas no inventa datos', () {
    test('base vacía -> lista vacía, no una agenda de prueba', () async {
      final repo = CitaRepositoryImpl(remoteDataSource: _DataSourceDoble());

      expect(await repo.getCitas(), isEmpty);
    });

    test('fallo de red -> lanza NetworkFailure', () async {
      final repo = CitaRepositoryImpl(
        remoteDataSource: _DataSourceDoble(
          errorAlLeer: const SocketException('sin red'),
        ),
      );

      await expectLater(repo.getCitas(), throwsA(isA<NetworkFailure>()));
    });

    test(
      'fallo del servidor (RLS, tabla mal nombrada) -> ServerFailure',
      () async {
        final repo = CitaRepositoryImpl(
          remoteDataSource: _DataSourceDoble(
            errorAlLeer: StateError('relation "citas" does not exist'),
          ),
        );

        await expectLater(repo.getCitas(), throwsA(isA<ServerFailure>()));
      },
    );

    test('la lista devuelta es exactamente la de la base', () async {
      final cita = _cita();
      final repo = CitaRepositoryImpl(
        remoteDataSource: _DataSourceDoble(citas: [cita]),
      );

      final resultado = await repo.getCitas();
      expect(resultado, hasLength(1));
      expect(resultado.single.id, cita.id);
    });
  });

  group('updateCitaEstado ya no tolera ids desconocidos', () {
    test('valida la transición contra el estado real de la base', () async {
      final ds = _DataSourceDoble(estadoActual: EstadoCita.completada);
      final repo = CitaRepositoryImpl(remoteDataSource: ds);

      await expectLater(
        repo.updateCitaEstado(
          '33333333-3333-3333-3333-333333333333',
          EstadoCita.enConsulta,
        ),
        throwsA(isA<TransicionEstadoInvalida>()),
      );
      expect(ds.estadosEscritos, isEmpty);
    });

    test(
      'un id que no existe falla en vez de saltarse la validación',
      () async {
        final ds = _DataSourceDoble(
          errorAlLeerEstado: const ServerFailure('La cita t01 ya no existe.'),
        );
        final repo = CitaRepositoryImpl(remoteDataSource: ds);

        await expectLater(
          repo.updateCitaEstado('t01', EstadoCita.confirmada),
          throwsA(isA<ServerFailure>()),
        );
        expect(ds.estadosEscritos, isEmpty);
      },
    );

    test('una transición legal sí se escribe', () async {
      final ds = _DataSourceDoble(estadoActual: EstadoCita.programada);
      final repo = CitaRepositoryImpl(remoteDataSource: ds);

      await repo.updateCitaEstado(
        '33333333-3333-3333-3333-333333333333',
        EstadoCita.confirmada,
      );

      expect(ds.estadosEscritos, [
        ('33333333-3333-3333-3333-333333333333', EstadoCita.confirmada),
      ]);
    });
  });

  test('no queda ningún id sintético en el datasource de citas', () {
    final fuente = File(
      'lib/features/cita/data/datasources/cita_remote_datasources.dart',
    ).readAsStringSync();

    expect(fuente.contains('_citasPrueba'), isFalse);
    expect(fuente.contains('_docFernandez'), isFalse);
    expect(fuente.contains('_pacAlonso'), isFalse);
  });

  test('Cita sigue siendo el tipo que devuelve el repositorio', () async {
    final repo = CitaRepositoryImpl(
      remoteDataSource: _DataSourceDoble(citas: [_cita()]),
    );
    expect(await repo.getCitas(), isA<List<Cita>>());
  });
}
