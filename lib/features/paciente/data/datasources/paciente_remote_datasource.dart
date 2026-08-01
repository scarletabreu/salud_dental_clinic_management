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

  /// Nombres para listados, desde la vista de directorio (HFX-QA-100).
  ///
  /// `directorio_pacientes` sólo expone id, nombre y apellido y la lee todo el
  /// personal clínico, así que resuelve el nombre incluso de un paciente cuya
  /// ficha completa el rol no puede abrir.
  Future<Map<String, String>> getNombresPacientes(List<String> ids) async {
    if (ids.isEmpty) return {};

    final res = await client
        .from('directorio_pacientes')
        .select('id, nombre, apellido')
        .inFilter('id', ids);

    return {
      for (final fila in (res as List).whereType<Map<String, dynamic>>())
        if (fila['id'] is String)
          fila['id'] as String: [fila['nombre'], fila['apellido']]
              .whereType<String>()
              .join(' ')
              .trim(),
    };
  }

  /// El listado se arma con **consultas planas**, no con el embed anidado.
  ///
  /// `pacientes → personas → persona_contactos → contactos` depende de que
  /// PostgREST infiera bien tres saltos de relación, y en producción no lo
  /// hacía: el error salía nombrando `pacientes_seguro`, una vista creada a
  /// mano que volvía ambigua la inferencia (defecto D3). `_fetchPacienteModel`
  /// ya evitaba el embed a propósito para la ficha individual; aquí se aplica
  /// el mismo patrón al listado, resolviendo cada nivel por su clave.
  ///
  /// El coste son tres viajes en vez de uno, todos por índice de clave
  /// primaria o foránea.
  Future<List<PacienteModel>> getPacientes() async {
    final pacientesRes = await client
        .from('pacientes')
        .select('*')
        .filter('deleted_at', 'is', null);

    final pacientes = (pacientesRes as List)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
    if (pacientes.isEmpty) return [];

    final ids = pacientes.map((p) => p['id'] as String).toList();

    final personasRes = await client
        .from('personas')
        .select('*')
        .inFilter('id', ids);
    final personasPorId = {
      for (final fila in (personasRes as List).whereType<Map<String, dynamic>>())
        fila['id'] as String: Map<String, dynamic>.from(fila),
    };

    // Un solo salto de relación (`persona_contactos → contactos`), que es el
    // que PostgREST sí resuelve sin ambigüedad.
    final relacionesRes = await client
        .from('persona_contactos')
        .select('persona_id, contactos(*)')
        .inFilter('persona_id', ids);
    final relacionesPorPersona = <String, List<dynamic>>{};
    for (final fila in (relacionesRes as List).whereType<Map<String, dynamic>>()) {
      final personaId = fila['persona_id'] as String?;
      if (personaId == null) continue;
      relacionesPorPersona.putIfAbsent(personaId, () => []).add(fila);
    }

    final lista = <PacienteModel>[];
    for (final paciente in pacientes) {
      final id = paciente['id'] as String;
      final persona = personasPorId[id];
      // Sin persona no hay ficha que mostrar: la fila está incompleta en la
      // base o el rol no puede leerla. Se omite en vez de romper el listado.
      if (persona == null) continue;

      final relaciones = relacionesPorPersona[id];
      if (relaciones != null && relaciones.isNotEmpty) {
        persona['persona_contacto'] = relaciones;
      }
      paciente['personas'] = persona;
      lista.add(PacienteModel.fromJson(paciente));
    }

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  String _generoDb(Genero g) =>
      g == Genero.noPrefiereDecir ? Genero.otro.name : g.name;

  /// Contactos de la ficha tal como los espera la base: el primero es el
  /// principal y el resto quedan como contactos de emergencia.
  List<Map<String, dynamic>> _contactosPayload(PacienteModel paciente) => [
    for (var i = 0; i < paciente.contactos.length; i++)
      {
        if (_isValidUuid(paciente.contactos[i].id))
          'id': paciente.contactos[i].id,
        'email': paciente.contactos[i].email,
        'numero_telefono': paciente.contactos[i].numeroTelefono,
        'direccion': paciente.contactos[i].direccion,
        'es_emergencia': paciente.contactos[i].esEmergencia || i > 0,
      },
  ];

  /// Devuelve el id del paciente creado (el mismo de su persona) para que
  /// quien lo registra pueda seguir trabajando sobre él sin releer la lista:
  /// agendarle la cita del mismo flujo o subirle la foto de perfil.
  ///
  /// El alta es una sola llamada porque es una sola transacción: persona,
  /// contactos, ficha y expediente entran juntos o no entra ninguno. Antes eran
  /// cuatro escrituras encadenadas con una limpieza manual en el `catch`, que
  /// una caída de red entre dos de ellas se saltaba dejando huérfanos (y la
  /// cédula ocupada para siempre). La foto sigue fuera: solo puede subirse
  /// cuando ya hay un id confirmado.
  Future<String> addPaciente(PacienteModel paciente) async {
    if (paciente.contactos.isEmpty) {
      throw Exception('El paciente debe tener al menos un contacto.');
    }

    final respuesta = await client.rpc(
      'registrar_paciente',
      params: {
        'p_payload': {
          'nombre': paciente.nombre,
          'apellido': paciente.apellido,
          'fecha_nacimiento': paciente.birthDate.toIso8601String(),
          'cedula': paciente.govID,
          'estatus': paciente.estatus.name,
          'genero': _generoDb(paciente.genero),
          'tipo_paciente': paciente.tipoPaciente.name,
          'trabajo': paciente.trabajo,
          'referencia': paciente.referencia,
          'peso': paciente.peso,
          'altura': paciente.altura,
          'contactos': _contactosPayload(paciente),
          // El expediente nace con el paciente: sin él, un asistente no podría
          // crearlo después (la RLS de `records` es clínica) y la primera
          // consulta se encontraba una ficha a medias.
          'record': {
            'tipo_sangre': paciente.record.tipoSangre.dbValue,
            'cant_hijos': paciente.record.cantHijos,
            'cirugias_previas': paciente.record.cirugiasPrevias,
            'historial_familiar': paciente.record.historialFamiliar,
          },
          'condiciones': [
            for (final condicion in paciente.record.condiciones)
              if (condicion.id != null) {'condicion_id': condicion.id},
          ],
        },
      },
    );

    return (respuesta as Map)['paciente_id'] as String;
  }

  /// [version] es la que el formulario cree tener. Si otro actor guardó primero,
  /// la base responde `CL019` y no escribe nada, en vez de pisar su edición.
  Future<void> updatePaciente(PacienteModel paciente, {int? version}) async {
    final pacienteId = paciente.id;
    if (pacienteId == null) {
      throw Exception('No se puede actualizar un paciente sin ID.');
    }

    await client.rpc(
      'actualizar_paciente',
      params: {
        'p_paciente_id': pacienteId,
        'p_version': version,
        'p_payload': {
          'nombre': paciente.nombre,
          'apellido': paciente.apellido,
          'fecha_nacimiento': paciente.birthDate.toIso8601String(),
          'cedula': paciente.govID,
          'estatus': paciente.estatus.name,
          'genero': _generoDb(paciente.genero),
          'tipo_paciente': paciente.tipoPaciente.name,
          'trabajo': paciente.trabajo,
          'referencia': paciente.referencia,
          'peso': paciente.peso,
          'altura': paciente.altura,
          // Las columnas `foto_*` no viajan a propósito: su única ruta de
          // escritura es `PacienteFotoStorage`, que las mantiene en sincronía
          // con el objeto de Storage. Incluirlas borraba la foto cada vez que
          // se editaba cualquier otro dato de la ficha.
          'contactos': _contactosPayload(paciente),
        },
      },
    );
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
    await client.from('pacientes').insert({
      'id': normalizedId,
      'genero': Genero.otro.name,
      'tipo_paciente': TipoPaciente.integrado.name,
      'trabajo': '',
      'referencia': '',
      'created_at': now,
      'updated_at': now,
    });

    // Se relee por el camino plano en vez de con un `select` anidado sobre el
    // propio insert: es el mismo motivo que en `getPacientes` (defecto D3).
    final creadoModel = await _fetchPacienteModel(normalizedId);
    if (creadoModel == null) {
      throw StateError(
        'La ficha del paciente se creó pero no se pudo releer. '
        'Vuelve a abrirla desde el listado.',
      );
    }
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
