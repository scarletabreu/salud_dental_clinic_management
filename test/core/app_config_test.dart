import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('acepta configuración pública HTTPS por ambiente', () {
      final config = AppConfig.validated(
        environment: 'production',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_example',
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabasePublishableKey, 'sb_publishable_example');
    });

    test('acepta Supabase local solo para desarrollo', () {
      final config = AppConfig.validated(
        environment: 'dev',
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: 'local-anon-key',
      );

      expect(config.environment, AppEnvironment.development);
    });

    test('rechaza variables ausentes o un ambiente desconocido', () {
      expect(
        () => AppConfig.validated(
          environment: '',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validated(
          environment: 'staging',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validated(
          environment: 'production',
          supabaseUrl: '',
          supabasePublishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validated(
          environment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: '',
        ),
        throwsStateError,
      );
    });

    test('rechaza HTTP remoto y claves secretas', () {
      expect(
        () => AppConfig.validated(
          environment: 'test',
          supabaseUrl: 'http://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validated(
          environment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_secret_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validated(
          environment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey:
              'header.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
        ),
        throwsStateError,
      );
    });

    test('distingue el ambiente vacío del ambiente desconocido', () {
      // El mensaje es lo que ve quien ejecuta sin `--dart-define`: tiene que
      // decir que la variable falta, no que su valor esté mal escrito.
      expect(
        () => AppEnvironment.parse('  '),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Falta APP_ENVIRONMENT.',
          ),
        ),
      );
      expect(
        () => AppEnvironment.parse('staging'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('debe ser development, test o production'),
          ),
        ),
      );
    });

    test(
      'sin variables inyectadas el arranque falla y lo declara como ausencia',
      () {
        // Es exactamente el estado de un `flutter run` sin
        // `--dart-define-from-file`: `main()` necesita las dos señales para
        // elegir el mensaje correcto en lugar de dejar la página en blanco.
        expect(AppConfig.sinConfiguracionInyectada, isTrue);
        expect(AppConfig.fromEnvironment, throwsStateError);
      },
      // La suite se ejecuta sin variables; si alguien se las pasa, el caso deja
      // de aplicar en vez de fallar por un motivo ajeno a lo que verifica.
      skip: AppConfig.sinConfiguracionInyectada
          ? null
          : 'La suite recibió --dart-define.',
    );
  });
}
