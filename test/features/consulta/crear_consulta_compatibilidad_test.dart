import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient('https://example.supabase.co', 'test-key');

  PostgrestException firmaNuevaAusente() => const PostgrestException(
    message:
        'Could not find the function public.crear_consulta_completa'
        '(p_cita_id, p_dientes, p_doctor_id, p_documentos, p_fecha, '
        'p_motivo_consulta, p_paciente_id, p_temp_condiciones, '
        'p_tipo_atencion) in the schema cache',
    code: 'PGRST202',
  );

  test(
    'la consulta usa temporalmente la firma anterior si falta la nueva',
    () async {
      final llamadas = <Map<String, dynamic>>[];
      final datasource = ConsultaRemoteDatasourceImpl(
        supabaseClient: client,
        crearConsultaRpc: (params) async {
          llamadas.add(Map<String, dynamic>.from(params));
          if (llamadas.length == 1) throw firmaNuevaAusente();
          return 'consulta-1';
        },
      );

      final id = await datasource.crearConsultaCompleta({
        'p_paciente_id': 'paciente-1',
        'p_tipo_atencion': 'consulta',
      });

      expect(id, 'consulta-1');
      expect(llamadas, hasLength(2));
      expect(llamadas.first['p_tipo_atencion'], 'consulta');
      expect(llamadas.last, isNot(contains('p_tipo_atencion')));
    },
  );

  test(
    'una evaluación nunca se guarda como consulta por compatibilidad',
    () async {
      final datasource = ConsultaRemoteDatasourceImpl(
        supabaseClient: client,
        crearConsultaRpc: (_) => Future<dynamic>.error(firmaNuevaAusente()),
      );

      await expectLater(
        datasource.crearConsultaCompleta({
          'p_paciente_id': 'paciente-1',
          'p_tipo_atencion': 'evaluacion',
        }),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.message,
            'message',
            contains('migraciones pendientes'),
          ),
        ),
      );
    },
  );

  test('otros errores de PostgREST no activan la compatibilidad', () async {
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
      throwsA(
        isA<PostgrestException>().having(
          (error) => error.code,
          'code',
          '42501',
        ),
      ),
    );
    expect(llamadas, 1);
  });
}
