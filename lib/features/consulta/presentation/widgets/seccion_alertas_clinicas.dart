import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';

/// Las alertas del motor clínico, con el dato que las disparó a la vista
/// (HFX-CLIN-003).
///
/// No diagnostican ni deciden: dicen qué se detectó, con qué severidad y qué
/// acción hace falta para poder cerrar la consulta.
class SeccionAlertasClinicas extends StatelessWidget {
  const SeccionAlertasClinicas({super.key, required this.alertas});

  final List<AlertaClinica> alertas;

  @override
  Widget build(BuildContext context) {
    final vigentes = [
      for (final a in alertas)
        if (a.estado != EstadoAlerta.obsoleta) a,
    ];
    if (vigentes.isEmpty) return const SizedBox.shrink();

    final ac = context.appColors;
    final bloqueantes = vigentes.where((a) => a.bloqueaCierre).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (bloqueantes > 0 ? ac.red : ac.amber).withValues(alpha: 0.35),
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bloqueantes > 0
                    ? Icons.dangerous_rounded
                    : Icons.warning_amber_rounded,
                size: 20,
                color: bloqueantes > 0 ? ac.red : ac.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bloqueantes > 0
                      ? 'Alertas clínicas por resolver ($bloqueantes)'
                      : 'Alertas clínicas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final alerta in vigentes)
            _TarjetaAlerta(alerta: alerta, key: ValueKey(alerta.id)),
        ],
      ),
    );
  }
}

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta, super.key});

  final AlertaClinica alerta;

  Color _color(AppColors ac) => switch (alerta.severidad) {
    SeveridadAlerta.absoluta => ac.red,
    SeveridadAlerta.critica => ac.red,
    SeveridadAlerta.advertencia => ac.amber,
    SeveridadAlerta.informativa => ac.teal,
  };

  /// El dato que activó la regla, dicho en una línea. Sin esto la alerta es
  /// una orden sin motivo.
  String? get _detalleDisparador {
    final codigo = alerta.disparador['codigo'];
    final valor = alerta.disparador['valor'];
    if (codigo == null || valor == null) return null;
    final condicion = alerta.disparador['condicion'];
    final rango = [
      if (alerta.disparador['min'] != null) 'mín ${alerta.disparador['min']}',
      if (alerta.disparador['max'] != null) 'máx ${alerta.disparador['max']}',
    ].join(' · ');
    return [
      'Dato: $codigo = $valor',
      if (rango.isNotEmpty) 'Rango aprobado: $rango',
      if (condicion != null) 'Condición: $condicion',
    ].join('   ');
  }

  Future<void> _resolver(BuildContext context, {required bool documentar}) async {
    final cubit = context.read<ConsultaCubit>();
    String? justificacion;

    if (documentar) {
      justificacion = await _pedirJustificacion(context, alerta);
      if (justificacion == null) return;
    }

    await cubit.resolverAlerta(
      alerta,
      documentada: documentar,
      justificacion: justificacion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = _color(ac);
    final resuelta = !alerta.estaPendiente;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: resuelta ? 0.05 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alerta.severidad.etiqueta.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alerta.accion.etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ac.textSecondary,
                  ),
                ),
              ),
              if (resuelta)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: ac.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alerta.estado == EstadoAlerta.documentada
                          ? 'Documentada'
                          : 'Confirmada',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ac.primaryGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alerta.mensaje,
            style: TextStyle(fontSize: 13.5, color: ac.textPrimary, height: 1.4),
          ),
          if (_detalleDisparador case final detalle?) ...[
            const SizedBox(height: 6),
            Text(
              detalle,
              style: TextStyle(fontSize: 11.5, color: ac.textMuted),
            ),
          ],
          if (alerta.justificacion case final justificacion?) ...[
            const SizedBox(height: 8),
            Text(
              'Justificación: $justificacion',
              style: TextStyle(
                fontSize: 12,
                color: ac.textSecondary,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!resuelta) ...[
            const SizedBox(height: 6),
            Text(
              alerta.accion.indicacion,
              style: TextStyle(fontSize: 12, color: ac.textMuted, height: 1.35),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!alerta.accion.exigeJustificacion)
                  TextButton(
                    onPressed: () => _resolver(context, documentar: false),
                    child: const Text('Confirmar que lo revisé'),
                  ),
                FilledButton.icon(
                  onPressed: () => _resolver(context, documentar: true),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.edit_note_rounded, size: 17),
                  label: const Text('Documentar acción'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<String?> _pedirJustificacion(
  BuildContext context,
  AlertaClinica alerta,
) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final ac = ctx.appColors;
      return AppDialog(
        preferredWidth: 460,
        title: const Text('Documentar la acción clínica'),
        scrollable: false,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alerta.mensaje,
                style: TextStyle(
                  fontSize: 13,
                  color: ac.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Qué decidiste y por qué',
                  hintText:
                      'Ej. Se pospone el tratamiento electivo y se refiere a '
                      'control médico.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La justificación clínica es obligatoria.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
