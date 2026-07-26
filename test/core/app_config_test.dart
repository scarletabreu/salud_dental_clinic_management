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
  });
}
