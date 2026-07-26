import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/bootstrap_error_screen.dart';

void main() {
  group('BootstrapErrorScreen', () {
    testWidgets(
      'explica cómo inyectar la configuración cuando no hay ninguna',
      (tester) async {
        await tester.pumpWidget(
          const BootstrapErrorScreen(
            detalle: 'Falta APP_ENVIRONMENT.',
            tipo: BootstrapErrorKind.configuracionAusente,
          ),
        );

        expect(find.text('No se pudo iniciar la aplicación'), findsOneWidget);
        expect(find.text('Falta APP_ENVIRONMENT.'), findsOneWidget);
        expect(
          find.textContaining('no recibió la configuración'),
          findsOneWidget,
        );
        expect(
          find.textContaining('--dart-define-from-file=dart_define.json'),
          findsOneWidget,
        );
      },
    );

    testWidgets('atribuye el fallo al valor cuando sí hubo configuración', (
      tester,
    ) async {
      await tester.pumpWidget(
        const BootstrapErrorScreen(
          detalle: 'SUPABASE_URL debe ser una URL HTTPS válida',
          tipo: BootstrapErrorKind.configuracionInvalida,
        ),
      );

      expect(find.textContaining('no es válida'), findsOneWidget);
      expect(
        find.text('SUPABASE_URL debe ser una URL HTTPS válida'),
        findsOneWidget,
      );
      expect(
        find.textContaining('--dart-define-from-file=dart_define.json'),
        findsOneWidget,
      );
    });

    testWidgets('no propone tocar las variables si el fallo fue posterior', (
      tester,
    ) async {
      // Un fallo de Supabase o del contenedor no se arregla editando
      // `dart_define.json`; sugerirlo mandaría a buscar donde no es.
      await tester.pumpWidget(
        const BootstrapErrorScreen(
          detalle: 'SocketException: Connection refused',
          tipo: BootstrapErrorKind.inicializacion,
        ),
      );

      expect(find.textContaining('falló la inicialización'), findsOneWidget);
      expect(
        find.textContaining('--dart-define-from-file=dart_define.json'),
        findsNothing,
      );
    });

    testWidgets('cabe en un viewport de 320 px sin desbordarse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const BootstrapErrorScreen(
          detalle: 'Falta SUPABASE_PUBLISHABLE_KEY.',
          tipo: BootstrapErrorKind.configuracionInvalida,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
