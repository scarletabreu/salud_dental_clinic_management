import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seleccionar_condicion_sheet.dart';

/// Condiciones descubiertas durante la consulta (HFX-CLIN-003).
///
/// Cuentan desde que se registran: el selector de tratamientos y el de
/// medicinas ya las cruzan con las contraindicaciones del catálogo, sin
/// esperar a que alguien las copie al expediente.
class SeccionCondicionesDetectadas extends StatelessWidget {
  const SeccionCondicionesDetectadas({
    super.key,
    required this.detectadas,
    required this.catalogo,
  });

  final List<CondicionDetectada> detectadas;
  final List<Condicion> catalogo;

  Future<void> _agregar(BuildContext context) async {
    final cubit = context.read<ConsultaCubit>();
    final disponibles = [
      for (final c in catalogo)
        if (!detectadas.any((d) => d.condicionId == c.id)) c,
    ];
    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más condiciones disponibles en el catálogo.'),
        ),
      );
      return;
    }
    final nueva = await seleccionarCondicionDetectada(context, disponibles);
    if (nueva == null) return;
    cubit.agregarCondicionDetectada(nueva);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Una condición registrada aquí participa de inmediato en las '
                'contraindicaciones de medicinas y tratamientos.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: ac.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _agregar(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (detectadas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin condiciones nuevas registradas en esta consulta.',
              style: TextStyle(fontSize: 13, color: ac.textMuted),
            ),
          )
        else
          for (var i = 0; i < detectadas.length; i++)
            _Fila(
              condicion: detectadas[i],
              onQuitar: () =>
                  context.read<ConsultaCubit>().quitarCondicionDetectada(i),
              onCambiarIncorporacion: (valor) => context
                  .read<ConsultaCubit>()
                  .actualizarCondicionDetectada(
                    i,
                    detectadas[i].copyWith(incorporarAlExpediente: valor),
                  ),
            ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.condicion,
    required this.onQuitar,
    required this.onCambiarIncorporacion,
  });

  final CondicionDetectada condicion;
  final VoidCallback onQuitar;
  final ValueChanged<bool> onCambiarIncorporacion;

  Color _color(AppColors ac) => switch (condicion.severidad) {
    SeveridadCondicion.severa => ac.red,
    SeveridadCondicion.moderada => ac.amber,
    SeveridadCondicion.leve => ac.teal,
  };

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = _color(ac);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  condicion.nombre,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              Text(
                condicion.severidad.etiqueta,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              IconButton(
                tooltip: 'Quitar',
                icon: Icon(Icons.close_rounded, size: 16, color: ac.textMuted),
                onPressed: onQuitar,
              ),
            ],
          ),
          if ((condicion.notas ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                condicion.notas!.trim(),
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  value: condicion.incorporarAlExpediente,
                  onChanged: (v) => onCambiarIncorporacion(v ?? false),
                ),
                Expanded(
                  child: Text(
                    'Incorporar al expediente al cerrar la consulta',
                    style: TextStyle(fontSize: 12, color: ac.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
