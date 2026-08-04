import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Repositorio cuyo login se queda colgado hasta que el test lo resuelve: es la
/// única forma de observar la pantalla mientras la autenticación está en vuelo.
class _RepositorioLento extends Fake implements UsuarioRepository {
  final _completer = Completer<Usuario>();
  int intentos = 0;

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      const Stream<supabase.AuthState>.empty();

  @override
  Future<Usuario> loginUsuario(String username, String password) {
    intentos++;
    return _completer.future;
  }

  void responder() => _completer.complete(
    Admin(
      id: 'u-1',
      nombre: 'Ana',
      apellido: 'Pérez',
      birthDate: DateTime(1985),
      govID: '001-1234567-8',
      contactos: const [],
      estatus: EstatusPersona.activo,
      username: 'bsantana',
      // Un administrador es un doctor con capacidades añadidas: nace con
      // identidad clínica, así que su perfil siempre trae especialidad.
      specialty: 'Ortodoncia',
      assistants: const [],
      departamento: 'Administración',
    ),
  );
}

Future<void> _montar(WidgetTester tester, _RepositorioLento repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(usuarioRepository: repo),
        child: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).first, 'bsantana');
  await tester.enterText(find.byType(TextFormField).last, 'secreto123');
  await tester.pump();
}

void main() {
  testWidgets('mientras autentica, el botón muestra progreso', (tester) async {
    final repo = _RepositorioLento();
    await _montar(tester, repo);

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);

    repo.responder();
    await tester.pumpAndSettle();
  });

  testWidgets('dos toques seguidos no lanzan dos autenticaciones', (
    tester,
  ) async {
    final repo = _RepositorioLento();
    await _montar(tester, repo);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    // El botón ya está deshabilitado: se toca donde estaba, por si acaso.
    await tester.tap(find.byType(InkWell).last, warnIfMissed: false);
    await tester.pump();

    expect(repo.intentos, 1);

    repo.responder();
    await tester.pumpAndSettle();
  });
}
