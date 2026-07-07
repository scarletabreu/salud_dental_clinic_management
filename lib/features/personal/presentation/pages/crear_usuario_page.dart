import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_state.dart';

class _CedulaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3) buffer.write('-');
      if (i == 10) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CrearUsuarioPage extends StatefulWidget {
  final Usuario? usuario;
  const CrearUsuarioPage({super.key, this.usuario});

  @override
  State<CrearUsuarioPage> createState() => _CrearUsuarioPageState();
}

class _CrearUsuarioPageState extends State<CrearUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late DateTime _birthDate;
  late final TextEditingController _telefonoController;
  late final TextEditingController _cedulaController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  RolUsuario _rolUsuario = RolUsuario.asistente;
  bool _obscurePassword = true;

  bool get _isEditing => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreController = TextEditingController(text: u?.nombre ?? '');
    _apellidoController = TextEditingController(text: u?.apellido ?? '');
    _birthDate = u?.birthDate ?? DateTime(2000, 1, 1);
    _cedulaController = TextEditingController(text: u?.govID ?? '');
    _telefonoController = TextEditingController(
      text: u?.contactos.first.numeroTelefono ?? '',
    );
    _usernameController = TextEditingController(text: u?.username ?? '');
    _passwordController = TextEditingController();

    if (u != null) {
      _rolUsuario = u.rol;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _birthDate = DateTime.now();
    _telefonoController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<PersonalPerfilesCubit>().guardarUsuario(
      existente: widget.usuario,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      birthDate: _birthDate,
      govID: _cedulaController.text.trim(),
      username: _usernameController.text.trim(),
      telefono: _telefonoController.text.trim(),
      nuevaPassword: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      email: _isEditing
          ? null
          : '${_usernameController.text.trim()}@saluddental.com',
      rol: _isEditing ? null : _rolUsuario,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return BlocConsumer<PersonalPerfilesCubit, PersonalPerfilesState>(
      listener: (context, state) {
        if (state is PerfilError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: ac.red, content: Text(state.message)),
          );
        }
        // Puedes agregar aquí un estado de éxito específico para la creación de perfiles/usuarios si cuentas con uno
      },
      builder: (context, state) {
        final isSaving = state is PerfilLoading;

        return Scaffold(
          backgroundColor: ac.bgPage,
          appBar: _buildAppBar(ac, isSaving),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDatosPersonalesCard(ac),
                  const SizedBox(height: 16),
                  _buildCredencialesCard(ac),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppColors ac, bool isSaving) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        color: ac.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              GestureDetector(
                onTap: isSaving ? null : () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: ac.divider),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: ac.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Usuarios',
                          style: TextStyle(fontSize: 11, color: ac.primaryBlue),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 13,
                          color: ac.textMuted,
                        ),
                        Text(
                          _isEditing ? 'Editar usuario' : 'Nuevo usuario',
                          style: TextStyle(fontSize: 11, color: ac.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditing ? 'Editar usuario' : 'Registro de usuario',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.textSecondary,
                  side: BorderSide(color: ac.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isSaving ? null : _save,
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatosPersonalesCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.primaryBlue,
      iconBg: ac.primaryBlue.withOpacity(0.10),
      icon: Icons.person_outline_rounded,
      title: 'Datos personales del usuario',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FormField(
                  ac: ac,
                  icon: Icons.badge_outlined,
                  label: 'Nombre *',
                  child: TextFormField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco(ac, hint: 'Ej. Carlos'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  ac: ac,
                  icon: Icons.badge_outlined,
                  label: 'Apellido *',
                  child: TextFormField(
                    controller: _apellidoController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco(ac, hint: 'Ej. Mendoza'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El apellido es obligatorio'
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.credit_card_outlined,
            label: 'Cédula *',
            child: TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [_CedulaInputFormatter()],
              decoration: _inputDeco(ac, hint: '000-0000000-0'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La cédula es obligatoria';
                }
                final demasked = v.replaceAll('-', '');
                if (demasked.length != 11) {
                  return 'La cédula debe contener exactamente 11 dígitos';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.phone_android_rounded,
            label: 'Teléfono *',
            child: TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: _inputDeco(ac, hint: 'Ej. 809-555-0199'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El teléfono es obligatorio'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.cake_outlined,
            label: 'Fecha de nacimiento *',
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _birthDate = picked);
              },
              child: InputDecorator(
                decoration: _inputDeco(ac),
                child: Text(
                  '${_birthDate.day.toString().padLeft(2, '0')}/'
                  '${_birthDate.month.toString().padLeft(2, '0')}/'
                  '${_birthDate.year}',
                  style: TextStyle(fontSize: 14, color: ac.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredencialesCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.teal,
      iconBg: ac.teal.withOpacity(0.10),
      icon: Icons.lock_outline_rounded,
      title: 'Credenciales y accesos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(
            ac: ac,
            icon: Icons.admin_panel_settings_outlined,
            label: 'Rol de sistema *',
            child: AbsorbPointer(
              absorbing: _isEditing,
              child: Opacity(
                opacity: _isEditing ? 0.5 : 1.0,
                child: _ChipSelector<RolUsuario>(
                  ac: ac,
                  options: RolUsuario.values,
                  selected: _rolUsuario,
                  labelOf: (rol) => rol.name.toUpperCase(),
                  activeColor: ac.primaryBlue,
                  onSelected: (rol) => setState(() => _rolUsuario = rol),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.alternate_email_rounded,
            label: 'Nombre de usuario *',
            child: TextFormField(
              controller: _usernameController,
              decoration: _inputDeco(ac, hint: 'Ej. cmendoza'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El usuario es obligatorio'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.password_rounded,
            label: _isEditing
                ? 'Nueva Contraseña (Dejar vacío para mantener)'
                : 'Contraseña *',
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDeco(ac, hint: '••••••••').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: ac.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (!_isEditing && (v == null || v.trim().isEmpty)) {
                  return 'La contraseña es obligatoria';
                }
                if (v != null && v.isNotEmpty && v.length < 6) {
                  return 'Debe contener al menos 6 caracteres';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(AppColors ac, {String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    filled: true,
    fillColor: ac.bgPage,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.divider, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.primaryBlue, width: 1.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.red, width: 0.5),
    ),
  );
}

class _FormCard extends StatelessWidget {
  final AppColors ac;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final String title;
  final Widget child;

  const _FormCard({
    required this.ac,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider, width: 0.5),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final AppColors ac;
  final IconData icon;
  final String label;
  final Widget child;

  const _FormField({
    required this.ac,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: ac.primaryBlue),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: ac.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final AppColors ac;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final Color activeColor;
  final void Function(T) onSelected;

  const _ChipSelector({
    required this.ac,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.activeColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.10) : ac.bgPage,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isActive ? activeColor.withOpacity(0.50) : ac.divider,
                width: isActive ? 1.0 : 0.5,
              ),
            ),
            child: Text(
              labelOf(opt),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? activeColor : ac.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
