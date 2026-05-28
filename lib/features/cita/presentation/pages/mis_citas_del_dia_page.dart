import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import '../cubit/cita_cubit.dart';
import '../cubit/cita_state.dart';
import '../widgets/timeline_view.dart';

const _kAccentCalendar = Color(0xFF0066FF);

const _kMonths = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _kMonthsShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _kWeekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _kWeekdaysShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class MisCitasDelDiaPage extends StatelessWidget {
  const MisCitasDelDiaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: kBgPage,
      child: BlocBuilder<CitaCubit, CitaState>(
        builder: _buildState,
      ),
    );
  }

  static Widget _buildState(BuildContext context, CitaState state) {
    if (state is CitaLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: kTeal,
          strokeWidth: 2,
        ),
      );
    }
    if (state is CitaError) {
      return _ErrorView(message: state.message);
    }
    if (state is CitaLoaded) {
      return _CalendarioView(state: state);
    }
    return const SizedBox.shrink();
  }
}

class _CalendarioView extends StatelessWidget {
  final CitaLoaded state;
  const _CalendarioView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ControlBar(state: state),
        const Divider(height: 1, color: kDivider),
        Expanded(child: _CalendarioBody(state: state)),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  final CitaLoaded state;
  const _ControlBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CitaCubit>();

    return Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SegmentedButton<CalendarioViewMode>(
            segments: const [
              ButtonSegment(
                value: CalendarioViewMode.mensual,
                label: Text('Mes'),
                icon: Icon(Icons.calendar_month_outlined, size: 16),
              ),
              ButtonSegment(
                value: CalendarioViewMode.semanal,
                label: Text('Sem'),
                icon: Icon(Icons.view_week_outlined, size: 16),
              ),
              ButtonSegment(
                value: CalendarioViewMode.diaria,
                label: Text('Día'),
                icon: Icon(Icons.today_outlined, size: 16),
              ),
            ],
            selected: {state.viewMode},
            onSelectionChanged: (s) => cubit.changeViewMode(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return kTextMuted;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _kAccentCalendar;
                }
                return Colors.transparent;
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _currentLabel(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: cubit.goPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Anterior',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(foregroundColor: kTextMuted),
          ),
          OutlinedButton(
            onPressed: cubit.goToToday,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: kDivider),
              foregroundColor: _kAccentCalendar,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Hoy'),
          ),
          IconButton(
            onPressed: cubit.goToNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Siguiente',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(foregroundColor: kTextMuted),
          ),
        ],
      ),
    );
  }

  String _currentLabel() {
    if (state.viewMode == CalendarioViewMode.diaria) {
      final d = state.selectedDay;
      return '${_kWeekdays[d.weekday - 1]}, ${d.day} de ${_kMonths[d.month - 1]} ${d.year}';
    }
    if (state.viewMode == CalendarioViewMode.semanal) {
      final weekStart = _weekStartFor(state.focusedDay);
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (weekStart.month == weekEnd.month) {
        return '${weekStart.day} – ${weekEnd.day} de ${_kMonths[weekStart.month - 1]} ${weekStart.year}';
      }
      return '${weekStart.day} ${_kMonthsShort[weekStart.month - 1]} – ${weekEnd.day} ${_kMonthsShort[weekEnd.month - 1]} ${weekStart.year}';
    }
    return '${_kMonths[state.focusedDay.month - 1]} ${state.focusedDay.year}';
  }

  static DateTime _weekStartFor(DateTime day) {
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class _CalendarioBody extends StatelessWidget {
  final CitaLoaded state;
  const _CalendarioBody({required this.state});

  static DateTime _weekStartFor(DateTime day) {
    return day.subtract(Duration(days: day.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    // ── Vista Día: timeline de 1 columna ──────────────────────
    if (state.viewMode == CalendarioViewMode.diaria) {
      final dayCitas = state.citasForDay(state.selectedDay);
      return DayTimelineView(citas: dayCitas, day: state.selectedDay);
    }

    // ── Vista Semana: timeline de 7 columnas ──────────────────
    if (state.viewMode == CalendarioViewMode.semanal) {
      final weekStart = _weekStartFor(state.focusedDay);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekCitas = state.citas.where((c) {
        final d = c.date;
        return !d.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
            !d.isAfter(DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59));
      }).toList();
      return WeekTimelineView(citas: weekCitas, weekStart: weekStart);
    }

    // ── Vista Mes: mes-grid + panel lateral ───────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 55,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _CalendarSection(state: state, fillHeight: true),
                ),
              ),
              const VerticalDivider(width: 1, color: kDivider),
              Expanded(flex: 45, child: _DetailPanel(state: state)),
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              _CalendarSection(state: state),
              const SizedBox(height: 16),
              SizedBox(height: 380, child: _DetailPanel(state: state)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarSection extends StatelessWidget {
  final CitaLoaded state;
  final bool fillHeight;
  const _CalendarSection({required this.state, this.fillHeight = false});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CitaCubit>();

    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [kCardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TableCalendar<Cita>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: state.focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, state.selectedDay),
          calendarFormat: state.viewMode == CalendarioViewMode.mensual
              ? CalendarFormat.month
              : CalendarFormat.week,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
            CalendarFormat.week: 'Semana',
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          eventLoader: cubit.eventLoader,
          onDaySelected: cubit.selectDay,
          onFormatChanged: (_) {},
          onPageChanged: cubit.onPageChanged,
          calendarBuilders: CalendarBuilders<Cita>(
            dowBuilder: (ctx, day) => _DowCell(day: day),
            defaultBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.normal,
            ),
            selectedBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.selected,
            ),
            todayBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.today,
            ),
            outsideBuilder: (ctx, day, _) => const SizedBox.shrink(),
            markerBuilder: (ctx, day, events) => const SizedBox.shrink(),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.all(3),
          ),
          daysOfWeekHeight: 40,
          rowHeight: 64,
        ),
      ),
    );
  }
}

