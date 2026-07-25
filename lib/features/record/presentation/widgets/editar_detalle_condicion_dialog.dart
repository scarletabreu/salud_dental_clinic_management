import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/record_condicion.dart';

class EditarDetalleCondicionDialog extends StatefulWidget {
  final RecordCondicion recordCondicion;

  const EditarDetalleCondicionDialog({
    super.key,
    required this.recordCondicion,
  });

  @override
  State<EditarDetalleCondicionDialog> createState() =>
      _EditarDetalleCondicionDialogState();
}

class _EditarDetalleCondicionDialogState
    extends State<EditarDetalleCondicionDialog> {
  late final TextEditingController _medicamentoController;
  late final TextEditingController _dosisController;
  late final TextEditingController _frecuenciaController;
  late final TextEditingController _medicoController;
  late final TextEditingController _contactoController;
  late final TextEditingController _notasController;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final rc = widget.recordCondicion;
    _medicamentoController = TextEditingController(text: rc.medicamento ?? '');
    _dosisController = TextEditingController(text: rc.dosis ?? '');
    _frecuenciaController = TextEditingController(text: rc.frecuencia ?? '');
    _medicoController = TextEditingController(text: rc.medicoTratante ?? '');
    _contactoController = TextEditingController(text: rc.contactoMedico ?? '');
    _notasController = TextEditingController(text: rc.notas ?? '');
    _activo = rc.activo;
  }

  @override
  void dispose() {
    _medicamentoController.dispose();
    _dosisController.dispose();
    _frecuenciaController.dispose();
    _medicoController.dispose();
    _contactoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _guardar() {
    final actualizado = widget.recordCondicion.copyWith(
      medicamento: _medicamentoController.text.trim(),
      dosis: _dosisController.text.trim(),
      frecuencia: _frecuenciaController.text.trim(),
      medicoTratante: _medicoController.text.trim(),
      contactoMedico: _contactoController.text.trim(),
      notas: _notasController.text.trim(),
      activo: _activo,
    );
    Navigator.of(context).pop(actualizado);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final nombreCondicion =
        widget.recordCondicion.condicion?.nombre ?? 'Condición médica';

    return AppDialog(
      preferredWidth: 460,
      title: Text('Detalle de $nombreCondicion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tratamiento activo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _activo
                    ? 'El paciente actualmente recibe tratamiento para esta condición.'
                    : 'Condición o tratamiento inactivo/inactivo histórico.',
                style: TextStyle(fontSize: 12, color: ac.textMuted),
              ),
              value: _activo,
              activeColor: ac.primaryBlue,
              onChanged: (v) => setState(() => _activo = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _medicamentoController,
              decoration: _inputDeco(
                ac,
                label: 'Medicamento (Texto Libre)',
                hint: 'Ej. Losartán 50mg',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dosisController,
                    decoration: _inputDeco(
                      ac,
                      label: 'Dosis',
                      hint: 'Ej. 1 tableta',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _frecuenciaController,
                    decoration: _inputDeco(
                      ac,
                      label: 'Frecuencia',
                      hint: 'Ej. Cada 12 horas',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _medicoController,
              decoration: _inputDeco(
                ac,
                label: 'Médico tratante',
                hint: 'Ej. Dr. Ramírez (Cardiólogo)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactoController,
              decoration: _inputDeco(
                ac,
                label: 'Contacto médico (Opcional)',
                hint: 'Teléfono o clínica externa',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notasController,
              maxLines: 2,
              decoration: _inputDeco(
                ac,
                label: 'Notas e indicaciones extra',
                hint: 'Observaciones sobre el control médico…',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
          child: const Text('Guardar indicación'),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(
    AppColors ac, {
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
