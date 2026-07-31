import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaFormDialog extends StatefulWidget {
  final Paciente paciente;
  final String consultaId;
  final String? doctorId;
  final Receta? recetaParaEditar;

  const RecetaFormDialog({
    super.key,
    required this.paciente,
    required this.consultaId,
    this.doctorId,
    this.recetaParaEditar,
  });

  static Future<Receta?> mostrar(
    BuildContext context, {
    required Paciente paciente,
    required String consultaId,
    String? doctorId,
    Receta? recetaParaEditar,
  }) {
    return showDialog<Receta>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecetaFormDialog(
        paciente: paciente,
        consultaId: consultaId,
        doctorId: doctorId,
        recetaParaEditar: recetaParaEditar,
      ),
    );
  }

  @override
  State<RecetaFormDialog> createState() => _RecetaFormDialogState();
}

class _RecetaFormDialogState extends State<RecetaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_ItemFormControllers> _itemsControllers = [];
  final _indicacionesGeneralesCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();

  bool _tieneContraindicacionAlerta = false;

  @override
  void initState() {
    super.initState();

    if (widget.paciente.record.condiciones.isNotEmpty) {
      _tieneContraindicacionAlerta = true;
    }

    if (widget.recetaParaEditar != null) {
      _indicacionesGeneralesCtrl.text =
          widget.recetaParaEditar!.indicacionesGenerales ?? '';
      _justificacionCtrl.text =
          widget.recetaParaEditar!.justificacionContraindicaciones ?? '';

      for (final item in widget.recetaParaEditar!.items) {
        _itemsControllers.add(_ItemFormControllers.fromItem(item));
      }
    }

    if (_itemsControllers.isEmpty) {
      _agregarRenglonMedicamento();
    }
  }

  void _agregarRenglonMedicamento() {
    setState(() {
      _itemsControllers.add(_ItemFormControllers());
    });
  }

  void _eliminarRenglonMedicamento(int index) {
    if (_itemsControllers.length == 1) return;
    setState(() {
      _itemsControllers[index].dispose();
      _itemsControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final c in _itemsControllers) {
      c.dispose();
    }
    _indicacionesGeneralesCtrl.dispose();
    _justificacionCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final items = _itemsControllers.map((c) => c.toItem()).toList();

    final recetaFinal = Receta(
      id: widget.recetaParaEditar?.id,
      codigoReceta: widget.recetaParaEditar?.codigoReceta ?? '',
      consultaId: widget.consultaId,
      pacienteId: widget.paciente.id ?? '',
      doctorId: widget.doctorId,
      fechaEmision: DateTime.now(),
      items: items,
      indicacionesGenerales: _indicacionesGeneralesCtrl.text.trim(),
      justificacionContraindicaciones: _justificacionCtrl.text.trim(),
    );

    Navigator.of(context).pop(recetaFinal);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return AlertDialog(
      backgroundColor: ac.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.medication_liquid_rounded, color: ac.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.recetaParaEditar != null
                  ? 'Reemitir / Corregir Receta'
                  : 'Emitir Receta Médica',
              style: TextStyle(fontSize: 18, color: ac.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_tieneContraindicacionAlerta) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ac.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ac.red.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: ac.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alertas y Alergias del Paciente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ac.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El paciente posee las siguientes condiciones: '
                          '${widget.paciente.record.condiciones.map((c) => c.nombre).join(', ')}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ac.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'MEDICAMENTOS PRESCRITOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: ac.primaryGreen,
                  ),
                ),
                const SizedBox(height: 10),

                ..._itemsControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ctrl = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ac.bgPage,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ac.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Medicamento #${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ac.textPrimary,
                              ),
                            ),
                            if (_itemsControllers.length > 1)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: ac.red,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _eliminarRenglonMedicamento(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: ctrl.nombreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Medicamento *',
                                  hintText: 'Ej: Amoxicilina',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.presentacionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Concentración / Presentación',
                                  hintText: 'Ej: Tabletas 500mg',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.dosisCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Dosis *',
                                  hintText: 'Ej: 1',
                                ),
                                validator: _numeroPositivo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.unidadCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Unidad *',
                                  hintText: 'tableta, ml',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.viaCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Vía de Adm. *',
                                  hintText: 'oral',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.frecuenciaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cada … horas *',
                                  hintText: '8',
                                ),
                                validator: _numeroPositivo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.duracionCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Durante … días *',
                                  hintText: '7',
                                ),
                                validator: _numeroPositivo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctrl.cantidadCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad a despachar *',
                                  hintText: '21',
                                ),
                                validator: _numeroPositivo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                OutlinedButton.icon(
                  onPressed: _agregarRenglonMedicamento,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar otro medicamento'),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _indicacionesGeneralesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        'Indicaciones Generales u Observaciones al Paciente',
                    hintText:
                        'Tomar con abundante agua. No suspender antes de cumplir el tratamiento.',
                  ),
                ),
                const SizedBox(height: 12),

                if (_tieneContraindicacionAlerta)
                  TextFormField(
                    controller: _justificacionCtrl,
                    decoration: const InputDecoration(
                      labelText:
                          'Justificación ante Contraindicaciones / Alergias',
                      hintText: 'Indicar razón médica de prescripción...',
                    ),
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
        FilledButton.icon(
          onPressed: _guardar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Emitir Receta'),
        ),
      ],
    );
  }
}

