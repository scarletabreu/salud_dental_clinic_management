import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/cubit/tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_form_dialog.dart';

class TratamientoCard extends StatelessWidget {
  final Tratamiento tratamiento;
  final VoidCallback? onEdit;

  const TratamientoCard({
    super.key,
    required this.tratamiento,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.divider.withOpacity(0.4), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _abrirEdicion(context),
        borderRadius: BorderRadius.circular(14),
        hoverColor: ac.primaryBlue.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ac.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color: ac.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tratamiento.nombre,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    if (tratamiento.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tratamiento.descripcion,
                        style: TextStyle(fontSize: 13, color: ac.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),

              _AlcanceBadge(ac: ac, alcance: tratamiento.alcance.name),
              const SizedBox(width: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRECIO BASE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: ac.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${tratamiento.costo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ac.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              _ActionIcon(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                color: ac.textSecondary.withOpacity(0.6),
                onTap: () =>
                    onEdit != null ? onEdit!() : _abrirEdicion(context),
              ),
              const SizedBox(width: 2),
              _ActionIcon(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Eliminar',
                color: ac.red.withOpacity(0.70),
                onTap: () => _confirmarEliminacion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirEdicion(BuildContext context) {
    if (onEdit != null) {
      onEdit!();
    } else {
      final cubit = context.read<TratamientoCubit>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: TratamientoFormDialog(tratamiento: tratamiento),
        ),
      );
    }
  }

  void _confirmarEliminacion(BuildContext context) {
    final cubit = context.read<TratamientoCubit>();
    final ac = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ac.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ac.red.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: ac.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Eliminar tratamiento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Esta acción deshabilitará permanentemente "${tratamiento.nombre}" del catálogo clínico.',
                  style: TextStyle(fontSize: 13, color: ac.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ac.textSecondary,
                        side: BorderSide(color: ac.divider),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        cubit.eliminarTratamiento(tratamiento.id!);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Eliminar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlcanceBadge extends StatelessWidget {
  final AppColors ac;
  final String alcance;
  const _AlcanceBadge({required this.ac, required this.alcance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ac.primaryBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ac.primaryBlue.withOpacity(0.20)),
      ),
      child: Text(
        alcance.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: ac.primaryBlue,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
