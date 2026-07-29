import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

Future<ItemReceta?> mostrarRecetaItemFormDialog(
  BuildContext context,
  Medicina medicina, {
  ItemReceta? itemExistente,
}) {
  return showDialog<ItemReceta>(
    context: context,
    builder: (ctx) =>
        _RecetaItemFormDialog(medicina: medicina, itemExistente: itemExistente),
  );
}

class _RecetaItemFormDialog extends StatefulWidget {
  final Medicina medicina;
  final ItemReceta? itemExistente;

  const _RecetaItemFormDialog({required this.medicina, this.itemExistente});

  @override
  State<_RecetaItemFormDialog> createState() => _RecetaItemFormDialogState();
}

class _RecetaItemFormDialogState extends State<_RecetaItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dosisController;
  late final TextEditingController _presentacionController;
  late final TextEditingController _viaController;
  late final TextEditingController _frecuenciaController;
  late final TextEditingController _duracionController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _indicacionesController;

  @override
  void initState() {
    super.initState();
    final item = widget.itemExistente;

    _dosisController = TextEditingController(text: item?.dosis ?? '');
    _presentacionController = TextEditingController(
      text: item?.presentacionConcentracion ?? '',
    );
    _viaController = TextEditingController(
      text: item?.viaAdministracion ?? 'vía oral',
    );
    _frecuenciaController = TextEditingController(text: item?.frecuencia ?? '');
    _duracionController = TextEditingController(text: item?.duracion ?? '');
    _cantidadController = TextEditingController(
      text: item?.cantidadIndicada ?? '',
    );
    _indicacionesController = TextEditingController(
      text: item?.indicacionesEspecificas ?? '',
    );
  }

  @override
  void dispose() {
    _dosisController.dispose();
    _presentacionController.dispose();
    _viaController.dispose();
    _frecuenciaController.dispose();
    _duracionController.dispose();
    _cantidadController.dispose();
    _indicacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final item = ItemReceta(
      id: widget.itemExistente?.id,
      medicamentoId: widget.medicina.id,
      nombreMedicamento: widget.medicina.nombre,
      presentacionConcentracion: _presentacionController.text.trim(),
      dosis: _dosisController.text.trim(),
      viaAdministracion: _viaController.text.trim(),
      frecuencia: _frecuenciaController.text.trim(),
      duracion: _duracionController.text.trim(),
      cantidadIndicada: _cantidadController.text.trim(),
      indicacionesEspecificas: _indicacionesController.text.trim().isEmpty
          ? null
          : _indicacionesController.text.trim(),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AppDialog(
      preferredWidth: 460,
      title: Row(
        children: [
          Icon(Icons.medication_rounded, size: 22, color: ac.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.medicina.nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      scrollable: false,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      ac,
                      _dosisController,
                      'Dosis *',
                      'Ej. 500mg / 1 tab',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _campo(
                      ac,
                      _presentacionController,
                      'Concentración',
                      'Ej. Tabletas',
                      requerido: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      ac,
                      _frecuenciaController,
                      'Frecuencia *',
                      'Ej. Cada 8 horas',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _campo(
                      ac,
                      _viaController,
                      'Vía de Adm.',
                      'Ej. Vía oral',
                      requerido: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      ac,
                      _duracionController,
                      'Duración *',
                      'Ej. 7 días',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _campo(
                      ac,
                      _cantidadController,
                      'Cantidad Despacho',
                      'Ej. 21 tabletas',
                      requerido: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _campo(
                ac,
                _indicacionesController,
                'Indicaciones específicas',
                'Ej. Tomar junto con los alimentos',
                requerido: false,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Agregar renglón'),
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
