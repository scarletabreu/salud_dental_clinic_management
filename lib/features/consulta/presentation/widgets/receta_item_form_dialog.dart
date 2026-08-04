import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/conflicto.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

/// Formulario de un renglón de receta (HFX-CLIN-003).
///
/// Dosis, frecuencia, duración y cantidad se capturan como números: es lo que
/// permite comprobar que lo despachado alcanza para la pauta. Si el paciente
/// tiene una contraindicación relativa para este medicamento, la justificación
/// clínica se pide aquí, por medicamento, y no como una nota suelta de la
/// receta completa.
Future<ItemReceta?> mostrarRecetaItemFormDialog(
  BuildContext context,
  Medicina medicina, {
  ItemReceta? itemExistente,
  List<Conflicto> conflictosRelativos = const [],
}) {
  return showDialog<ItemReceta>(
    context: context,
    builder: (ctx) => _RecetaItemFormDialog(
      medicina: medicina,
      itemExistente: itemExistente,
      conflictosRelativos: conflictosRelativos,
    ),
  );
}

class _RecetaItemFormDialog extends StatefulWidget {
  final Medicina medicina;
  final ItemReceta? itemExistente;
  final List<Conflicto> conflictosRelativos;

  const _RecetaItemFormDialog({
    required this.medicina,
    this.itemExistente,
    this.conflictosRelativos = const [],
  });

  @override
  State<_RecetaItemFormDialog> createState() => _RecetaItemFormDialogState();
}

