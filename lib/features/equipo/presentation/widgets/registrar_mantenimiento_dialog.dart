import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/domain/entities/equipo_mantenimiento.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';

class RegistrarMantenimientoDialog extends StatefulWidget {
  const RegistrarMantenimientoDialog({
    super.key,
    required this.equipo,
    required this.suplidores,
  });

  final Equipo equipo;
  final List<Suplidor> suplidores;

  @override
  State<RegistrarMantenimientoDialog> createState() =>
      _RegistrarMantenimientoDialogState();
}

class _RegistrarMantenimientoDialogState
    extends State<RegistrarMantenimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _costoController = TextEditingController();
  final _descripcionController = TextEditingController(
    text: 'Mantenimiento preventivo',
  );
  DateTime _fecha = DateTime.now();
  String? _suplidorId;
  bool _guardando = false;

  @override
  void dispose() {
    _costoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fecha = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || widget.equipo.id == null) return;
    setState(() => _guardando = true);
    final ok = await context.read<EquipoCubit>().registrarMantenimiento(
      EquipoMantenimiento(
        equipoId: widget.equipo.id!,
        descripcion: _descripcionController.text.trim(),
        suplidorId: _suplidorId,
        costo: double.parse(_costoController.text.trim().replaceAll(',', '.')),
        fechaMantenimiento: _fecha,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el mantenimiento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Mantenimiento · ${widget.equipo.nombre}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _suplidorId,
                  decoration: const InputDecoration(
                    labelText: 'Suplidor',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  items: widget.suplidores
                      .where((s) => s.id != null)
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: _guardando
                      ? null
                      : (value) => setState(() => _suplidorId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona un suplidor.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _costoController,
                  enabled: !_guardando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Costo (RD\$)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final costo = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (costo == null) return 'Ingresa un costo válido.';
                    if (costo < 0) return 'El costo no puede ser negativo.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _guardando ? null : _seleccionarFecha,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionController,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Detalle',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Describe el mantenimiento.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
          icon: _guardando
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_guardando ? 'Guardando...' : 'Registrar'),
        ),
      ],
    );
  }
}
