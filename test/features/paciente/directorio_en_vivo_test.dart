import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

import '../../support/senales_de_prueba.dart';

/// MU-3 · El paciente creado por el asistente existe para el doctor sin
/// reiniciar sesión, y la búsqueda activa no parpadea ni se pierde cuando la
/// señal recarga el directorio.

Paciente _paciente(String id, String nombre, String apellido) => Paciente(
  id: id,
  nombre: nombre,
  apellido: apellido,
  birthDate: DateTime(1990, 1, 1),
  govID: 'ced-$id',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  tipoPaciente: TipoPaciente.integrado,
  trabajo: '',
  referencia: '',
  citas: const [],
  record: Record(
    pacienteId: id,
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

class _PacienteRepoFalso extends Fake implements IPacienteRepository {
  List<Paciente> pacientes = [];
  Failure? fallo;

  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() async {
    final f = fallo;
    if (f != null) return Left(f);
    return Right(List.of(pacientes));
  }
}

class _ConsultaRepoFalso extends Fake implements ConsultaRepository {}

class _CitaRepoFalso extends Fake implements CitaRepository {}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _PacienteRepoFalso repo;
  late FabricaCanalesFalsa fabrica;
  late PacienteCubit cubit;

  setUp(() {
    repo = _PacienteRepoFalso()
      ..pacientes = [_paciente('p1', 'Zoila', 'Gómez')];
    fabrica = FabricaCanalesFalsa();
    cubit = PacienteCubit(
      repo,
      _ConsultaRepoFalso(),
      _CitaRepoFalso(),
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );
  });

  tearDown(() => cubit.close());

  test('la persona creada en otra sesión aparece en el directorio', () async {
    await cubit.load();
    expect((cubit.state as PacienteLoaded).todos, hasLength(1));

    repo.pacientes = [
      _paciente('p1', 'Zoila', 'Gómez'),
      _paciente('p2', 'Rita', 'Peralta'),
    ];
    fabrica.cambios['personas']!();
    await _asentar();

    final estado = cubit.state as PacienteLoaded;
    expect(estado.todos, hasLength(2));
    expect(estado.filtrados, hasLength(2));
  });

  test('la búsqueda activa se re-aplica sobre la lista fresca', () async {
    repo.pacientes = [
      _paciente('p1', 'Zoila', 'Gómez'),
      _paciente('p2', 'Rita', 'Peralta'),
    ];
    await cubit.load();
    cubit.search('gómez');
    expect((cubit.state as PacienteLoaded).filtrados, hasLength(1));

    repo.pacientes = [
      _paciente('p1', 'Zoila', 'Gómez'),
      _paciente('p2', 'Rita', 'Peralta'),
      _paciente('p3', 'Juan', 'Gómez'),
    ];
    fabrica.cambios['pacientes']!();
    await _asentar();

    final estado = cubit.state as PacienteLoaded;
    expect(
      estado.filtrados.map((p) => p.id),
      ['p1', 'p3'],
      reason: 'el filtro «gómez» debe incluir al Gómez recién creado',
    );
    expect(estado.todos, hasLength(3));
  });

  test('el detalle abierto no se pisa por la señal del directorio', () async {
    await cubit.load();
    // Simula estar dentro de una ficha: el estado ya no es la lista.
    cubit.emit(PacienteDetailLoaded(_paciente('p1', 'Zoila', 'Gómez')));

    fabrica.cambios['personas']!();
    await _asentar();

    expect(cubit.state, isA<PacienteDetailLoaded>());
  });

  test('si la recarga por señal falla, la lista queda como estaba', () async {
    await cubit.load();
    repo.fallo = const ServerFailure('sin red');

    fabrica.cambios['personas']!();
    await _asentar();

    final estado = cubit.state as PacienteLoaded;
    expect(estado.todos, hasLength(1));
  });
}
