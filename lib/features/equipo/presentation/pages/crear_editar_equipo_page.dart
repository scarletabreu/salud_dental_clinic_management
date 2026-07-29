import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';

class CrearEditarEquipoPage extends StatefulWidget {
  final Equipo? equipo;

  const CrearEditarEquipoPage({super.key, this.equipo});

  bool get _esEdicion => equipo != null;

  // CORREGIDO: faltaba createState() — es requerido por StatefulWidget,
  // su ausencia causaba ambos errores del compilador.
  @override
  State<CrearEditarEquipoPage> createState() => _CrearEditarEquipoPageState();
}

class _CrearEditarEquipoPageState extends State<CrearEditarEquipoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _diasCtrl;
  DateTime? _fechaUltimoMantenimiento;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.equipo;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: e?.descripcion ?? '');
    _diasCtrl = TextEditingController(
      text: e?.tiempoParaMantenimiento.toString() ?? '',
    );
    _fechaUltimoMantenimiento = e?.ultimoMantenimiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _diasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaUltimoMantenimiento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _fechaUltimoMantenimiento = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaUltimoMantenimiento == null) {
      _mostrarError('Selecciona la fecha del último mantenimiento.');
      return;
    }

    setState(() => _guardando = true);

    final equipo = Equipo(
      id: widget.equipo?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      ultimoMantenimiento: _fechaUltimoMantenimiento!,
      tiempoParaMantenimiento: int.parse(_diasCtrl.text.trim()),
    );

    final ok = await context.read<EquipoCubit>().guardarEquipo(equipo);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.of(context).pop();
    } else {
      _mostrarError('No se pudo guardar el equipo. Inténtalo de nuevo.');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.appColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget._esEdicion ? 'Editar equipo' : 'Nuevo equipo',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Información del equipo', ac),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _nombreCtrl,
                      label: 'Nombre del equipo',
                      hint: 'Ej: Unidad dental #1',
                      icon: Icons.build_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo requerido'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _descripcionCtrl,
                      label: 'Descripción',
                      hint: 'Ej: Sillón dental marca Kavo',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Mantenimiento', ac),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fechaUltimoMantenimiento != null
                                    ? 'Último mantenimiento: ${dateFmt.format(_fechaUltimoMantenimiento!)}'
                                    : 'Seleccionar fecha de último mantenimiento',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _fechaUltimoMantenimiento != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _diasCtrl,
                      label: 'Frecuencia de mantenimiento (días)',
                      hint: 'Ej: 90',
                      icon: Icons.repeat_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo requerido';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Debe ser un número mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget._esEdicion
                              ? 'Guardar cambios'
                              : 'Registrar equipo',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, AppColors ac) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ac.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appColors.red, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.appColors.primaryGreen,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: child,
    );
  }
}
