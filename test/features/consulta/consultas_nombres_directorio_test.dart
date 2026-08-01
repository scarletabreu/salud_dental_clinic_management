import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/eliminar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

/// Defecto D4/D20 (QA 1 ago 2026). El listado de consultas resolvía los nombres
/// con una segunda llamada a `getPacientes()` y se **tragaba** el error con un
/// `fold((_) => [])`: todas las filas caían al literal `Paciente #<uuid>` sin
/// que nadie supiera por qué. Con el modelo de permisos de producción, un
/// doctor ve consultas de pacientes cuya ficha no puede abrir, así que eso
/// pasaba siempre.
class _ConsultaRepoDoble extends Fake implements ConsultaRepository {
  _ConsultaRepoDoble(this.consultas);
  final List<Consulta> consultas;

  @override
  Future<List<Consulta>> getConsultas() async => consultas;
}

class _PacienteRepoDoble extends Fake implements IPacienteRepository {
  _PacienteRepoDoble({this.nombres = const {}, this.failure});

  final Map<String, String> nombres;
  final Failure? failure;
  List<String>? idsPedidos;

  @override
  Future<Either<Failure, Map<String, String>>> getNombresPacientes(
    List<String> ids,
  ) async {
    idsPedidos = ids;
    if (failure != null) return Left(failure!);
    return Right(nombres);
  }

  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() async {
    throw StateError(
      'El listado de consultas no debe pedir la lista completa de pacientes: '
      'los nombres salen del directorio.',
    );
  }
}

class _DoctorRepoDoble extends Fake implements DoctorRepository {
  @override
  Future<List<Doctor>> getDoctores() async => const [];
}

class _EliminarDoble extends Fake implements EliminarConsultaUseCase {}

Consulta _consulta(String id, String pacienteId) => Consulta(
  id: id,
  pacienteId: pacienteId,
  doctorId: 'doc-1',
  fecha: DateTime(2026, 7, 30),
  motivoConsulta: 'Revisión',
);

ConsultasListCubit _cubit(IPacienteRepository pacientes, List<Consulta> cs) =>
    ConsultasListCubit(
      consultaRepository: _ConsultaRepoDoble(cs),
      pacienteRepository: pacientes,
      doctorRepository: _DoctorRepoDoble(),
      eliminarConsultaUseCase: _EliminarDoble(),
    );

void main() {
  test('los nombres salen del directorio, pidiendo sólo los ids necesarios', () async {
    final pacientes = _PacienteRepoDoble(
      nombres: {'pac-1': 'Zoila Pérez', 'pac-2': 'Luis Gómez'},
    );
    final cubit = _cubit(pacientes, [
      _consulta('c1', 'pac-1'),
      _consulta('c2', 'pac-2'),
      _consulta('c3', 'pac-1'),
    ]);

    await cubit.cargar();

    expect(pacientes.idsPedidos, unorderedEquals(['pac-1', 'pac-2']));
    final estado = cubit.state as ConsultasLoaded;
    expect(estado.nombrePaciente('pac-1'), 'Zoila Pérez');
    expect(estado.nombrePaciente('pac-2'), 'Luis Gómez');
  });

  test('un fallo al resolver nombres se propaga en vez de pintar uuids', () async {
    final pacientes = _PacienteRepoDoble(
      failure: const ServerFailure('Error al resolver los nombres'),
    );
    final cubit = _cubit(pacientes, [_consulta('c1', 'pac-1')]);

    await cubit.cargar();

    expect(cubit.state, isA<ConsultasError>());
  });

  test('un paciente ausente del directorio se dice con palabras, no con un uuid', () async {
    final pacientes = _PacienteRepoDoble(nombres: const {});
    final cubit = _cubit(pacientes, [_consulta('c1', 'pac-1')]);

    await cubit.cargar();

    final estado = cubit.state as ConsultasLoaded;
    expect(estado.nombrePaciente('pac-1'), 'Paciente no encontrado');
    expect(estado.nombrePaciente('pac-1'), isNot(contains('pac-1')));
  });
}
