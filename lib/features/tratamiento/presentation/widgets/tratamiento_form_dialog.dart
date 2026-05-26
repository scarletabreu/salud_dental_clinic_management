import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/providers/tratamiento_provider.dart';

class TratamientoFormDialog extends ConsumerStatefulWidget {
  final Tratamiento? tratamiento;

  const TratamientoFormDialog({super.key, this.tratamiento});

  @override
  ConsumerState<TratamientoFormDialog> createState() =>
      _TratamientoFormDialogState();
}

class _TratamientoFormDialogState extends ConsumerState<TratamientoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _costoCtrl;
  late Alcance _alcanceSeleccionado;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tratamiento;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: t?.descripcion ?? '');
    _costoCtrl = TextEditingController(
      text: t != null ? t.costo.toString() : '',
    );
    _alcanceSeleccionado = t?.alcance ?? Alcance.diente;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  void _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final nuevoTratamiento = Tratamiento(
      id: widget.tratamiento?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      costo: double.parse(_costoCtrl.text),
      alcance: _alcanceSeleccionado,
      contraindicaciones: widget.tratamiento?.contraindicaciones ?? [],
    );

    final exito = await ref
        .read(tratamientoProvider.notifier)
        .guardarTratamiento(nuevoTratamiento);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (exito) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.tratamiento != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Tratamiento' : 'Nuevo Tratamiento'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Tratamiento *',
                    hintText: 'Ej: Endodoncia, Limpieza Dental',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles del servicio clínico...',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio Base (\$) *',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El precio es obligatorio';
                    }
                    final precio = double.tryParse(value);
                    if (precio == null) {
                      return 'Ingrese un número válido';
                    }
                    if (precio < 0) {
                      return 'El precio no puede ser negativo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Alcance>(
                  value: _alcanceSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Alcance del Tratamiento',
                  ),
                  items: Alcance.values.map((Alcance alc) {
                    return DropdownMenuItem<Alcance>(
                      value: alc,
                      child: Text(alc.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (Alcance? nuevoAlcance) {
                    if (nuevoAlcance != null) {
                      setState(() => _alcanceSeleccionado = nuevoAlcance);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _enviarFormulario,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
