import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import '../cubit/cita_cubit.dart';
import '../cubit/cita_state.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: BlocBuilder<CitaCubit, CitaState>(
        builder: (context, state) {
          if (state is CitaLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CitaError) {
            return _ErrorView(message: state.message);
          }
          if (state is CitaLoaded) {
            return _CalendarioView(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CalendarioView extends StatelessWidget {
  final CitaLoaded state;
  const _CalendarioView({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ControlBar(state: state),
        Divider(height: 1, color: colorScheme.outlineVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.surface,
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
              textStyle: WidgetStatePropertyAll(textTheme.labelSmall),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _currentLabel(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: cubit.goPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Anterior',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton(
            onPressed: cubit.goToToday,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: BorderSide(color: colorScheme.outlineVariant),
              foregroundColor: colorScheme.primary,
            ),
            child: const Text('Hoy'),
          ),
          IconButton(
            onPressed: cubit.goToNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Siguiente',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
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
    return '${_kMonths[state.focusedDay.month - 1]} ${state.focusedDay.year}';
  }
}

class _CalendarioBody extends StatelessWidget {
  final CitaLoaded state;
  const _CalendarioBody({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.viewMode == CalendarioViewMode.diaria) {
      return _DetailPanel(state: state);
    }
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
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
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
            dowBuilder: (ctx, day) =>
                _DowCell(day: day, colorScheme: colorScheme),
            defaultBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.normal,
              colorScheme: colorScheme,
            ),
            selectedBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.selected,
              colorScheme: colorScheme,
            ),
            todayBuilder: (ctx, day, _) => _DayCell(
              day: day,
              events: state.citasForDay(day),
              type: _DayCellType.today,
              colorScheme: colorScheme,
            ),
            outsideBuilder: (ctx, day, _) => const SizedBox.shrink(),
            markerBuilder: (ctx, day, events) => const SizedBox.shrink(),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(3),
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
  final ColorScheme colorScheme;
  const _DowCell({required this.day, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final label = _kWeekdaysShort[day.weekday - 1];
    final isWeekend = day.weekday >= 6;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isWeekend
              ? colorScheme.error.withValues(alpha: 0.75)
              : colorScheme.onSurfaceVariant,
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
  final ColorScheme colorScheme;

  const _DayCell({
    required this.day,
    required this.events,
    required this.type,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == _DayCellType.selected;
    final isToday = type == _DayCellType.today;
    final hasEvents = events.isNotEmpty;
    final isWeekend = day.weekday >= 6;

    final Color? cellBg;
    final Color dayColor;
    final FontWeight dayWeight;

    if (isSelected) {
      cellBg = colorScheme.primary;
      dayColor = colorScheme.onPrimary;
      dayWeight = FontWeight.w700;
    } else if (isToday) {
      cellBg = colorScheme.primaryContainer;
      dayColor = colorScheme.onPrimaryContainer;
      dayWeight = FontWeight.w700;
    } else if (hasEvents) {
      cellBg = colorScheme.primaryContainer.withValues(alpha: 0.22);
      dayColor = isWeekend ? colorScheme.error : colorScheme.onSurface;
      dayWeight = FontWeight.w600;
    } else {
      cellBg = null;
      dayColor = isWeekend
          ? colorScheme.error.withValues(alpha: 0.75)
          : colorScheme.onSurface;
      dayWeight = FontWeight.w400;
    }

    return Container(
      decoration: BoxDecoration(
        color: cellBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: dayWeight,
              color: dayColor,
              height: 1.1,
            ),
          ),
          if (hasEvents) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...events
                    .take(3)
                    .map(
                      (c) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.onPrimary.withValues(alpha: 0.75)
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
                            ? colorScheme.onPrimary.withValues(alpha: 0.65)
                            : colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final citas = state.citasForDay(state.selectedDay);
    final d = state.selectedDay;
    final dateLabel =
        '${_kWeekdays[d.weekday - 1]}, ${d.day} de ${_kMonthsShort[d.month - 1]} ${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      citas.isEmpty
                          ? 'Sin citas programadas'
                          : '${citas.length} cita${citas.length == 1 ? '' : 's'} agendada${citas.length == 1 ? '' : 's'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: citas.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (citas.isNotEmpty) _StatusLegend(colorScheme: colorScheme),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
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
  final ColorScheme colorScheme;
  const _StatusLegend({required this.colorScheme});

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
                  color: e.color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.name,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('¿Cancelar Cita?'),
            ],
          ),
          content: const Text(
            'Esta acción liberará el espacio en el calendario del odontólogo. ¿Desea continuar con la cancelación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Atrás',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              onPressed: () {
                // Dispara el evento en el Cubit global de la página
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = cita.estado.color;
    final hour = cita.date.hour.toString().padLeft(2, '0');
    final min = cita.date.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time badge
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hour,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    min,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor.withValues(alpha: 0.7),
                      height: 1.2,
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
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
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
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high_rounded,
                                size: 10,
                                color: Colors.red.shade700,
                              ),
                              Text(
                                'Urgente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
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
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cita.estado.name,
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
                  return PopupMenuItem<EstadoCita>(
                    value: e,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: e == cita.estado
                                ? FontWeight.bold
                                : FontWeight.normal,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 36,
              color: colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin citas este día',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona otro día para ver citas',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<CitaCubit>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Error al cargar citas',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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
