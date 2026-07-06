import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

/// Formulario para completar dosis, frecuencia, duración e indicaciones
/// de una medicina ya seleccionada y ya validada contra contraindicaciones.
/// Devuelve la [Receta] armada o null si se cancela.
Future<Receta?> mostrarRecetaItemFormDialog(
  BuildContext context,
  Medicina medicina, {
  String? justificacionClinica,
}) {
  return showDialog<Receta>(
    context: context,
    builder: (ctx) => _RecetaItemFormDialog(
      medicina: medicina,
      justificacionClinica: justificacionClinica,
    ),
  );
}

class _RecetaItemFormDialog extends StatefulWidget {
  final Medicina medicina;
  final String? justificacionClinica;

  const _RecetaItemFormDialog({
    required this.medicina,
    this.justificacionClinica,
  });

  @override
  State<_RecetaItemFormDialog> createState() => _RecetaItemFormDialogState();
}

class _RecetaItemFormDialogState extends State<_RecetaItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dosisController = TextEditingController();
  final _frecuenciaController = TextEditingController();
  final _duracionController = TextEditingController();
  final _indicacionesController = TextEditingController();

  @override
  void dispose() {
    _dosisController.dispose();
    _frecuenciaController.dispose();
    _duracionController.dispose();
    _indicacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final receta = Receta(
      title: widget.medicina.nombre,
      createdAt: DateTime.now(),
      medicinaId: widget.medicina.id ?? '',
      dosis: _dosisController.text.trim(),
      frecuencia: _frecuenciaController.text.trim(),
      duracion: _duracionController.text.trim(),
      indicaciones: _indicacionesController.text.trim(),
      notas: widget.justificacionClinica,
    );

    Navigator.of(context).pop(receta);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.medication_rounded, size: 20, color: ac.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.medicina.nombre,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(ac, _dosisController, 'Dosis', 'Ej. 500mg'),
                const SizedBox(height: 12),
                _campo(
                  ac,
                  _frecuenciaController,
                  'Frecuencia',
                  'Ej. Cada 8 horas',
                ),
                const SizedBox(height: 12),
                _campo(ac, _duracionController, 'Duración', 'Ej. 7 días'),
                const SizedBox(height: 12),
                _campo(
                  ac,
                  _indicacionesController,
                  'Indicaciones',
                  'Ej. Tomar con alimentos',
                  requerido: false,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
          child: const Text('Agregar a la receta'),
        ),
      ],
    );
  }

  Widget _campo(
    AppColors ac,
    TextEditingController controller,
    String label,
    String hint, {
    bool requerido = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: requerido
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
