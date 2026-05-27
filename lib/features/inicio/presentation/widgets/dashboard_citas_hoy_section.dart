import 'package:flutter/material.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Text(
                  'Citas de Hoy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${citas.length} total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          if (citas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 32,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sin citas programadas para hoy',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
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
                    const Divider(
                      height: 1,
                      color: Color(0xFFF9FAFB),
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

  Color _waitColor() {
    final mins = DateTime.now().difference(cita.date).inMinutes;
    if (mins >= 30) return const Color(0xFFDC2626);
    if (mins >= 15) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final h = cita.date.hour.toString().padLeft(2, '0');
    final m = cita.date.minute.toString().padLeft(2, '0');
    final waitLabel = _waitLabel();
    final canChange = onCambiarEstado != null && cita.id != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column — fixed width, right-aligned
          SizedBox(
            width: 40,
            child: Text(
              '$h:$m',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Estado dot
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cita.estado.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name + secondary info
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cita.esEmergencia)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Emergencia',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
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
                      color: _waitColor(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status pill — tappable popup when changes available
          if (canChange)
            PopupMenuButton<EstadoCita>(
              onSelected: (nuevoEstado) =>
                  onCambiarEstado!(cita.id!, nuevoEstado),
              itemBuilder: (context) => EstadoCita.values
                  .where((e) => e != cita.estado)
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
                          Text(
                            e.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              tooltip: 'Cambiar estado',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _StatusPill(
                estado: cita.estado,
                showArrow: true,
              ),
            )
          else
            _StatusPill(estado: cita.estado, showArrow: false),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final EstadoCita estado;
  final bool showArrow;

  const _StatusPill({required this.estado, required this.showArrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            estado.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: estado.color,
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
    );
  }
}
