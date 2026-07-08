import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  static const _blue = Color(0xFF0066FF);
  static const _blueDark = Color(0xFF0047B3);
  static const _surface = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFCBD5E1);

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Salud Dental',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Inicia sesión para continuar',
          style: TextStyle(fontSize: 14.5, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ErrorBanner(),
            _label('Usuario'),
            const SizedBox(height: 6),
            _usernameField(),
            const SizedBox(height: 18),
            _label('Contraseña'),
            const SizedBox(height: 6),
            _passwordField(),
            const SizedBox(height: 26),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
  );

  Widget _usernameField() {
    return TextFormField(
      controller: _usernameCtrl,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(fontSize: 15, color: _textPrimary),
      decoration: _deco(
        hint: 'pruebadoctor',
        icon: Icons.person_outline_rounded,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty)
          return 'Ingresa tu nombre de usuario.';
        if (v.trim().length < 3)
          return 'El usuario debe tener al menos 3 caracteres.';
        return null;
      },
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 15, color: _textPrimary),
      decoration: _deco(
        hint: '••••••••',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _textMuted,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña.';
        if (v.length < 4)
          return 'La contraseña debe tener al menos 4 caracteres.';
        return null;
      },
      onFieldSubmitted: (_) => _submit(),
    );
  }

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 14.5),
      prefixIcon: Icon(icon, color: _textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
    );
  }

  Widget _submitButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) =>
          p.isAuthenticated != c.isAuthenticated || (p.error != c.error),
      builder: (context, state) {
        final loading = false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _blueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.32),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : _submit,
              borderRadius: BorderRadius.circular(13),
              child: const Center(
                child: Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.error != c.error,
      builder: (context, state) {
        if (state.error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDA4AF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE11D48),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF9F1239),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
