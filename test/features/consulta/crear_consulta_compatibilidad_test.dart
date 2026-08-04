import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `crear_consulta_completa` tiene **una sola** firma viva.
///
/// Convivían dos sobrecargas, y ambas con EXECUTE para `authenticated`: la
/// anterior no recibía `p_tipo_atencion`, así que una evaluación registrada por
/// ella se guardaba como consulta de ejecución y falseaba el expediente
/// (F5-03 del audit del 2 ago 2026). `audit_006` retiró la vieja de la base y
/// el cliente dejó de tener un camino que la mantuviera viva.
void main() {
  final client = SupabaseClient('https://example.supabase.co', 'test-key');

  PostgrestException firmaAusente() => const PostgrestException(
    message:
        'Could not find the function public.crear_consulta_completa'
        '(p_cita_id, p_dientes, p_doctor_id, p_documentos, p_fecha, '
        'p_motivo_consulta, p_paciente_id, p_temp_condiciones, '
        'p_tipo_atencion) in the schema cache',
    code: 'PGRST202',
  );

  test('el tipo de atención viaja siempre, sin reintento sin él', () async {
    final llamadas = <Map<String, dynamic>>[];
    final datasource = ConsultaRemoteDatasourceImpl(
      supabaseClient: client,
      crearConsultaRpc: (params) async {
        llamadas.add(Map<String, dynamic>.from(params));
        return 'consulta-1';
      },
    );

    final id = await datasource.crearConsultaCompleta({
      'p_paciente_id': 'paciente-1',
      'p_tipo_atencion': 'evaluacion',
    });

    expect(id, 'consulta-1');
    expect(llamadas, hasLength(1));
    expect(llamadas.single['p_tipo_atencion'], 'evaluacion');
  });

  test('si falta la firma, el fallo se ve; no se cae a la vieja', () async {
    var llamadas = 0;
    final datasource = ConsultaRemoteDatasourceImpl(
      supabaseClient: client,
      crearConsultaRpc: (_) {
        llamadas++;
        throw firmaAusente();
      },
    );

    await expectLater(
      datasource.crearConsultaCompleta({
        'p_paciente_id': 'paciente-1',
        'p_tipo_atencion': 'evaluacion',
      }),
      throwsA(
        isA<PostgrestException>().having((e) => e.code, 'code', 'PGRST202'),
      ),
    );
    expect(
      llamadas,
      1,
      reason: 'un segundo intento sin `p_tipo_atencion` guardaría la '
          'evaluación como consulta de ejecución',
    );
  });

  test('otros errores de PostgREST se propagan tal cual', () async {
    var llamadas = 0;
    final datasource = ConsultaRemoteDatasourceImpl(
      supabaseClient: client,
      crearConsultaRpc: (_) {
        llamadas++;
        throw const PostgrestException(
          message: 'permission denied',
          code: '42501',
        );
      },
    );

    await expectLater(
      datasource.crearConsultaCompleta({'p_tipo_atencion': 'consulta'}),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
    );
    expect(llamadas, 1);
  });
}
