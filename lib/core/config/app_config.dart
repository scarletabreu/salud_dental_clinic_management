import 'dart:convert';

enum AppEnvironment {
  development,
  test,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' || 'dev' => AppEnvironment.development,
      'test' || 'testing' => AppEnvironment.test,
      'production' || 'prod' => AppEnvironment.production,
      _ => throw StateError(
        'APP_ENVIRONMENT debe ser development, test o production.',
      ),
    };
  }
}

/// Configuración pública inyectada durante la compilación.
///
/// Flutter Web incluye estos valores en el JavaScript resultante. Por eso aquí
/// solo se admite la publishable/anon key de Supabase; una service_role key no
/// debe llegar nunca al cliente ni a `--dart-define`.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    const environment = String.fromEnvironment('APP_ENVIRONMENT');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );

    return AppConfig.validated(
      environment: environment,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );
  }

  factory AppConfig.validated({
    required String environment,
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) {
    final parsedEnvironment = AppEnvironment.parse(environment);
    final uri = Uri.tryParse(supabaseUrl);
    final isLoopback =
        uri?.host == 'localhost' ||
        uri?.host == '127.0.0.1' ||
        uri?.host == '::1';

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(parsedEnvironment == AppEnvironment.development && isLoopback))) {
      throw StateError(
        'SUPABASE_URL debe ser una URL HTTPS válida '
        '(se permite HTTP únicamente para localhost).',
      );
    }

    final key = supabasePublishableKey.trim();
    if (key.isEmpty) {
      throw StateError('Falta SUPABASE_PUBLISHABLE_KEY.');
    }
    if (_isServerCredential(key)) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY no puede contener una clave secreta '
        'o service_role.',
      );
    }

    return AppConfig(
      environment: parsedEnvironment,
      supabaseUrl: uri.toString(),
      supabasePublishableKey: key,
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  static bool _isServerCredential(String key) {
    if (key.startsWith('sb_secret_')) {
      return true;
    }

    final parts = key.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      return claims is Map<String, dynamic> && claims['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
