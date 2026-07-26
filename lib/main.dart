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

  // Nada de lo que ocurre en el arranque tiene interfaz todavía: si algo lanza,
  // el framework nunca llega a `runApp` y en web el resultado es una página en
  // blanco con el error escondido en la consola del navegador. Cada etapa se
  // envuelve por separado para que el fallo llegue a la pantalla diciendo qué
  // hay que corregir, en vez de morir en silencio.
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
      publishableKey: config.supabasePublishableKey,
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

/// Raíz de la interfaz. Solo se reconstruye cuando cambia el modo de tema.
///
/// Antes era un `BlocBuilder` sobre `SettingsState` completo, de modo que
/// cualquier ajuste —el idioma, por ejemplo— reconstruía el `MaterialApp` y
/// con él todo el árbol de la app. Seleccionar únicamente `themeMode` deja
/// fuera al resto del estado: es el rebuild más caro que existe aquí y ahora
/// solo ocurre cuando de verdad cambia lo que el `MaterialApp` usa.
class _RaizConTema extends StatelessWidget {
  const _RaizConTema();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state.themeMode,
    );

    return MaterialApp(
      title: 'Salud Dental',
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
