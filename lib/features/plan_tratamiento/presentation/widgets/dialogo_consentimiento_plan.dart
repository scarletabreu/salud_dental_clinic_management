import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/consentimiento_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';

/// Lo que el doctor registra cuando el paciente decide sobre el plan.
class DecisionConsentimiento {
  final bool aceptado;
  final String persona;
  final String relacion;
  final MetodoConsentimiento metodo;
  final String? motivoRechazo;

  const DecisionConsentimiento({
    required this.aceptado,
    required this.persona,
    required this.relacion,
    required this.metodo,
    this.motivoRechazo,
  });
}

/// Registro del consentimiento del plan (HFX-CLIN-003).
///
/// Pide lo que convierte una decisión en evidencia: quién aceptó, en qué
/// calidad y por qué medio. Un clic del doctor no es la firma del paciente, y
/// esta pantalla lo dice explícitamente.
Future<DecisionConsentimiento?> mostrarDialogoConsentimiento(
  BuildContext context, {
  required PlanTratamiento plan,
  required bool aceptar,
}) {
  return showDialog<DecisionConsentimiento>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DialogoConsentimiento(plan: plan, aceptar: aceptar),
  );
}

class _DialogoConsentimiento extends StatefulWidget {
  const _DialogoConsentimiento({required this.plan, required this.aceptar});

  final PlanTratamiento plan;
  final bool aceptar;

  @override
  State<_DialogoConsentimiento> createState() => _DialogoConsentimientoState();
}

class _DialogoConsentimientoState extends State<_DialogoConsentimiento> {
  final _formKey = GlobalKey<FormState>();
  final _persona = TextEditingController();
  final _relacion = TextEditingController(text: 'titular');
  final _motivo = TextEditingController();
  MetodoConsentimiento _metodo = MetodoConsentimiento.verbalPresencial;

  @override
  void dispose() {
    _persona.dispose();
    _relacion.dispose();
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      DecisionConsentimiento(
        aceptado: widget.aceptar,
        persona: _persona.text.trim(),
        relacion: _relacion.text.trim().isEmpty
            ? 'titular'
            : _relacion.text.trim(),
        metodo: _metodo,
        motivoRechazo: _motivo.text.trim().isEmpty ? null : _motivo.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final total = widget.plan.totalEstimado;

    return AppDialog(
      preferredWidth: 480,
      title: Text(
        widget.aceptar ? 'Registrar aceptación del plan' : 'Registrar rechazo del plan',
      ),
      scrollable: false,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ac.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Versión ${widget.plan.version} del plan · '
                      '${widget.plan.items.length} actividades · '
                      'RD\$ ${total.toStringAsFixed(2)} estimados',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se guarda esta versión y estos precios como lo que el '
                      'paciente vio. Si el plan cambia después, hay que volver '
                      'a pedir su decisión.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ac.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _persona,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Persona que decide *',
                  hintText: 'Nombre completo de quien acepta o rechaza',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Sin nombre no hay evidencia de quién decidió.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relacion,
                decoration: const InputDecoration(
                  labelText: 'Relación con el paciente',
                  hintText: 'titular, madre, tutor legal…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MetodoConsentimiento>(
                initialValue: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método del consentimiento *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final metodo in MetodoConsentimiento.values)
                    DropdownMenuItem(
                      value: metodo,
                      child: Text(metodo.etiqueta),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _metodo = v ?? _metodo),
              ),
              if (!widget.aceptar) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivo,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo *',
                    hintText: 'Qué dijo el paciente',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Un rechazo sin motivo no explica nada después.'
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
        FilledButton(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: widget.aceptar ? ac.primaryGreen : ac.red,
          ),
          child: Text(widget.aceptar ? 'Registrar aceptación' : 'Registrar rechazo'),
        ),
      ],
    );
  }
}
