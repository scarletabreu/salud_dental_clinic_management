import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';

const _kHourStart = 8;
const _kHourEnd = 20;
const _kHourHeight = 64.0;
const _kHeaderHeight = 48.0;
const _kTimeAxisWidth = 52.0;
const _kAccentCalendar = Color(0xFF0066FF);

// ─────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────

class WeekTimelineView extends StatelessWidget {
  final List<Cita> citas;
  final DateTime weekStart; // must be Monday

  const WeekTimelineView({
    super.key,
    required this.citas,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return _TimelineScaffold(
      days: days,
      citas: citas,
    );
  }
}

class DayTimelineView extends StatelessWidget {
  final List<Cita> citas;
  final DateTime day;

  const DayTimelineView({super.key, required this.citas, required this.day});

  @override
  Widget build(BuildContext context) {
    return _TimelineScaffold(days: [day], citas: citas);
  }
}

// ─────────────────────────────────────────────────────────────
// Scaffold compartido
// ─────────────────────────────────────────────────────────────

class _TimelineScaffold extends StatelessWidget {
  final List<DateTime> days;
  final List<Cita> citas;

  const _TimelineScaffold({required this.days, required this.citas});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = days.length == 1
            ? (constraints.maxWidth - _kTimeAxisWidth)
            : (constraints.maxWidth - _kTimeAxisWidth) / days.length;

