import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

class DashboardCitasHoySection extends StatelessWidget {
  final List<Cita> citas;
  final void Function(String citaId, EstadoCita nuevoEstado)? onCambiarEstado;

  const DashboardCitasHoySection({
    super.key,
    required this.citas,
    this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Citas de Hoy',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ac.chipBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${citas.length} total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ac.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: ac.divider),

          if (citas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 32,
                      color: ac.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin citas programadas para hoy',
                      style: TextStyle(
                        fontSize: 13,
                        color: ac.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < citas.length; i++) ...[
                  _CitaRow(cita: citas[i], onCambiarEstado: onCambiarEstado),
                  if (i < citas.length - 1)
                    Divider(
                      height: 1,
                      color: ac.rowDivider,
                      indent: 76,
                      endIndent: 20,
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CitaRow extends StatelessWidget {
  final Cita cita;
  final void Function(String citaId, EstadoCita nuevoEstado)? onCambiarEstado;

  const _CitaRow({required this.cita, this.onCambiarEstado});

  String? _waitLabel() {
    if (cita.estado != EstadoCita.enEspera) return null;
    final diff = DateTime.now().difference(cita.date);
    if (diff.isNegative) return null;
    final mins = diff.inMinutes;
    if (mins == 0) return 'Acaba de llegar';
    if (mins < 60) return '$mins min esperando';
    return '${diff.inHours}h ${mins % 60}min';
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
    final waitLabel = _waitLabel();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2),
            child: Text(
              '$h:$m',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ac.textDisabled,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cita.estado.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cita.persona.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ac.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cita.esEmergencia)
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ac.emergencyBg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Emergencia',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: ac.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (waitLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    waitLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _waitColor(ac),
                    ),
                  ),
                ],
                if (!_estadoEnLinea(context)) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _selectorEstado(context),
                  ),
                ],
              ],
            ),
          ),
          // Con texto ampliado el estado no cabe en la misma línea que el
          // nombre: baja bajo los datos de la cita.
          if (!_estadoEnLinea(context)) const SizedBox.shrink(),
          if (_estadoEnLinea(context)) const SizedBox(width: 10),
          if (_estadoEnLinea(context))
            _selectorEstado(context)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  bool _estadoEnLinea(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) <= 1.3;

  Widget _selectorEstado(BuildContext context) {
    final canChange = onCambiarEstado != null && cita.id != null;
    return Builder(
      builder: (context) {
        if (canChange) {
          return PopupMenuButton<EstadoCita>(
            onSelected: (nuevoEstado) =>
                onCambiarEstado!(cita.id!, nuevoEstado),
            itemBuilder: (context) => cita.estado.transicionesPermitidas
                .map(
                  (e) => PopupMenuItem<EstadoCita>(
                    value: e,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(e.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                )
                .toList(),
            tooltip: 'Cambiar estado',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _StatusPill(estado: cita.estado, showArrow: true),
          );
        }
        return _StatusPill(estado: cita.estado, showArrow: false);
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final EstadoCita estado;
  final bool showArrow;

  const _StatusPill({required this.estado, required this.showArrow});

  @override
  Widget build(BuildContext context) {
    // Píldora de estado: acompaña a cada fila de la lista, así que su rótulo
    // no puede crecer sin límite ni empujar al nombre del paciente.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: estado.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                estado.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: estado.color,
                ),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 13,
                color: estado.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
