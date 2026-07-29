import 'dart:typed_data';
import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/models/record_condicion_model.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRemoteDatasource {
  final SupabaseClient client;

  PacienteRemoteDatasource(this.client);

  static const _selectPaciente =
      '*, personas(nombre, apellido, fecha_nacimiento, cedula, estatus, '
      'persona_contacto:persona_contactos(contactos(*)))';

  Future<String> uploadFotoPaciente({
    required String pacienteId,
    required Uint8List bytes,
  }) async {
    final path = '$pacienteId/perfil.jpg';

    await client.storage
        .from('fotos-pacientes')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return path;
  }

  Future<List<PacienteModel>> getPacientes() async {
    final pacientesRes = await client
        .from('pacientes')
        .select(_selectPaciente)
        .filter('deleted_at', 'is', null);

    final lista = (pacientesRes as List)
        .map((json) => PacienteModel.fromJson(json as Map<String, dynamic>))
        .toList();

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  String _generoDb(Genero g) =>
      g == Genero.noPrefiereDecir ? Genero.otro.name : g.name;

  /// Devuelve el id del paciente creado (el mismo de su persona) para que
  /// quien lo registra pueda seguir trabajando sobre él sin releer la lista:
  /// agendarle la cita del mismo flujo o subirle la foto de perfil.
  Future<String> addPaciente(PacienteModel paciente) async {
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
      return personaId;
    } on PostgrestException {
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
      rethrow;
    }
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    final pacienteId = paciente.id;
    if (pacienteId == null) {
      throw Exception('No se puede actualizar un paciente sin ID.');
    }

    final now = DateTime.now().toIso8601String();

    await client
        .from('personas')
        .update({
          'nombre': paciente.nombre,
          'apellido': paciente.apellido,
          'fecha_nacimiento': paciente.birthDate.toIso8601String(),
          'cedula': paciente.govID,
          'estatus': paciente.estatus.name,
          'updated_at': now,
        })
        .eq('id', pacienteId);

    await client
        .from('pacientes')
        .update({
          'genero': _generoDb(paciente.genero),
          'tipo_paciente': paciente.tipoPaciente.name,
          'trabajo': paciente.trabajo,
          'referencia': paciente.referencia,
          'peso': paciente.peso,
          'altura': paciente.altura,
          // Las columnas `foto_*` se omiten a propósito: su única ruta de
          // escritura es `PacienteFotoStorage`, que las mantiene en sincronía
          // con el objeto de Storage. Incluirlas aquí borraba la foto cada vez
          // que se editaba cualquier otro dato de la ficha.
          'updated_at': now,
        })
        .eq('id', pacienteId);

    for (int i = 0; i < paciente.contactos.length; i++) {
      final contacto = paciente.contactos[i];
      final isPrincipal = i == 0;
      final isEmergencia = contacto.esEmergencia || i > 0;

      if (contacto.id != null && _isValidUuid(contacto.id)) {
        await client
            .from('contactos')
            .update({
              'email': contacto.email,
              'numero_telefono': contacto.numeroTelefono,
              'direccion': contacto.direccion,
              'updated_at': now,
            })
            .eq('id', contacto.id!);
      } else if (contacto.numeroTelefono.trim().isNotEmpty) {
        final nuevoRes = await client
            .from('contactos')
            .insert({
              'email': contacto.email,
              'numero_telefono': contacto.numeroTelefono,
              'direccion': contacto.direccion,
            })
            .select('id')
            .single();

        final nuevoContactoId = nuevoRes['id'] as String;

        await client.from('persona_contactos').insert({
          'persona_id': pacienteId,
          'contacto_id': nuevoContactoId,
          'es_principal': isPrincipal,
          'es_emergencia': isEmergencia,
        });
      }
    }
  }

  Future<void> deletePaciente(String id) async {
    final now = DateTime.now().toIso8601String();
    await client
        .from('pacientes')
        .update({'deleted_at': now, 'updated_at': now})
        .eq('id', id);

    await client
        .from('personas')
        .update({'deleted_at': now, 'updated_at': now})
        .eq('id', id);
  }

  Future<PacienteModel> getPacienteById(String id) async {
    final normalizedId = _normalizeId(id);

    final pacienteModel = await _fetchPacienteModel(normalizedId);
    if (pacienteModel != null) {
      final record = await _loadOrCreateRecord(pacienteModel.id!);
      return pacienteModel.copyWithModel(record: record);
    }

    throw Exception('Paciente con id "$normalizedId" no encontrado.');
  }

  Future<bool> esPersonaSinFichaClinica(String personaId) async {
    final normalizedId = _normalizeId(personaId);

    final enPacientes = await client
        .from('pacientes')
        .select('id')
        .eq('id', normalizedId)
        .maybeSingle();
    if (enPacientes != null) return false;
    return true;
  }

  Future<PacienteModel> getOrCreateByPersonaId(String personaId) async {
    final normalizedId = _normalizeId(personaId);
    final pacienteModel = await _fetchPacienteModel(normalizedId);
    if (pacienteModel != null) {
      final record = await _loadOrCreateRecord(pacienteModel.id!);
      return pacienteModel.copyWithModel(record: record);
    }

    final now = DateTime.now().toIso8601String();
    final creado = await client
        .from('pacientes')
        .insert({
          'id': normalizedId,
          'genero': Genero.otro.name,
          'tipo_paciente': TipoPaciente.integrado.name,
          'trabajo': '',
          'referencia': '',
          'created_at': now,
          'updated_at': now,
        })
        .select(_selectPaciente)
        .single();

    final creadoModel = PacienteModel.fromJson(
      Map<String, dynamic>.from(creado),
    );
    final record = await _loadOrCreateRecord(creadoModel.id!);
    return creadoModel.copyWithModel(record: record);
  }

  Future<RecordModel> _loadOrCreateRecord(String pacienteId) async {
    try {
      final data = await client
          .from('records')
          .select('*')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (data != null) {
        final record = RecordModel.fromJson(Map<String, dynamic>.from(data));
        if (record.id != null) {
          final condicionesRes = await client
              .from('record_condicion')
              .select('*, condiciones(*)')
              .eq('record_id', record.id!);

          final condiciones = <CondicionModel>[];
          final detallesCondiciones = <RecordCondicionModel>[];
          for (final item in condicionesRes) {
            Map<String, dynamic>? condicionJson;
            if (item['condiciones'] is Map<String, dynamic>) {
              condicionJson = item['condiciones'] as Map<String, dynamic>?;
            } else if (item['condicion'] is Map<String, dynamic>) {
              condicionJson = item['condicion'] as Map<String, dynamic>?;
            } else if (item.containsKey('id') && item.containsKey('nombre')) {
              condicionJson = Map<String, dynamic>.from(item);
            }

            if (condicionJson != null) {
              condiciones.add(CondicionModel.fromJson(condicionJson));
              detallesCondiciones.add(
                RecordCondicionModel.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }

          return RecordModel.fromEntity(
            record.copyWith(
              condiciones: condiciones,
              detallesCondiciones: detallesCondiciones,
            ),
          );
        }

        return record;
      }

      final emptyRecord = RecordModel(
        pacienteId: pacienteId,
        tipoSangre: TipoSangre.desconocido,
        condiciones: const [],
        cirugiasPrevias: const [],
        historialFamiliar: '',
      );
      final insertData = emptyRecord.toJson();
      insertData.remove('condiciones');
      final created = await client
          .from('records')
          .insert(insertData)
          .select('*')
          .single();

      return RecordModel.fromJson(Map<String, dynamic>.from(created));
    } on PostgrestException {
      rethrow;
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }

  String _normalizeId(String id) {
    final trimmed = id.trim();
    return _isValidUuid(trimmed) ? trimmed.toLowerCase() : trimmed;
  }

  Future<PacienteModel?> _fetchPacienteModel(String id) async {
    try {
      final pacienteRow = await client
          .from('pacientes')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (pacienteRow == null) return null;

      final personaRow = await client
          .from('personas')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (personaRow == null) return null;

      final personaContactos = await client
          .from('persona_contactos')
          .select('contactos(*)')
          .eq('persona_id', id);

      final map = Map<String, dynamic>.from(pacienteRow);
      map['personas'] = Map<String, dynamic>.from(personaRow);
      if (personaContactos.isNotEmpty) {
        map['personas']!['persona_contacto'] = personaContactos;
      }
      return PacienteModel.fromJson(map);
    } on PostgrestException catch (_) {
      return null;
    }
  }
}
