import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/pages/login_page.dart';
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (state) {
            AuthInitial() => const _SplashScreen(),
            AuthLoading() => const _SplashScreen(),
            Authenticated() => const DashboardShell(),
            Unauthenticated() => const LoginPage(),
            AuthError() => const LoginPage(),
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0066FF),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
