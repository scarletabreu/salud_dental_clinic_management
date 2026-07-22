import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// El login solo necesita del repositorio el stream de sesión, que aquí nunca
/// emite: la pantalla se queda en su estado inicial, que es el que interesa
/// medir.
class _RepositorioFalso extends Fake implements UsuarioRepository {
  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      const Stream<supabase.AuthState>.empty();
}

Widget _app({double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: BlocProvider<AuthCubit>(
    create: (_) => AuthCubit(usuarioRepository: _RepositorioFalso()),
    child: const LoginPage(),
  ),
);

void _viewport(WidgetTester tester, double ancho, double alto) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  final viewports = <String, Size>{
    '320 px': const Size(320, 640),
    '360 px': const Size(360, 740),
    '390 px': const Size(390, 844),
    'tablet': const Size(768, 1024),
    'escritorio': const Size(1280, 800),
  };

  viewports.forEach((nombre, tamano) {
    testWidgets('el login se completa en $nombre', (tester) async {
      _viewport(tester, tamano.width, tamano.height);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Los dos campos y el botón siguen presentes y accesibles.
      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'bsantana');
      await tester.enterText(find.byType(TextFormField).last, 'secreto123');
      await tester.pump();

      expect(find.text('bsantana'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'el formulario de acceso no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('la tarjeta de acceso nunca excede el ancho de 320 px', (
    tester,
  ) async {
    _viewport(tester, 320, 640);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final campo in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      final rect = tester.getRect(find.byWidget(campo));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
  });

  testWidgets('el login sobrevive al teclado abierto en 320 px', (
    tester,
  ) async {
    _viewport(tester, 320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el login sobrevive al texto ampliado en 320 px', (tester) async {
    _viewport(tester, 320, 640);
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
