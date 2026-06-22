import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/cubit/tratamiento_cubit.dart';

class TratamientoFormDialog extends StatefulWidget {
  final Tratamiento? tratamiento;
  const TratamientoFormDialog({super.key, this.tratamiento});

  @override
  State<TratamientoFormDialog> createState() => _TratamientoFormDialogState();
}

class _TratamientoFormDialogState extends State<TratamientoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _costoCtrl;
  late Alcance _alcance;
  bool _saving = false;

  bool get _isEditing => widget.tratamiento != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tratamiento;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: t?.descripcion ?? '');
    _costoCtrl = TextEditingController(
      text: t != null ? t.costo.toString() : '',
    );
    _alcance = t?.alcance ?? Alcance.diente;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tratamiento = Tratamiento(
      id: widget.tratamiento?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      costo: double.parse(_costoCtrl.text),
      alcance: _alcance,
      contraindicaciones: widget.tratamiento?.contraindicaciones ?? [],
    );

    final exito = await context
        .read<TratamientoCubit>()
        .guardarTratamiento(tratamiento);
    if (mounted) {
      setState(() => _saving = false);
      if (exito) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Dialog(
      backgroundColor: ac.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ac.primaryBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 17,
                        color: ac.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing ? 'Editar tratamiento' : 'Nuevo tratamiento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FormField(
                  ac: ac,
                  icon: Icons.label_outline_rounded,
                  label: 'Nombre del tratamiento',
                  child: TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDeco(
                      ac,
                      hint: 'Ej. Endodoncia, Limpieza dental',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                _FormField(
                  ac: ac,
                  icon: Icons.notes_rounded,
                  label: 'Descripción',
                  child: TextFormField(
                    controller: _descripcionCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: _inputDeco(
                      ac,
                      hint: 'Detalles del servicio clínico…',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _FormField(
                  ac: ac,
                  icon: Icons.attach_money_rounded,
                  label: 'Precio base',
                  child: TextFormField(
                    controller: _costoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDeco(ac, hint: '0.00', prefix: '\$ '),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'El precio es obligatorio';
                      }
                      final n = double.tryParse(v);
                      if (n == null) return 'Ingresa un número válido';
                      if (n < 0) return 'El precio no puede ser negativo';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),

                _FormField(
                  ac: ac,
                  icon: Icons.tune_rounded,
                  label: 'Alcance del tratamiento',
                  child: DropdownButtonFormField<Alcance>(
                    initialValue: _alcance,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
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
                        borderSide: BorderSide(
                          color: ac.primaryBlue,
                          width: 1.0,
                        ),
                      ),
                    ),
                    items: Alcance.values
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                              a.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                color: ac.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _alcance = v);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
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
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(
                        _isEditing ? 'Guardar cambios' : 'Crear tratamiento',
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
    AppColors ac, {
    String? hint,
    String? prefix,
    bool alignLabelWithHint = false,
  }) => InputDecoration(
    hintText: hint,
    prefixText: prefix,
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
    alignLabelWithHint: alignLabelWithHint,
  );
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
