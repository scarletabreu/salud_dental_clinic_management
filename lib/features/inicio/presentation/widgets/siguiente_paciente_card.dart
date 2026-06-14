import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

class SiguientePacienteCard extends StatelessWidget {
  final Cita? cita;
  final void Function(EstadoCita)? onCambiarEstado;

  const SiguientePacienteCard({super.key, this.cita, this.onCambiarEstado});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ac.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ac.teal, ac.tealLight],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: cita != null
                    ? _WithPatient(cita: cita!, onCambiarEstado: onCambiarEstado)
                    : const _Empty(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ac.chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 24,
            color: ac.textDisabled,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGUIENTE PACIENTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ac.textDisabled,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin pacientes en espera',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ac.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cuando un paciente sea registrado en espera, aparecerá aquí.',
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Con paciente ─────────────────────────────────────────────────────────────

class _WithPatient extends StatelessWidget {
  final Cita cita;
  final void Function(EstadoCita)? onCambiarEstado;

  const _WithPatient({required this.cita, this.onCambiarEstado});

  String _waitTime() {
    final diff = DateTime.now().difference(cita.date);
    if (diff.isNegative) return 'Puntual';
    final mins = diff.inMinutes;
    if (mins == 0) return 'Acaba de llegar';
    if (mins < 60) return 'Esperando $mins min';
    final hrs = diff.inHours;
    return 'Esperando ${hrs}h ${mins % 60}min';
  }

  Color _waitColor(AppColors ac) {
    final mins = DateTime.now().difference(cita.date).inMinutes;
    if (mins >= 30) return ac.red;
    if (mins >= 15) return ac.orange;
    return ac.green;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final h = cita.date.hour.toString().padLeft(2, '0');
    final m = cita.date.minute.toString().padLeft(2, '0');
    final canAct = onCambiarEstado != null && cita.id != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SIGUIENTE PACIENTE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ac.teal,
                letterSpacing: 1.0,
              ),
            ),
            if (cita.esEmergencia) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ac.emergencyBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'EMERGENCIA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: ac.red,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: ac.teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 26,
                color: ac.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita.persona.fullName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: ac.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$h:$m',
                        style: TextStyle(
                          fontSize: 12,
                          color: ac.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ac.textDisabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _waitTime(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _waitColor(ac),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAct
                    ? () => onCambiarEstado!(EstadoCita.cancelada)
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: ac.red,
                  side: BorderSide(color: ac.red.withValues(alpha: 0.35)),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 15),
                label: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canAct
                    ? () => onCambiarEstado!(EstadoCita.enConsulta)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: ac.primaryBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Iniciar Consulta'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
