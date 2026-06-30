import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/conflicto.dart';

Future<String?> mostrarContraindicacionDialog(
  BuildContext context,
  String tratamientoNombre,
  List<Conflicto> conflictos,
) {
  if (conflictos.isEmpty) return Future.value(null);

  final c = context.appColors;
  final tieneAbsoluta = conflictos.any((conf) => conf.severidad == SeveridadConflicto.absoluta);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  tieneAbsoluta ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
                  color: tieneAbsoluta ? c.red : c.orange,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Contraindicaciones para "$tratamientoNombre"')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieneAbsoluta
                        ? 'No se puede aplicar este tratamiento porque existen contraindicaciones ABSOLUTAS.'
                        : 'Este tratamiento está contraindicado, pero puede aplicarse si registras una justificación clínica.',
                    style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ...conflictos.map((conflicto) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ConflictoTile(conflicto: conflicto),
                      )),
                  if (!tieneAbsoluta) ...[
                    const SizedBox(height: 10),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Justificación clínica',
                          hintText: 'Describe por qué aplicar este tratamiento a pesar del riesgo',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La justificación clínica es obligatoria.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
              if (!tieneAbsoluta)
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                  child: const Text('Aplicar de todas formas'),
                ),
            ],
          );
        },
      );
    },
  );
}

class _ConflictoTile extends StatelessWidget {
  final Conflicto conflicto;

  const _ConflictoTile({required this.conflicto});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final severityColor = _colorForSeverity(conflicto.severidad);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: severityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                conflicto.severidad.label,
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conflicto.condicionPaciente.nombre,
                  style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflicto.descripcion,
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _colorForSeverity(SeveridadConflicto severity) {
    return switch (severity) {
      SeveridadConflicto.absoluta => const Color(0xFFEF4444),
      SeveridadConflicto.critica => const Color(0xFFF59E0B),
      SeveridadConflicto.advertencia => const Color(0xFFFBBF24),
    };
  }
}
