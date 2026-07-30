import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final SupabaseClient supabase;
  static const _selectPerfilCompleto =
      '*, usuarios(*, personas(*, persona_contactos(*, contactos(*))))';

  UsuarioRemoteDataSourceImpl(this.supabase);

  @override
  User? getCurrentSupabaseUser() => supabase.auth.currentUser;

  @override
  String? getCurrentUserId() => supabase.auth.currentUser?.id;

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  bool isSessionActive() => supabase.auth.currentSession != null;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// La RPC recibe `auth.uid()` implícitamente: no hay forma de pedir el
  /// perfil de otro usuario, y la respuesta no contiene ninguna contraseña.
  @override
  Future<Map<String, dynamic>?> getPerfilActual() async {
    final filas = await supabase.rpc('perfil_actual') as List?;
    if (filas == null || filas.isEmpty) return null;
    return Map<String, dynamic>.from(filas.first as Map);
  }

  @override
  Future<Map<String, dynamic>?> getPerfilPorTabla({
    required String tabla,
    required String uuid,
    String selectColumns = '*',
  }) async {
    return await supabase
        .from(tabla)
        .select(selectColumns)
        .eq('id', uuid)
        .maybeSingle();
  }

  @override
  Future<List<dynamic>?> getPerfilesPorTabla({
    required String tabla,
    required String selectColumns,
  }) async {
    final response = await supabase.from(tabla).select(selectColumns);
    return response as List<dynamic>?;
  }

  @override
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  @override
  Future<String> crearUsuarioCompleto(Map<String, dynamic> payload) async {
    final res = await supabase.functions.invoke(
      'admin-crear-usuario',
      body: payload,
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Error al crear usuario');
    }
    return res.data['uuid'] as String;
  }

  @override
  Future<void> resetearPassword({
    required String targetUuid,
    required String nuevaPassword,
  }) async {
    final res = await supabase.functions.invoke(
      'admin-resetear-password',
      body: {'targetUuid': targetUuid, 'nuevaPassword': nuevaPassword},
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Error al resetear contraseña');
    }
  }

  @override
  Future<void> actualizarPersona(
    String personaId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('personas').update(data).eq('id', personaId);
  }

  @override
  Future<void> actualizarTelefonoPersona({
    required String personaId,
    required String telefono,
  }) async {
    final relacion = await supabase
        .from('persona_contactos')
        .select('contacto_id')
        .eq('persona_id', personaId)
        .eq('es_principal', true)
        .maybeSingle();

    if (relacion != null) {
      await supabase
          .from('contactos')
          .update({'numero_telefono': telefono})
          .eq('id', relacion['contacto_id']);
    } else {
      final nuevoContacto = await supabase
          .from('contactos')
          .insert({'numero_telefono': telefono, 'email': '', 'direccion': ''})
          .select('id')
          .single();

      await supabase.from('persona_contactos').insert({
        'persona_id': personaId,
        'contacto_id': nuevoContacto['id'],
        'tipo_contacto': 'personal',
        'es_principal': true,
      });
    }
  }

  @override
  Future<void> actualizarUsuarioBasico(
    String usuarioId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('usuarios').update(data).eq('id', usuarioId);
  }

  /// Cuenta citas donde este usuario es el doctor asignado y aún no están
  /// terminadas ni canceladas.
  @override
  Future<int> contarCitasPendientes(String doctorId) async {
    final response = await supabase
        .from('citas')
        .select('id')
        .eq('doctor_id', doctorId)
        .not('estado', 'in', '(TERMINADA,CANCELADA)');
    return (response as List).length;
  }

  /// Cuenta consultas de este doctor que no se han finalizado.
  @override
  Future<int> contarConsultasPendientes(String doctorId) async {
    final response = await supabase
        .from('consultas')
        .select('id')
        .eq('doctor_id', doctorId)
        .filter('fecha_fin', 'is', null);
    return (response as List).length;
  }

  /// Marca `deleted_at` en `usuarios`. El trigger en Supabase se encarga
  /// de cascadear hacia `doctor`/`asistente`/`admin` según corresponda.
  @override
  Future<void> desactivarUsuarioRemoto(String usuarioId) async {
    await supabase
        .from('usuarios')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', usuarioId);
  }

  @override
  Future<List<dynamic>?> getTodosAsistentes() async {
    final response = await supabase
        .from('asistentes')
        .select(_selectPerfilCompleto);
    return response as List<dynamic>?;
  }

  @override
  Future<List<String>> getAsistenteIdsAsignados(String doctorId) async {
    final response = await supabase
        .from('doctor_asistentes')
        .select('asistente_id')
        .eq('doctor_id', doctorId);
    return (response as List)
        .map((row) => row['asistente_id'] as String)
        .toList();
  }

  @override
  Future<void> reemplazarAsistentesDoctor(
    String doctorId,
    List<String> asistenteIds,
  ) async {
    await supabase.from('doctor_asistentes').delete().eq(
      'doctor_id',
      doctorId,
    );

    if (asistenteIds.isNotEmpty) {
      await supabase.from('doctor_asistentes').insert(
        asistenteIds
            .map((id) => {'doctor_id': doctorId, 'asistente_id': id})
            .toList(),
      );
    }
  }
}