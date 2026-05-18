import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRemoteDatasource {
  final SupabaseClient client;

  PacienteRemoteDatasource(this.client);

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final pacientesRes = await client
          .from('pacientes')
          .select(
            '*, personas(nombre, apellido, fecha_nacimiento, cedula, estatus)',
          )
          .filter('deleted_at', 'is', null);

      final contactosRes = await client
          .from('contactos')
          .select()
          .filter('deleted_at', 'is', null);

      final contactosByPersonaId = <String, Map<String, dynamic>>{};
      for (final c in contactosRes as List) {
        final map = c as Map<String, dynamic>;
        final pid = map['persona_id'] as String?;
        if (pid != null) contactosByPersonaId[pid] = map;
      }

      final lista = (pacientesRes as List).map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final contacto = contactosByPersonaId[map['id'] as String];
        if (contacto != null) map['contactos'] = [contacto];
        return PacienteModel.fromJson(map);
      }).toList();
      lista.addAll(_pacientesPrueba);
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener lista de pacientes: ${e.message}');
    }
  }

  static final _pacientesPrueba = [
    PacienteModel(
      id: 'test-001',
      nombre: 'Carlos',
      apellido: 'Méndez',
      birthDate: DateTime(1990, 3, 15),
      govID: '001-1234567-8',
      contacto: ContactoModel(
        id: 'c-001',
        email: 'carlos.mendez@email.com',
        numeroTelefono: '809-555-0101',
        direccion: 'Calle Primera #10, Santo Domingo',
      ),
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Ingeniero',
      referencia: 'Dr. López',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'test-002',
      nombre: 'María',
      apellido: 'Rodríguez',
      birthDate: DateTime(1998, 7, 22),
      govID: '002-9876543-1',
      contacto: ContactoModel(
        id: 'c-002',
        email: 'maria.rodriguez@email.com',
        numeroTelefono: '829-555-0202',
        direccion: 'Av. Winston Churchill, Santiago',
      ),
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      record: RecordModel.empty(),
      trabajo: 'Maestra',
      referencia: 'Familiar',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'test-003',
      nombre: 'Pedro',
      apellido: 'Almonte',
      birthDate: DateTime(1975, 11, 5),
      govID: '003-1112223-4',
      contacto: ContactoModel(
        id: 'c-003',
        email: 'pedro.almonte@email.com',
        numeroTelefono: '849-555-0303',
        direccion: 'Los Prados, Santo Domingo Norte',
      ),
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Contador',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.emergencia,
    ),
  ];

  Future<void> addPaciente(PacienteModel paciente) async {
    try {
      final data = paciente.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      if (!(_isValidUuid(data['id']))) {
        data.remove('id');
      }

      await client.from('pacientes').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo paciente: ${e.message}');
    }
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    try {
      final data = paciente.toJson();
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();

      await client.from('pacientes').update(data).eq('id', paciente.id!);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar paciente: ${e.message}');
    }
  }

  Future<void> deletePaciente(String id) async {
    try {
      await client
          .from('pacientes')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar paciente: ${e.message}');
    }
  }

  Future<PacienteModel> getPacienteById(String id) async {
    if (!_isValidUuid(id)) {
      final local = _pacientesPrueba.where((p) => p.id == id).firstOrNull;
      if (local != null) return local;
      throw Exception('Paciente de prueba con id "$id" no encontrado.');
    }

    try {
      final res = await client
          .from('pacientes')
          .select(
            '*, personas(nombre, apellido, fecha_nacimiento, cedula, estatus)',
          )
          .eq('id', id)
          .single();

      final map = Map<String, dynamic>.from(res as Map);
      return PacienteModel.fromJson(map);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener paciente: ${e.message}');
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }
}
