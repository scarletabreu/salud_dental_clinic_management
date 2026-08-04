import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

class DashboardHeaderCard extends StatelessWidget {
  final VoidCallback? onVerCitas;
  final String? nombreDoctor;
  final int? citasHoy;
  final int? citasEnEspera;

  const DashboardHeaderCard({
    super.key,
    this.onVerCitas,
    this.nombreDoctor,
    this.citasHoy,
    this.citasEnEspera,
  });

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _fechaFormateada() {
    final hoy = DateTime.now();
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dias[hoy.weekday - 1]} ${hoy.day} ${meses[hoy.month - 1]}, ${hoy.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ac.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_hospital_rounded,
                        color: ac.teal,
                        size: 22,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _saludo(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: ac.textDisabled,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nombreDoctor ?? 'Doctor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (narrow) ...[
                      const SizedBox(height: 8),
                      _DateChip(date: _fechaFormateada()),
                    ],
                  ],
                ),
              ),
              if (!narrow) _DateChip(date: _fechaFormateada()),
            ],
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (citasHoy != null)
                    _StatusChip(label: '$citasHoy citas hoy', color: ac.indigo),
                  if (citasEnEspera != null && citasEnEspera! > 0)
                    _StatusChip(
                      label: '$citasEnEspera en espera',
                      color: ac.amber,
                    ),
                ],
              ),
              if (onVerCitas != null)
                GestureDetector(
                  onTap: onVerCitas,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver citas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ac.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: ac.primaryGreen,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        date,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ac.textMuted,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