class _DowCell extends StatelessWidget {
  final DateTime day;
  const _DowCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final label = _kWeekdaysShort[day.weekday - 1];
    final isWeekend = day.weekday >= 6;
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: kBgPage,
        border: Border(
          bottom: BorderSide(color: kDivider, width: 1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isWeekend ? kRed.withValues(alpha: 0.7) : kTextMuted,
        ),
      ),
    );
  }
}

enum _DayCellType { normal, today, selected }

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<Cita> events;
  final _DayCellType type;

  const _DayCell({
    required this.day,
    required this.events,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == _DayCellType.selected;
    final isToday = type == _DayCellType.today;
    final hasEvents = events.isNotEmpty;
    final isWeekend = day.weekday >= 6;

    final Color cellBg;
    final Color dayColor;
    final FontWeight dayWeight;

    if (isSelected) {
      cellBg = _kAccentCalendar;
      dayColor = Colors.white;
      dayWeight = FontWeight.w700;
    } else if (isToday) {
      cellBg = _kAccentCalendar.withValues(alpha: 0.12);
      dayColor = _kAccentCalendar;
      dayWeight = FontWeight.w700;
    } else {
      cellBg = Colors.transparent;
      dayColor = isWeekend ? kRed.withValues(alpha: 0.7) : kTextSecondary;
      dayWeight = hasEvents ? FontWeight.w600 : FontWeight.w400;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: dayWeight,
                color: dayColor,
                height: 1,
              ),
            ),
          ),
          if (hasEvents) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...events.take(3).map(
                      (c) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.75)
                              : c.estado.color,
                        ),
                      ),
                    ),
                if (events.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '+${events.length - 3}',
                      style: TextStyle(
                        fontSize: 8,
                        height: 1,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.65)
                            : kTextDisabled,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final CitaLoaded state;
  const _DetailPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final citas = state.citasForDay(state.selectedDay);
    final d = state.selectedDay;
    final dateLabel =
        '${_kWeekdays[d.weekday - 1]}, ${d.day} de ${_kMonthsShort[d.month - 1]} ${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: kCardBg,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      citas.isEmpty
                          ? 'Sin citas programadas'
                          : '${citas.length} cita${citas.length == 1 ? '' : 's'} agendada${citas.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: citas.isEmpty ? kTextMuted : _kAccentCalendar,
                      ),
                    ),
                  ],
                ),
              ),
              if (citas.isNotEmpty) const _StatusLegend(),
            ],
          ),
        ),
        const Divider(height: 1, color: kDivider),
        Expanded(
          child: citas.isEmpty
              ? const _EmptyDay()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: citas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _CitaCard(cita: citas[i]),
                ),
        ),
      ],
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: EstadoCita.values.map((e) {
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e.color.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: kTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  const _CitaCard({required this.cita});

  void _mostrarDialogoCancelacion(BuildContext context, String citaId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            'Esta acción liberará el espacio en el calendario del odontólogo. ¿Desea continuar con la cancelación?',
            style: TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Atrás',
                style: TextStyle(color: kTextMuted),
              ),
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
                context.read<CitaCubit>().cambiarEstadoCita(
                      citaId,
                      EstadoCita.cancelada,
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Confirmar Cancelación'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = cita.estado.color;
    final hour = cita.date.hour.toString().padLeft(2, '0');
    final min = cita.date.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [kCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time badge
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hour,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    min,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor.withValues(alpha: 0.65),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Patient & doctor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cita.persona.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cita.esEmergencia)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kRed.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high_rounded,
                                size: 10,
                                color: kRed,
                              ),
                              const Text(
                                'Urgente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: kTextMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status pill + dropdown
            PopupMenuButton<EstadoCita>(
              initialValue: cita.estado,
              tooltip: 'Cambiar estado de la cita',
              onSelected: (EstadoCita nuevoEstado) {
                if (nuevoEstado == cita.estado) return;
                if (nuevoEstado == EstadoCita.cancelada) {
                  _mostrarDialogoCancelacion(context, cita.id!);
                } else {
                  context.read<CitaCubit>().cambiarEstadoCita(
                        cita.id!,
                        nuevoEstado,
                      );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cita.estado.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 14, color: statusColor),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) {
                return EstadoCita.values.map((EstadoCita e) {
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
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isActive ? e.color : kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kChipBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 28,
              color: kTextDisabled,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin citas este día',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona otro día para ver citas',
            style: TextStyle(
              fontSize: 12,
              color: kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CitaCubit>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: kRed,
            ),
            const SizedBox(height: 12),
            const Text(
              'Error al cargar citas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: kTextMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
