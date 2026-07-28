import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart' as di;
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/pages/login_page.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/cubit/settings_cubit.dart';
import 'core/presentation/app_theme.dart';
import 'core/presentation/bootstrap_error_screen.dart';
import 'core/presentation/connectivity_cubit.dart';
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } catch (error, stackTrace) {
    _mostrarFalloDeArranque(
      error,
      stackTrace,
      AppConfig.sinConfiguracionInyectada
          ? BootstrapErrorKind.configuracionAusente
          : BootstrapErrorKind.configuracionInvalida,
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    await di.init();
  } catch (error, stackTrace) {
    _mostrarFalloDeArranque(
      error,
      stackTrace,
      BootstrapErrorKind.inicializacion,
    );
    return;
  }

  runApp(const MyApp());
}

void _mostrarFalloDeArranque(
  Object error,
  StackTrace stackTrace,
  BootstrapErrorKind tipo,
) {
  debugPrint('Fallo de arranque ($tipo): $error\n$stackTrace');
  runApp(
    BootstrapErrorScreen(
      detalle: error is StateError ? error.message : '$error',
      tipo: tipo,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()),
        BlocProvider<SettingsCubit>(create: (_) => di.sl<SettingsCubit>()),
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.sl<ConnectivityCubit>(),
        ),
      ],
      child: const _RaizConTema(),
    );
  }
}

class _RaizConTema extends StatelessWidget {
  const _RaizConTema();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state.themeMode,
    );

    return MaterialApp(
      title: 'Clínica Salud Dental Integral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _AppRouter(),
    );
  }
}

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
