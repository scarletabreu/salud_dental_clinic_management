// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/di/service_locator.dart' as di;
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/pages/login_page.dart';
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xcuvywvltttephakzmwu.supabase.co',
    anonKey: 'sb_publishable_3VHcOI-RR6w4_E8GFSkj6A_w2qa5PBG',
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      // AuthCubit ya está registrado como Factory en el service_locator.
      // Al crearse aquí suscribe automáticamente el stream de onAuthStateChange.
      create: (_) => di.sl<AuthCubit>(),
      child: MaterialApp(
        title: 'Salud Dental',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0066FF),
            brightness: Brightness.light,
          ).copyWith(surfaceContainerLowest: const Color(0xFFF5F8FA)),
          useMaterial3: true,
        ),
        home: const _AppRouter(),
      ),
    );
  }
}

/// Enruta reactivamente según el estado del AuthCubit existente.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) => prev.isAuthenticated != curr.isAuthenticated,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: state.isAuthenticated
              ? const DashboardShell()
              : const LoginPage(),
        );
      },
    );
  }
}