import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'dart:math';

const _iconsPath = 'assets/icons';

const _icons = [
  'enjuague-bucal.png',
  'higiene-dental.png',
  'pasta-dental.png',
  'medicina-dental.png',
  'rayos-x.png',
];

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

  static const _blue = Color(0xFF185FA5);
  static const _surface = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFCBD5E1);

  static const _iconData = [
    (top: 0.03, left: 0.05, icon: 0, size: 52.0, angle: -0.30, opacity: 0.11),
    (top: 0.03, left: 0.30, icon: 2, size: 44.0, angle: 0.20, opacity: 0.09),
    (top: 0.03, left: 0.55, icon: 4, size: 48.0, angle: -0.15, opacity: 0.10),
    (top: 0.03, left: 0.78, icon: 1, size: 50.0, angle: 0.28, opacity: 0.11),
    (top: 0.12, left: 0.00, icon: 3, size: 46.0, angle: 0.18, opacity: 0.09),
    (top: 0.12, left: 0.20, icon: 0, size: 40.0, angle: -0.35, opacity: 0.08),
    (top: 0.12, left: 0.42, icon: 2, size: 44.0, angle: 0.22, opacity: 0.09),
    (top: 0.12, left: 0.65, icon: 4, size: 42.0, angle: -0.20, opacity: 0.08),
    (top: 0.12, left: 0.85, icon: 1, size: 46.0, angle: 0.30, opacity: 0.09),
    (top: 0.22, left: 0.03, icon: 2, size: 48.0, angle: 0.15, opacity: 0.10),
    (top: 0.22, left: 0.25, icon: 4, size: 42.0, angle: -0.25, opacity: 0.08),
    (top: 0.22, left: 0.70, icon: 3, size: 44.0, angle: 0.35, opacity: 0.09),
    (top: 0.22, left: 0.88, icon: 0, size: 40.0, angle: -0.18, opacity: 0.08),
    (top: 0.38, left: 0.00, icon: 1, size: 50.0, angle: -0.30, opacity: 0.10),
    (top: 0.38, left: 0.20, icon: 3, size: 44.0, angle: 0.22, opacity: 0.09),
    (top: 0.38, left: 0.70, icon: 0, size: 46.0, angle: -0.15, opacity: 0.09),
    (top: 0.38, left: 0.88, icon: 2, size: 42.0, angle: 0.38, opacity: 0.08),
    (top: 0.50, left: 0.03, icon: 4, size: 44.0, angle: 0.20, opacity: 0.09),
    (top: 0.50, left: 0.22, icon: 0, size: 40.0, angle: -0.28, opacity: 0.08),
    (top: 0.50, left: 0.68, icon: 1, size: 48.0, angle: 0.15, opacity: 0.10),
    (top: 0.50, left: 0.85, icon: 3, size: 44.0, angle: -0.22, opacity: 0.09),
    (top: 0.62, left: 0.00, icon: 2, size: 46.0, angle: -0.35, opacity: 0.09),
    (top: 0.62, left: 0.20, icon: 4, size: 42.0, angle: 0.25, opacity: 0.08),
    (top: 0.62, left: 0.70, icon: 0, size: 44.0, angle: -0.18, opacity: 0.09),
    (top: 0.62, left: 0.88, icon: 1, size: 40.0, angle: 0.30, opacity: 0.08),
    (top: 0.73, left: 0.03, icon: 3, size: 48.0, angle: 0.18, opacity: 0.10),
    (top: 0.73, left: 0.23, icon: 1, size: 44.0, angle: -0.22, opacity: 0.09),
    (top: 0.73, left: 0.68, icon: 2, size: 46.0, angle: 0.32, opacity: 0.09),
    (top: 0.73, left: 0.86, icon: 4, size: 42.0, angle: -0.28, opacity: 0.08),
    (top: 0.83, left: 0.00, icon: 0, size: 50.0, angle: -0.20, opacity: 0.10),
    (top: 0.83, left: 0.20, icon: 2, size: 44.0, angle: 0.28, opacity: 0.09),
    (top: 0.83, left: 0.70, icon: 3, size: 46.0, angle: -0.15, opacity: 0.09),
    (top: 0.83, left: 0.88, icon: 1, size: 40.0, angle: 0.22, opacity: 0.08),
    (top: 0.92, left: 0.03, icon: 4, size: 48.0, angle: 0.30, opacity: 0.10),
    (top: 0.92, left: 0.28, icon: 0, size: 42.0, angle: -0.25, opacity: 0.08),
    (top: 0.92, left: 0.55, icon: 1, size: 44.0, angle: 0.18, opacity: 0.09),
    (top: 0.92, left: 0.80, icon: 3, size: 52.0, angle: -0.30, opacity: 0.11),
  ];

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ..._iconData.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return _FloatingIcon(
              key: ValueKey(i),
              asset: '$_iconsPath/${_icons[d.icon]}',
              size: d.size,
              opacity: d.opacity,
              angle: d.angle,
              top: d.top * size.height,
              left: d.left * size.width,
              phaseOffset: i * 0.47,
            );
          }),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F1FB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Color(0xFF0C447C)),
              SizedBox(width: 5),
              Text(
                'Acceso seguro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0C447C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Salud Dental',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Inicia sesión para continuar',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ErrorBanner(),
            _label('Usuario'),
            const SizedBox(height: 6),
            _usernameField(),
            const SizedBox(height: 16),
            _label('Contraseña'),
            const SizedBox(height: 6),
            _passwordField(),
            const SizedBox(height: 22),
            _submitButton(),
            const SizedBox(height: 20),
            _divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _socialButton(
                    onTap: () {},
                    icon: _googleIcon(),
                    label: 'Google',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _socialButton(
                    onTap: () {},
                    icon: _appleIcon(),
                    label: 'Apple',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _forgotPassword(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: _textMuted,
    ),
  );

  Widget _usernameField() {
    return TextFormField(
      controller: _usernameCtrl,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(fontSize: 14, color: _textPrimary),
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
      style: const TextStyle(fontSize: 14, color: _textPrimary),
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
      hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 14),
      prefixIcon: Icon(icon, color: _textMuted, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border.withOpacity(0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _submitButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) =>
          p.isAuthenticated != c.isAuthenticated || p.error != c.error,
      builder: (context, state) {
        return SizedBox(
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(10),
                child: const Center(
                  child: Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _border, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continúa con',
            style: TextStyle(fontSize: 12, color: _textMuted.withOpacity(0.8)),
          ),
        ),
        const Expanded(child: Divider(color: _border, thickness: 0.5)),
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: _border.withOpacity(0.8), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Image.network(
      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
      width: 18,
      height: 18,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.language, size: 18, color: _textMuted),
    );
  }

  Widget _appleIcon() {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
      width: 17,
      height: 17,
      color: _textPrimary,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.apple, size: 18, color: _textPrimary),
    );
  }

  Widget _forgotPassword() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: Text(
          '¿Olvidaste tu contraseña? Recupérala aquí',
          style: TextStyle(fontSize: 12.5, color: _textMuted),
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({
    super.key,
    required this.asset,
    required this.size,
    required this.opacity,
    required this.angle,
    required this.top,
    required this.left,
    required this.phaseOffset,
  });

  final String asset;
  final double size;
  final double opacity;
  final double angle;
  final double top;
  final double left;
  final double phaseOffset;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 2800 + (widget.phaseOffset * 400).toInt(),
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = (_ctrl.value + widget.phaseOffset) % 1.0;
        final dy = sin(t * 2 * pi) * 6.0;
        final dx = sin(t * 2 * pi * 0.7 + widget.phaseOffset) * 3.0;
        final extraAngle = sin(t * 2 * pi + widget.phaseOffset) * 0.06;

        return Positioned(
          top: widget.top + dy,
          left: widget.left + dx,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: widget.angle + extraAngle,
              child: Opacity(
                opacity: widget.opacity,
                child: Image.asset(
                  widget.asset,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
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
          padding: const EdgeInsets.only(bottom: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDA4AF), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE11D48),
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      fontSize: 13,
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