class _RecetaItemFormDialogState extends State<_RecetaItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dosisCantidad;
  late final TextEditingController _dosisUnidad;
  late final TextEditingController _presentacion;
  late final TextEditingController _via;
  late final TextEditingController _frecuencia;
  late final TextEditingController _duracion;
  late final TextEditingController _cantidad;
  late final TextEditingController _indicaciones;
  late final TextEditingController _justificacion;

  /// El doctor tocó la cantidad: a partir de ahí no se recalcula sola.
  bool _cantidadEditada = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemExistente;

    _dosisCantidad = TextEditingController(
      text: item?.dosisCantidad == null
          ? ''
          : ItemReceta.formatearNumero(item!.dosisCantidad!),
    );
    _dosisUnidad = TextEditingController(
      text: item?.dosisUnidad.isNotEmpty == true ? item!.dosisUnidad : 'tableta',
    );
    _presentacion = TextEditingController(
      text: item?.presentacionConcentracion ?? '',
    );
    _via = TextEditingController(text: item?.viaAdministracion ?? 'oral');
    _frecuencia = TextEditingController(
      text: item?.frecuenciaHoras == null
          ? ''
          : ItemReceta.formatearNumero(item!.frecuenciaHoras!),
    );
    _duracion = TextEditingController(text: item?.duracionDias?.toString() ?? '');
    _cantidad = TextEditingController(
      text: item?.cantidadTotal == null
          ? ''
          : ItemReceta.formatearNumero(item!.cantidadTotal!),
    );
    _indicaciones = TextEditingController(
      text: item?.indicacionesEspecificas ?? '',
    );
    _justificacion = TextEditingController(text: item?.justificacionRiesgo ?? '');
    _cantidadEditada = _cantidad.text.isNotEmpty;

    for (final ctrl in [_dosisCantidad, _frecuencia, _duracion]) {
      ctrl.addListener(_sugerirCantidad);
    }
    _cantidad.addListener(() => _cantidadEditada = true);
  }

  @override
  void dispose() {
    for (final ctrl in [
      _dosisCantidad,
      _dosisUnidad,
      _presentacion,
      _via,
      _frecuencia,
      _duracion,
      _cantidad,
      _indicaciones,
      _justificacion,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _sugerirCantidad() {
    if (_cantidadEditada) {
      setState(() {});
      return;
    }
    final sugerida = ItemReceta.sugerirCantidad(
      dosisCantidad: double.tryParse(_dosisCantidad.text.trim()),
      frecuenciaHoras: double.tryParse(_frecuencia.text.trim()),
      duracionDias: int.tryParse(_duracion.text.trim()),
    );
    if (sugerida == null) return;
    _cantidad.value = TextEditingValue(
      text: ItemReceta.formatearNumero(sugerida),
    );
    _cantidadEditada = false;
    setState(() {});
  }

  ItemReceta _construir() => ItemReceta.estructurado(
    id: widget.itemExistente?.id,
    medicamentoId: widget.medicina.id,
    nombreMedicamento: widget.medicina.nombre,
    principioActivo: widget.medicina.principioActivo,
    presentacionConcentracion: _presentacion.text.trim(),
    dosisCantidad: double.tryParse(_dosisCantidad.text.trim()) ?? 0,
    dosisUnidad: _dosisUnidad.text.trim(),
    viaAdministracion: _via.text.trim(),
    frecuenciaHoras: double.tryParse(_frecuencia.text.trim()) ?? 0,
    duracionDias: int.tryParse(_duracion.text.trim()) ?? 0,
    cantidadTotal: double.tryParse(_cantidad.text.trim()) ?? 0,
    indicacionesEspecificas: _indicaciones.text.trim().isEmpty
        ? null
        : _indicaciones.text.trim(),
    justificacionRiesgo: _justificacion.text.trim().isEmpty
        ? null
        : _justificacion.text.trim(),
  );

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final item = _construir();
    final problemas = item.validar();
    if (problemas.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(problemas.first),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final previo = _construir();
    final incoherente =
        _cantidad.text.trim().isNotEmpty && !previo.cantidadEsCoherente;

    return AppDialog(
      preferredWidth: 520,
      title: Row(
        children: [
          Icon(Icons.medication_rounded, size: 22, color: ac.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.medicina.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.medicina.principioActivo?.trim().isNotEmpty == true
                      ? 'Principio activo: ${widget.medicina.principioActivo}'
                      : 'Sin principio activo en el catálogo: no se puede '
                            'evaluar duplicidad ni interacción.',
                  style: TextStyle(fontSize: 11.5, color: ac.textMuted),
                ),
              ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.conflictosRelativos.isNotEmpty)
                _AvisoRiesgoRelativo(conflictos: widget.conflictosRelativos),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _numero(ac, _dosisCantidad, 'Dosis *', 'Ej. 1'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _texto(
                      ac,
                      _dosisUnidad,
                      'Unidad *',
                      'tableta, ml, cápsula',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _texto(
                      ac,
                      _presentacion,
                      'Concentración',
                      'Ej. 500 mg',
                      requerido: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numero(
                      ac,
                      _frecuencia,
                      'Cada … horas *',
                      'Ej. 8',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numero(ac, _duracion, 'Durante … días *', 'Ej. 5'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _texto(ac, _via, 'Vía *', 'oral, tópica'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _numero(
                ac,
                _cantidad,
                'Cantidad total a despachar *',
                'Se calcula desde la pauta; puedes ajustarla',
              ),
              if (previo.cantidadEsperada != null) ...[
                const SizedBox(height: 6),
                Text(
                  incoherente
                      ? 'La pauta necesita ~'
                            '${ItemReceta.formatearNumero(previo.cantidadEsperada!)} '
                            '${_dosisUnidad.text.trim()}: revisa la cantidad.'
                      : 'La pauta necesita ~'
                            '${ItemReceta.formatearNumero(previo.cantidadEsperada!)} '
                            '${_dosisUnidad.text.trim()}.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: incoherente ? ac.red : ac.textMuted,
                    fontWeight: incoherente ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _texto(
                ac,
                _indicaciones,
                'Indicaciones específicas',
                'Ej. Tomar junto con los alimentos',
                requerido: false,
                maxLines: 2,
              ),
              if (widget.conflictosRelativos.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _justificacion,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Justificación clínica de este medicamento *',
                    hintText:
                        'Por qué se indica pese al riesgo relativo detectado',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El servidor no emite este renglón sin justificación.'
                      : null,
                ),
              ],
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

  Widget _numero(
    AppColors ac,
    TextEditingController controller,
    String label,
    String hint,
  ) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    validator: (v) {
      final valor = double.tryParse((v ?? '').trim());
      if (valor == null || valor <= 0) return 'Indica un número mayor que 0';
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _texto(
    AppColors ac,
    TextEditingController controller,
    String label,
    String hint, {
    bool requerido = true,
    int maxLines = 1,
  }) => TextFormField(
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

class _AvisoRiesgoRelativo extends StatelessWidget {
  const _AvisoRiesgoRelativo({required this.conflictos});

  final List<Conflicto> conflictos;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ac.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 17, color: ac.amber),
              const SizedBox(width: 8),
              Text(
                'Riesgo relativo para este paciente',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final conflicto in conflictos)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '· ${conflicto.condicionPaciente.nombre}: '
                '${conflicto.descripcion}',
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
