import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// Defecto D15 (QA 1 ago 2026): «Mis Citas del Día» no tenía forma de alternar
/// entre toda la clínica y la agenda propia. El filtro es de **vista**: sólo
/// recorta lo que el rol ya podía ver, nunca amplía el alcance.

Doctor _doctor(String id, String nombre) => Doctor(
  id: id,
  nombre: nombre,
  apellido: 'Apellido',
  birthDate: DateTime(1985, 1, 1),
  govID: '001-0000000-0',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: nombre.toLowerCase(),
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

Cita _cita(String id, Doctor doctor) => Cita(
  id: id,
  persona: _paciente(),
  doctor: doctor,
  date: DateTime(2026, 8, 1, 9),
  duracionMinutos: 30,
  esEmergencia: false,
  estado: EstadoCita.programada,
);

void main() {
  final ada = _doctor('doc-ada', 'Ada');
  final beto = _doctor('doc-beto', 'Beto');

  CitaCubitLoaded estado(List<Cita> citas) => CitaCubitLoaded(
    citas: citas,
    focusedDay: DateTime(2026, 8, 1),
    selectedDay: DateTime(2026, 8, 1),
    viewMode: CalendarioViewMode.diaria,
  );

  test('el selector se puebla con los doctores del alcance, sin repetir', () {
    final s = estado([
      _cita('c1', ada),
      _cita('c2', beto),
      _cita('c3', ada),
    ]);

    expect(s.doctoresDelAlcance.map((d) => d.id), ['doc-ada', 'doc-beto']);
  });

  test('sin filtro se ven todas las citas del alcance', () {
    final s = estado([_cita('c1', ada), _cita('c2', beto)]);

    expect(s.doctorIdFiltro, isNull);
    expect(s.citas, hasLength(2));
    expect(s.citasSinFiltrar, hasLength(2));
  });

  test('filtrar deja las de un doctor y conserva el alcance completo', () {
    final todas = [_cita('c1', ada), _cita('c2', beto)];
    final s = estado(
      todas,
    ).copyWith(citas: [todas.first], doctorIdFiltro: () => 'doc-ada');

    expect(s.citas.single.id, 'c1');
    // El alcance no se pierde: quitar el filtro debe poder devolver las dos.
    expect(s.citasSinFiltrar, hasLength(2));
    expect(s.doctoresDelAlcance, hasLength(2));
  });

  test('con un solo doctor en el alcance no hay nada que elegir', () {
    final s = estado([_cita('c1', ada), _cita('c2', ada)]);

    expect(s.doctoresDelAlcance, hasLength(1));
  });
}
