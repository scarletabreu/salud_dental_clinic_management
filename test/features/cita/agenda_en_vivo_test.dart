import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/transicion_estado_invalida.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// MU-1 · La agenda del día se mantiene sola: lo que otras sesiones hacen con
/// las citas de hoy (llegadas, inicios de consulta, reagendas) llega por el
/// stream y se integra pasando por los mismos filtros de alcance y de vista
/// que la carga normal.

Doctor _doctor(String id) => Doctor(
  id: id,
  nombre: 'Doc-$id',
  apellido: 'Apellido',
  birthDate: DateTime(1985, 1, 1),
  govID: '001-0000000-0',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: id,
  specialty: 'General',
  assistants: const [],
);

Paciente _paciente() => Paciente(
  id: 'pac-1',
  nombre: 'Zoila',
  apellido: 'Perez',
  birthDate: DateTime(1995, 5, 5),
  govID: '001-1111111-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  tipoPaciente: TipoPaciente.integrado,
  trabajo: '',
  referencia: '',
  citas: const [],
  record: Record(
    pacienteId: 'pac-1',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

Cita _citaHoy(
  String id,
  String doctorId, {
  EstadoCita estado = EstadoCita.programada,
  int hora = 9,
}) {
  final hoy = DateTime.now();
  return Cita(
    id: id,
    persona: _paciente(),
    doctor: _doctor(doctorId),
    date: DateTime(hoy.year, hoy.month, hoy.day, hora),
    duracionMinutos: 30,
    esEmergencia: false,
    estado: estado,
  );
}

Cita _citaManana(String id, String doctorId) {
  final manana = DateTime.now().add(const Duration(days: 1));
  return Cita(
    id: id,
    persona: _paciente(),
    doctor: _doctor(doctorId),
    date: DateTime(manana.year, manana.month, manana.day, 10),
    duracionMinutos: 30,
    esEmergencia: false,
    estado: EstadoCita.programada,
  );
}

class _RepoEnVivo extends Fake implements CitaRepository {
  _RepoEnVivo(this.iniciales);

  final List<Cita> iniciales;
  final emisor = StreamController<List<Cita>>.broadcast();
  Object? errorDeTransicion;

  @override
  Future<List<Cita>> getCitas({DateTime? desde, DateTime? hasta}) async =>
      iniciales;

  @override
  Future<List<Cita>> getCitasByDoctor(
    String doctorId, {
    DateTime? desde,
    DateTime? hasta,
  }) async => iniciales.where((c) => c.doctor.id == doctorId).toList();

  @override
  Stream<List<Cita>> watchCitasDeHoy() => emisor.stream;

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    final error = errorDeTransicion;
    if (error != null) throw error;
  }
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 1));

void main() {
  test('la llegada marcada en otra sesión aparece sin refrescar', () async {
    final repo = _RepoEnVivo([_citaHoy('c1', 'doc-a')]);
    final cubit = CitaCubit(repo);
    await cubit.load();

    repo.emisor.add([_citaHoy('c1', 'doc-a', estado: EstadoCita.enEspera)]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.citas.single.estado, EstadoCita.enEspera);
    await cubit.close();
  });

  test('una cita nueva de hoy entra sola a la agenda', () async {
    final repo = _RepoEnVivo([_citaHoy('c1', 'doc-a')]);
    final cubit = CitaCubit(repo);
    await cubit.load();

    repo.emisor.add([
      _citaHoy('c1', 'doc-a'),
      _citaHoy('c2', 'doc-a', hora: 11),
    ]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.citas, hasLength(2));
    await cubit.close();
  });

  test('un evento fuera del alcance del asistente no aparece', () async {
    final repo = _RepoEnVivo([_citaHoy('c1', 'doc-a')]);
    final cubit = CitaCubit(repo);
    await cubit.load(doctorIdsPermitidos: ['doc-a']);

    repo.emisor.add([
      _citaHoy('c1', 'doc-a'),
      _citaHoy('c2', 'doc-b', hora: 11),
    ]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(
      estado.citas.map((c) => c.id),
      ['c1'],
      reason: 'el recorte en memoria del asistente vale también para eventos',
    );
    await cubit.close();
  });

  test('una ráfaga de emisiones deja el último estado, sin duplicar', () async {
    final repo = _RepoEnVivo([_citaHoy('c1', 'doc-a')]);
    final cubit = CitaCubit(repo);
    await cubit.load();

    repo.emisor.add([_citaHoy('c1', 'doc-a', estado: EstadoCita.enEspera)]);
    repo.emisor.add([_citaHoy('c1', 'doc-a', estado: EstadoCita.enConsulta)]);
    repo.emisor.add([_citaHoy('c1', 'doc-a', estado: EstadoCita.completada)]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.citas, hasLength(1));
    expect(estado.citas.single.estado, EstadoCita.completada);
    await cubit.close();
  });

  test('las citas de otros días no se pierden al integrar las de hoy',
      () async {
    final repo = _RepoEnVivo([
      _citaHoy('c1', 'doc-a'),
      _citaManana('c2', 'doc-a'),
    ]);
    final cubit = CitaCubit(repo);
    await cubit.load();

    repo.emisor.add([_citaHoy('c1', 'doc-a', estado: EstadoCita.enEspera)]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.citas, hasLength(2));
    expect(
      estado.citas.firstWhere((c) => c.id == 'c2').estado,
      EstadoCita.programada,
    );
    await cubit.close();
  });

  test('el filtro de vista se conserva cuando llega un evento', () async {
    final repo = _RepoEnVivo([
      _citaHoy('c1', 'doc-a'),
      _citaHoy('c2', 'doc-b', hora: 11),
    ]);
    final cubit = CitaCubit(repo);
    await cubit.load();
    cubit.filtrarPorDoctor('doc-a');

    repo.emisor.add([
      _citaHoy('c1', 'doc-a', estado: EstadoCita.enEspera),
      _citaHoy('c2', 'doc-b', hora: 11, estado: EstadoCita.enEspera),
    ]);
    await _asentar();

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.citas.map((c) => c.id), ['c1']);
    expect(
      estado.citasSinFiltrar,
      hasLength(2),
      reason: 'quitar el filtro debe recuperar el alcance completo y fresco',
    );
    await cubit.close();
  });

  test('un conflicto de transición corrige la tarjeta al estado real',
      () async {
    final repo = _RepoEnVivo([_citaHoy('c1', 'doc-a')]);
    final cubit = CitaCubit(repo);
    await cubit.load();

    repo.errorDeTransicion = const TransicionEstadoInvalida(
      EstadoCita.cancelada,
      EstadoCita.enEspera,
    );
    await cubit.cambiarEstadoCita('c1', EstadoCita.enEspera);

    final estado = cubit.state as CitaCubitLoaded;
    expect(estado.errorMessage, contains('Cancelada'));
    expect(
      estado.citas.single.estado,
      EstadoCita.cancelada,
      reason: 'la tarjeta debe mostrar lo que hay en la base, no lo intentado',
    );
    await cubit.close();
  });
}
