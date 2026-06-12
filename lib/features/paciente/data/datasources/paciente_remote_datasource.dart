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

  /// `pacientes` comparte PK con `personas`; los contactos cuelgan de la
  /// persona vía la tabla puente `persona_contactos`.
  static const _selectPaciente =
      '*, personas(nombre, apellido, fecha_nacimiento, cedula, estatus, '
      'persona_contacto:persona_contactos(contactos(*)))';

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final pacientesRes = await client
          .from('pacientes')
          .select(_selectPaciente)
          .filter('deleted_at', 'is', null);

      final lista = (pacientesRes as List)
          .map((json) => PacienteModel.fromJson(json as Map<String, dynamic>))
          .toList();
      // Only include local mock patients when the backend returns no results,
      // so we don't mix test data with real data in production.
      if (lista.isEmpty) lista.addAll(_pacientesPrueba);
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener lista de pacientes: ${e.message}');
    }
  }

  // IDs p1-p6 must match CitaRemoteDataSource._citasPrueba so mock flows work end-to-end.
  static final _pacientesPrueba = [
    PacienteModel(
      id: 'p1',
      nombre: 'Pedro',
      apellido: 'Alonso',
      birthDate: DateTime(1985, 4, 10),
      govID: '001-1000001-0',
      contactos: [ContactoModel(
        id: 'c-p1',
        email: 'pedro.alonso@email.com',
        numeroTelefono: '809-555-0001',
        direccion: 'Calle Las Flores #1, Santo Domingo',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Médico',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'p2',
      nombre: 'María',
      apellido: 'Santos',
      birthDate: DateTime(1992, 8, 25),
      govID: '001-1000002-1',
      contactos: [ContactoModel(
        id: 'c-p2',
        email: 'maria.santos@email.com',
        numeroTelefono: '829-555-0002',
        direccion: 'Av. Independencia #22, Santiago',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      record: RecordModel.empty(),
      trabajo: 'Abogada',
      referencia: 'Dr. Fernández',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'p3',
      nombre: 'Juan',
      apellido: 'Méndez',
      birthDate: DateTime(1978, 2, 14),
      govID: '001-1000003-2',
      contactos: [ContactoModel(
        id: 'c-p3',
        email: 'juan.mendez@email.com',
        numeroTelefono: '849-555-0003',
        direccion: 'Los Alcarrizos, Santo Domingo Oeste',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Empresario',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.emergencia,
    ),
    PacienteModel(
      id: 'p4',
      nombre: 'Laura',
      apellido: 'Castillo',
      birthDate: DateTime(2000, 11, 3),
      govID: '001-1000004-3',
      contactos: [ContactoModel(
        id: 'c-p4',
        email: 'laura.castillo@email.com',
        numeroTelefono: '809-555-0004',
        direccion: 'Bella Vista, Santo Domingo',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      record: RecordModel.empty(),
      trabajo: 'Estudiante',
      referencia: 'Familiar',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'p5',
      nombre: 'Roberto',
      apellido: 'García',
      birthDate: DateTime(1970, 6, 20),
      govID: '001-1000005-4',
      contactos: [ContactoModel(
        id: 'c-p5',
        email: 'roberto.garcia@email.com',
        numeroTelefono: '829-555-0005',
        direccion: 'Naco, Santo Domingo',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Contador',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'p6',
      nombre: 'Sofía',
      apellido: 'Herrera',
      birthDate: DateTime(1995, 9, 8),
      govID: '001-1000006-5',
      contactos: [ContactoModel(
        id: 'c-p6',
        email: 'sofia.herrera@email.com',
        numeroTelefono: '849-555-0006',
        direccion: 'Piantini, Santo Domingo',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.femenino,
      record: RecordModel.empty(),
      trabajo: 'Diseñadora',
      referencia: 'Dr. Rodríguez',
      citas: const [],
      tipoPaciente: TipoPaciente.integrado,
    ),
    PacienteModel(
      id: 'test-001',
      nombre: 'Carlos',
      apellido: 'Méndez',
      birthDate: DateTime(1990, 3, 15),
      govID: '001-1234567-8',
      contactos: [ContactoModel(
        id: 'c-001',
        email: 'carlos.mendez@email.com',
        numeroTelefono: '809-555-0101',
        direccion: 'Calle Primera #10, Santo Domingo',
      )],
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
      contactos: [ContactoModel(
        id: 'c-002',
        email: 'maria.rodriguez@email.com',
        numeroTelefono: '829-555-0202',
        direccion: 'Av. Winston Churchill, Santiago',
      )],
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
      contactos: [ContactoModel(
        id: 'c-003',
        email: 'pedro.almonte@email.com',
        numeroTelefono: '849-555-0303',
        direccion: 'Los Prados, Santo Domingo Norte',
      )],
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: RecordModel.empty(),
      trabajo: 'Contador',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.emergencia,
    ),
  ];

  /// El enum `genero` de Postgres solo admite {masculino, femenino, otro};
  /// `noPrefiereDecir` (que sí existe en la app) se persiste como `otro`.
  String _generoDb(Genero g) =>
      g == Genero.noPrefiereDecir ? Genero.otro.name : g.name;

  /// Crea un paciente completo respetando el esquema de dos niveles:
  /// `contactos` → `personas` → `persona_contactos` → `pacientes`.
  /// La fila de `pacientes` comparte el `id` de la `persona` (PK compartida),
  /// por eso se inserta `personas` primero y se reutiliza su id.
  Future<void> addPaciente(PacienteModel paciente) async {
    if (paciente.contactos.isEmpty) {
      throw Exception('El paciente debe tener al menos un contacto.');
    }

    String? contactoId;
    String? personaId;
    try {
      final contacto = paciente.contactos.first;
      final contactoRes = await client
          .from('contactos')
          .insert({
            'email': contacto.email,
            'numero_telefono': contacto.numeroTelefono,
            'direccion': contacto.direccion,
          })
          .select('id')
          .single();
      contactoId = contactoRes['id'] as String;

      final personaRes = await client
          .from('personas')
          .insert({
            'nombre': paciente.nombre,
            'apellido': paciente.apellido,
            'fecha_nacimiento': paciente.birthDate.toIso8601String(),
            'cedula': paciente.govID,
            'estatus': paciente.estatus.name,
          })
          .select('id')
          .single();
      personaId = personaRes['id'] as String;

      await client.from('persona_contactos').insert({
        'persona_id': personaId,
        'contacto_id': contactoId,
        'es_principal': true,
      });

      final data = paciente.toJson()
        ..['id'] = personaId
        ..['genero'] = _generoDb(paciente.genero)
        ..['created_at'] = DateTime.now().toIso8601String()
        ..['updated_at'] = DateTime.now().toIso8601String();
      await client.from('pacientes').insert(data);
    } on PostgrestException catch (e) {
      // Rollback best-effort para no dejar filas huérfanas si algo falla
      // a mitad de camino.
      if (personaId != null) {
        await client
            .from('persona_contactos')
            .delete()
            .eq('persona_id', personaId);
        await client.from('personas').delete().eq('id', personaId);
      }
      if (contactoId != null) {
        await client.from('contactos').delete().eq('id', contactoId);
      }
      throw Exception('Error al registrar nuevo paciente: ${e.message}');
    }
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    try {
      final data = paciente.toJson();
      data.remove('id');
      data['genero'] = _generoDb(paciente.genero);
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
          .select(_selectPaciente)
          .eq('id', id)
          .single();

      final map = Map<String, dynamic>.from(res as Map);
      return PacienteModel.fromJson(map);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener paciente: ${e.message}');
    }
  }

  /// Devuelve el paciente cuya PK coincide con [personaId]; si la persona aún
  /// no es paciente (p. ej. se registró solo para agendar una cita), crea la
  /// fila de `pacientes` con valores por defecto. La PK de `pacientes` es la
  /// misma de `personas` (tabla de dos niveles).
  Future<PacienteModel> getOrCreateByPersonaId(String personaId) async {
    if (!_isValidUuid(personaId)) {
      // Citas de prueba referencian pacientes mock (p1-p6).
      return getPacienteById(personaId);
    }

    try {
      final existente = await client
          .from('pacientes')
          .select(_selectPaciente)
          .eq('id', personaId)
          .maybeSingle();
      if (existente != null) {
        return PacienteModel.fromJson(Map<String, dynamic>.from(existente));
      }

      final now = DateTime.now().toIso8601String();
      final creado = await client
          .from('pacientes')
          .insert({
            'id': personaId,
            'genero': Genero.otro.name,
            'tipo_paciente': TipoPaciente.integrado.name,
            'trabajo': '',
            'referencia': '',
            'created_at': now,
            'updated_at': now,
          })
          .select(_selectPaciente)
          .single();
      return PacienteModel.fromJson(Map<String, dynamic>.from(creado));
    } on PostgrestException catch (e) {
      throw Exception('Error al preparar el paciente de la consulta: ${e.message}');
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }
}
