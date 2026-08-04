import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// MU-1 · El Inicio recalcula sus tarjetas del día cuando la señal de agenda
/// avisa que las citas cambiaron en otra sesión.

class _CitaRepoFalso extends Fake implements CitaRepository {
  List<Cita> citas = [];

  @override
  Future<List<Cita>> getCitasByDoctor(
    String doctorId, {
    DateTime? desde,
    DateTime? hasta,
  }) async => citas;
}

class _PacienteRepoFalso extends Fake implements IPacienteRepository {
  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() async =>
      const Right([]);
}

class _MedicinaRepoFalso extends Fake implements IMedicinaRepository {
  @override
  Future<List<Medicina>> getCatalogoMedicinas() async => const [];
}

class _ConsumibleRepoFalso extends Fake implements ConsumibleRepository {}

class _CajaRepoFalso extends Fake implements CajaDiariaRepository {}

class _EquipoRepoFalso extends Fake implements EquipoRepository {}

class _FabricaFalsa implements FabricaCanalesSenal {
  final Map<String, void Function()> cambios = {};

  @override
  CanalSenal abrir(
    String tabla, {
    required void Function() onCambio,
    required void Function(EstadoCanalSenal estado) onEstado,
  }) {
    cambios[tabla] = onCambio;
    return _CanalFalso();
  }
}

class _CanalFalso implements CanalSenal {
  @override
  Future<void> cerrar() async {}
}

Cita _citaHoy(EstadoCita estado) {
  final hoy = DateTime.now();
  return Cita(
    id: 'c1',
    persona: Paciente(
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
    ),
    doctor: Doctor(
      id: 'doc-a',
      nombre: 'Delia',
      apellido: 'Clínica',
      birthDate: DateTime(1985, 9, 30),
      govID: '001-0000000-0',
      contactos: const <Contacto>[],
      estatus: EstatusPersona.activo,
      username: 'delia',
      specialty: 'Endodoncia',
      assistants: const [],
    ),
    date: DateTime(hoy.year, hoy.month, hoy.day, 9),
    duracionMinutos: 30,
    esEmergencia: false,
    estado: estado,
  );
}

void main() {
  test('la señal de agenda recalcula las tarjetas del día', () async {
    final citaRepo = _CitaRepoFalso()
      ..citas = [_citaHoy(EstadoCita.programada)];
    final fabrica = _FabricaFalsa();
    final senales = SenalesRealtime(
      fabrica: fabrica,
      debounce: Duration.zero,
    );

    final cubit = DashboardCubit(
      citaRepository: citaRepo,
      pacienteRepository: _PacienteRepoFalso(),
      medicinaRepository: _MedicinaRepoFalso(),
      consumibleRepository: _ConsumibleRepoFalso(),
      cajaDiariaRepository: _CajaRepoFalso(),
      equipoRepository: _EquipoRepoFalso(),
      senales: senales,
    );

    await cubit.load(roles: const [RolUsuario.doctor], doctorId: 'doc-a');
    expect((cubit.state as DashboardLoaded).citasPendientes, 1);
    expect((cubit.state as DashboardLoaded).citasEnEspera, 0);

    // Recepción marca la llegada en otra sesión: cambia la base y llega la señal.
    citaRepo.citas = [_citaHoy(EstadoCita.enEspera)];
    fabrica.cambios['citas']!();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final estado = cubit.state as DashboardLoaded;
    expect(estado.citasEnEspera, 1);
    expect(estado.citasPendientes, 0);

    await cubit.close();
    await senales.detener();
  });
}
