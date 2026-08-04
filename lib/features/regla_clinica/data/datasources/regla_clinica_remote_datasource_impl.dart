import 'package:salud_dental_clinic_management/features/regla_clinica/data/datasources/regla_clinica_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReglaClinicaRemoteDatasourceImpl implements ReglaClinicaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ReglaClinicaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchReglasVigentes() async {
    // Por RPC y no por `select`: la marca `editable` depende del tipo y no es
    // una columna. Calcularla en el cliente la duplicaría en dos sitios.
    final filas = await supabaseClient.rpc('reglas_clinicas_vigentes');
    return [
      for (final fila in (filas as List? ?? const []))
        Map<String, dynamic>.from(fila as Map),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCatalogoSignosVitales() async {
    final filas = await supabaseClient
        .from('catalogo_signos_vitales')
        .select('codigo, etiqueta, unidad, minimo_posible, maximo_posible, decimales')
        .order('orden');
    return [
      for (final fila in filas) Map<String, dynamic>.from(fila),
    ];
  }

  @override
  Future<Map<String, dynamic>> publicarRegla({
    required String codigo,
    required Map<String, dynamic> parametros,
    String? severidad,
    String? accion,
    String? nota,
  }) async {
    final resultado = await supabaseClient.rpc(
      'publicar_regla_clinica',
      params: {
        'p_codigo': codigo,
        'p_parametros': parametros,
        'p_severidad': severidad,
        'p_accion': accion,
        'p_nota': nota,
      },
    );
    return Map<String, dynamic>.from(resultado as Map);
  }
}