        return Column(
          children: [
            _DayHeaders(days: days, columnWidth: columnWidth),
            const Divider(height: 1, color: kDivider),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: (_kHourEnd - _kHourStart) * _kHourHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HourAxis(),
                      ...days.map((day) {
                        final dayCitas = citas
                            .where(
                              (c) =>
                                  c.date.year == day.year &&
                                  c.date.month == day.month &&
                                  c.date.day == day.day,
                            )
                            .toList();
                        return _DayColumn(
                          day: day,
                          citas: dayCitas,
                          width: columnWidth,
                          isLast: day == days.last,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Headers de columna de día
// ─────────────────────────────────────────────────────────────

const _kDayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class _DayHeaders extends StatelessWidget {
  final List<DateTime> days;
  final double columnWidth;

  const _DayHeaders({required this.days, required this.columnWidth});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: _kHeaderHeight,
      child: Row(
        children: [
          SizedBox(width: _kTimeAxisWidth),
          ...days.map((day) {
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            final isWeekend = day.weekday >= 6;
            return SizedBox(
              width: columnWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _kDayLabels[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isToday
                          ? _kAccentCalendar
                          : isWeekend
                              ? kRed.withValues(alpha: 0.7)
                              : kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isToday ? _kAccentCalendar : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : isWeekend
                            ? kRed.withValues(alpha: 0.7)
                            : kTextPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Eje de horas
// ─────────────────────────────────────────────────────────────

class _HourAxis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kTimeAxisWidth,
      child: Stack(
        children: List.generate(_kHourEnd - _kHourStart, (i) {
          final hour = _kHourStart + i;
          return Positioned(
            top: i * _kHourHeight - 7,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: kTextDisabled,
                  height: 1,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Columna de un día: grid + citas posicionadas
// ─────────────────────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final List<Cita> citas;
  final double width;
  final bool isLast;

  const _DayColumn({
    required this.day,
    required this.citas,
    required this.width,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    final totalHeight = (_kHourEnd - _kHourStart) * _kHourHeight;

    // Calcular hora actual en px
    double? nowLine;
    if (isToday) {
      final diffMin = (now.hour - _kHourStart) * 60 + now.minute;
      final pct = diffMin / ((_kHourEnd - _kHourStart) * 60);
      if (pct >= 0 && pct <= 1) {
        nowLine = pct * totalHeight;
      }
    }

    // Algoritmo de lanes para solapamiento
    final lanes = _assignLanes(citas);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: kDivider, width: 1),
          right: isLast ? const BorderSide(color: kDivider, width: 1) : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          // Líneas de hora
          ...List.generate(_kHourEnd - _kHourStart, (i) {
            return Positioned(
              top: i * _kHourHeight,
              left: 0,
              right: 0,
              child: const Divider(height: 1, color: kRowDivider),
            );
          }),
          // Línea media hora (más sutil)
          ...List.generate(_kHourEnd - _kHourStart, (i) {
            return Positioned(
              top: i * _kHourHeight + _kHourHeight / 2,
              left: 8,
              right: 0,
              child: Container(height: 1, color: kRowDivider),
            );
          }),
          // Tarjetas de cita
          ...citas.map((cita) {
            final lane = lanes[cita.id ?? cita.date.toString()];
            final laneCount = lane?['total'] ?? 1;
            final laneIndex = lane?['index'] ?? 0;
            final cardWidth = (width - 4) / laneCount;
            final cardLeft = 2 + laneIndex * cardWidth;
            return _PositionedCitaBlock(
              cita: cita,
              left: cardLeft,
              width: cardWidth - 2,
            );
          }),
          // Línea de hora actual
          if (nowLine != null)
            Positioned(
              top: nowLine,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kAccentCalendar,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(height: 2, color: _kAccentCalendar),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Map<String, Map<String, int>> _assignLanes(List<Cita> citas) {
    final sorted = [...citas]..sort((a, b) => a.date.compareTo(b.date));
    // Grupos de solapamiento
    final List<List<Cita>> groups = [];
    for (final cita in sorted) {
      bool placed = false;
      for (final group in groups) {
        final overlaps = group.any((c) =>
            c.date.isBefore(cita.fechaFin) && cita.date.isBefore(c.fechaFin));
        if (overlaps) {
          group.add(cita);
          placed = true;
          break;
        }
      }
      if (!placed) groups.add([cita]);
    }

    final result = <String, Map<String, int>>{};
    for (final group in groups) {
      for (var i = 0; i < group.length; i++) {
        final key = group[i].id ?? group[i].date.toString();
        result[key] = {'index': i, 'total': group.length};
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────
// Bloque de cita posicionado
// ─────────────────────────────────────────────────────────────

class _PositionedCitaBlock extends StatelessWidget {
  final Cita cita;
  final double left;
  final double width;

  const _PositionedCitaBlock({
    required this.cita,
    required this.left,
    required this.width,
  });

  double _topOffset() {
    final diffMin = (cita.date.hour - _kHourStart) * 60 + cita.date.minute;
    return diffMin / 60 * _kHourHeight;
  }

  double _blockHeight() {
    final h = cita.duracionMinutos / 60 * _kHourHeight;
    return h.clamp(24.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final top = _topOffset();
    final height = _blockHeight();
    final color = cita.estado.color;
    final isShort = height < 40;

    return Positioned(
      top: top + 1,
      left: left,
      width: width,
      height: height - 2,
      child: _CitaBlock(
        cita: cita,
        color: color,
        isShort: isShort,
      ),
    );
  }
}

class _CitaBlock extends StatelessWidget {
  final Cita cita;
  final Color color;
  final bool isShort;

  const _CitaBlock({
    required this.cita,
    required this.color,
    required this.isShort,
  });

  void _showStatusMenu(BuildContext context) {
    final cubit = context.read<CitaCubit>();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    showMenu<EstadoCita>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: EstadoCita.values.map((e) {
        final isActive = e == cita.estado;
        return PopupMenuItem<EstadoCita>(
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? e.color : kTextSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((nuevoEstado) {
      if (!context.mounted) return;
      if (nuevoEstado == null || nuevoEstado == cita.estado) return;
      if (nuevoEstado == EstadoCita.cancelada) {
        _showCancelDialog(context, cubit);
      } else {
        cubit.cambiarEstadoCita(cita.id!, nuevoEstado);
      }
    });
  }

  void _showCancelDialog(BuildContext context, CitaCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kRed),
            SizedBox(width: 8),
            Text(
              '¿Cancelar Cita?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta acción liberará el espacio en el calendario del odontólogo. ¿Desea continuar?',
          style: TextStyle(fontSize: 13, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Atrás', style: TextStyle(color: kTextMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              cubit.cambiarEstadoCita(cita.id!, EstadoCita.cancelada);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startH = cita.date.hour.toString().padLeft(2, '0');
    final startM = cita.date.minute.toString().padLeft(2, '0');
    final endH = cita.fechaFin.hour.toString().padLeft(2, '0');
    final endM = cita.fechaFin.minute.toString().padLeft(2, '0');
    final timeRange = '$startH:$startM – $endH:$endM';

    return GestureDetector(
      onTap: () => _showStatusMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            top: BorderSide(color: color, width: 2.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.fromLTRB(6, isShort ? 3 : 5, 4, 3),
        child: isShort
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      cita.persona.fullName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cita.persona.fullName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                            height: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cita.esEmergencia)
                        Icon(
                          Icons.priority_high_rounded,
                          size: 10,
                          color: kRed,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextMuted,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    timeRange,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.75),
                      height: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
