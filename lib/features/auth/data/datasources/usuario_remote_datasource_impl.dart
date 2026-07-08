import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final SupabaseClient supabase;

  UsuarioRemoteDataSourceImpl(this.supabase);

  @override
  User? getCurrentSupabaseUser() => supabase.auth.currentUser;

  @override
  String? getCurrentUserId() => supabase.auth.currentUser?.id;

  @override
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Error al cerrar sesión: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cerrar sesión: $e');
    }
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
    try {
      final res = await supabase.functions.invoke(
        'admin-crear-usuario',
        body: payload,
      );
      if (res.status != 200) {
        throw Exception(res.data?['error'] ?? 'Error al crear usuario');
      }
      return res.data['uuid'] as String;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  @override
  Future<void> resetearPassword({
    required String targetUuid,
    required String nuevaPassword,
  }) async {
    try {
      final res = await supabase.functions.invoke(
        'admin-resetear-password',
        body: {'targetUuid': targetUuid, 'nuevaPassword': nuevaPassword},
      );
      if (res.status != 200) {
        throw Exception(res.data?['error'] ?? 'Error al resetear contraseña');
      }
    } catch (e) {
      throw Exception('Error al resetear contraseña: $e');
    }
  }

  @override
  Future<void> actualizarPersona(
    String personaId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabase.from('personas').update(data).eq('id', personaId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar persona: ${e.message}');
    }
  }

  @override
  Future<void> actualizarTelefonoPersona({
    required String personaId,
    required String telefono,
  }) async {
    try {
      final relacion = await supabase
          .from('persona_contacto')
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

        await supabase.from('persona_contacto').insert({
          'persona_id': personaId,
          'contacto_id': nuevoContacto['id'],
          'tipo_contacto': 'personal',
          'es_principal': true,
        });
      }
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar el teléfono: ${e.message}');
    }
  }

  @override
  Future<void> actualizarUsuarioBasico(
    String usuarioId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabase.from('usuarios').update(data).eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar usuario: ${e.message}');
    }
  }
}
