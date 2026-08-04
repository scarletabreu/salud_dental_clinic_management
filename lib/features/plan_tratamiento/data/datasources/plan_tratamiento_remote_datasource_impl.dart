import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/datasources/plan_tratamiento_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlanTratamientoRemoteDatasourceImpl
    implements PlanTratamientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  PlanTratamientoRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectPlan =
      '*, items:items_plan_tratamiento(*, tratamiento:tratamientos(id, nombre, costo, alcance))';

  @override
  Future<String> insertPlan(Map<String, dynamic> data) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    final fila = await supabaseClient
        .from('planes_tratamiento')
        .insert({...data, 'created_at': ahora, 'updated_at': ahora})
        .select('id')
        .single();
    return fila['id'] as String;
  }

    @override
  Future<List<Map<String, dynamic>>> fetchResumenPorPlan(
    String planId,
  ) async {
    final response = await supabaseClient
        .from('resumen_actividad_plan')
        .select()
        .eq('plan_id', planId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResumenPorPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('resumen_actividad_plan')
        .select()
        .eq('paciente_id', pacienteId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> updatePlan(String id, Map<String, dynamic> data) async {
    await supabaseClient
        .from('planes_tratamiento')
        .update({
          ...data,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> insertItems(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return const [];
    final ahora = DateTime.now().toUtc().toIso8601String();
    final filas = await supabaseClient
        .from('items_plan_tratamiento')
        .insert([
          for (final item in items)
            {...item, 'created_at': ahora, 'updated_at': ahora},
        ])
        .select('*, tratamiento:tratamientos(id, nombre, costo, alcance)');
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<Map<String, dynamic>> updateItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    final fila = await supabaseClient
        .from('items_plan_tratamiento')
        .update({
          ...data,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('*, tratamiento:tratamientos(id, nombre, costo, alcance)')
        .single();
    return Map<String, dynamic>.from(fila);
  }

  @override
  Future<void> deleteItem(String id) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    await supabaseClient
        .from('items_plan_tratamiento')
        .update({'deleted_at': ahora, 'updated_at': ahora})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlanesPorPaciente(
    String pacienteId,
  ) async {
    final filas = await supabaseClient
        .from('planes_tratamiento')
        .select(_selectPlan)
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha_propuesta', ascending: false);
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<Map<String, dynamic>?> fetchPlanPorConsulta(String consultaId) async {
    final fila = await supabaseClient
        .from('planes_tratamiento')
        .select(_selectPlan)
        .eq('consulta_origen_id', consultaId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return fila == null ? null : Map<String, dynamic>.from(fila);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchItemsEjecutables(
    String pacienteId,
  ) async {
    // Lo que el paciente ya aceptó y todavía no se cierra: es la bandeja de
    // trabajo de la próxima consulta.
    final filas = await supabaseClient
        .from('items_plan_tratamiento')
        .select(
          '*, tratamiento:tratamientos(id, nombre, costo, alcance), '
          'diente:dientes(id, fdi_code), '
          'plan:planes_tratamiento!inner(id, paciente_id, deleted_at)',
        )
        .eq('plan.paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .isFilter('plan.deleted_at', null)
        .inFilter('estado', const ['aceptado', 'pendiente', 'en_proceso'])
        .order('orden');
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<Map<String, dynamic>> registrarConsentimiento({
    required String planId,
    required String decision,
    required String persona,
    required String metodo,
    String relacion = 'titular',
    String? motivo,
  }) async {
    final respuesta = await supabaseClient.rpc(
      'registrar_consentimiento_plan',
      params: {
        'p_plan_id': planId,
        'p_decision': decision,
        'p_persona': persona,
        'p_metodo': metodo,
        'p_relacion': relacion,
        'p_motivo': motivo,
      },
    );
    return Map<String, dynamic>.from(respuesta as Map);
  }
}