/// Los campos de la pauta son numéricos desde HFX-CLIN-003: es lo que permite
/// comprobar que la cantidad despachada alcanza para el tratamiento indicado.
String? _numeroPositivo(String? valor) {
  final numero = double.tryParse((valor ?? '').trim());
  if (numero == null || numero <= 0) return 'Indica un número mayor que 0';
  return null;
}

class _ItemFormControllers {
  final nombreCtrl = TextEditingController();
  final presentacionCtrl = TextEditingController();
  final dosisCtrl = TextEditingController();
  final unidadCtrl = TextEditingController(text: 'tableta');
  final viaCtrl = TextEditingController(text: 'oral');
  final frecuenciaCtrl = TextEditingController();
  final duracionCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController();

  String? medicamentoId;
  String? principioActivo;
  String? justificacionRiesgo;

  _ItemFormControllers();

  factory _ItemFormControllers.fromItem(ItemReceta i) {
    final c = _ItemFormControllers();
    c.nombreCtrl.text = i.nombreMedicamento;
    c.presentacionCtrl.text = i.presentacionConcentracion;
    c.dosisCtrl.text = i.dosisCantidad == null
        ? ''
        : ItemReceta.formatearNumero(i.dosisCantidad!);
    c.unidadCtrl.text = i.dosisUnidad.isEmpty ? 'tableta' : i.dosisUnidad;
    c.viaCtrl.text = i.viaAdministracion;
    c.frecuenciaCtrl.text = i.frecuenciaHoras == null
        ? ''
        : ItemReceta.formatearNumero(i.frecuenciaHoras!);
    c.duracionCtrl.text = i.duracionDias?.toString() ?? '';
    c.cantidadCtrl.text = i.cantidadTotal == null
        ? ''
        : ItemReceta.formatearNumero(i.cantidadTotal!);
    c.medicamentoId = i.medicamentoId;
    c.principioActivo = i.principioActivo;
    c.justificacionRiesgo = i.justificacionRiesgo;
    return c;
  }

  ItemReceta toItem() {
    return ItemReceta.estructurado(
      medicamentoId: medicamentoId,
      nombreMedicamento: nombreCtrl.text.trim(),
      principioActivo: principioActivo,
      presentacionConcentracion: presentacionCtrl.text.trim(),
      dosisCantidad: double.tryParse(dosisCtrl.text.trim()) ?? 0,
      dosisUnidad: unidadCtrl.text.trim(),
      viaAdministracion: viaCtrl.text.trim(),
      frecuenciaHoras: double.tryParse(frecuenciaCtrl.text.trim()) ?? 0,
      duracionDias: int.tryParse(duracionCtrl.text.trim()) ?? 0,
      cantidadTotal: double.tryParse(cantidadCtrl.text.trim()) ?? 0,
      justificacionRiesgo: justificacionRiesgo,
    );
  }

  void dispose() {
    nombreCtrl.dispose();
    presentacionCtrl.dispose();
    dosisCtrl.dispose();
    unidadCtrl.dispose();
    viaCtrl.dispose();
    frecuenciaCtrl.dispose();
    duracionCtrl.dispose();
    cantidadCtrl.dispose();
  }
}
