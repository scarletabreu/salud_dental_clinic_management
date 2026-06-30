import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../presentation/widgets/nueva_cita_dialog.dart';
import '../cubit/cita_cubit.dart';
import '../cubit/cita_cubit_state.dart';
import '../widgets/timeline_view.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/cita_edit_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/efectuar_consulta_page.dart';

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

const _kWeekdaysShort = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

class MisCitasDelDiaPage extends StatelessWidget {
  const MisCitasDelDiaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.bgPage,
      body: BlocListener<CitaCubit, CitaCubitState>(
        listener: (context, state) {
          if (state is CitaCubitLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: ac.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: BlocBuilder<CitaCubit, CitaCubitState>(builder: _buildState),
      ),
      floatingActionButton: BlocBuilder<CitaCubit, CitaCubitState>(
        builder: (context, state) {
          if (state is! CitaCubitLoaded) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'fab_nueva_cita_unique_tag',
            backgroundColor: context.appColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            onPressed: () async {
              await NuevaCitaDialog.show(
                context,
                personaRepository: sl<PersonaRepository>(),
                doctorRepository: sl<DoctorRepository>(),
              );
              context.read<CitaCubit>().load();
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Nueva Cita',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildState(BuildContext context, CitaCubitState state) {
    if (state is CitaCubitLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.appColors.primaryBlue,
          strokeWidth: 2,
        ),
      );
    }
    if (state is CitaCubitError) return _ErrorView(message: state.message);
    if (state is CitaCubitLoaded) return _CalendarioView(state: state);
    return const SizedBox.shrink();
  }
}

class _CalendarioView extends StatelessWidget {
  final CitaCubitLoaded state;
  const _CalendarioView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlBar(state: state),
          const SizedBox(height: 12),
          Expanded(child: _CalendarioBody(state: state)),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final CitaCubitLoaded state;
  const _ControlBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final cubit = context.read<CitaCubit>();

    final citasHoy = state.citasForDay(state.selectedDay);
    final urgentes = citasHoy.where((c) => c.esEmergencia).length;
    final pendientes = citasHoy
        .where((c) => c.estado == EstadoCita.programada)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Citas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ac.textPrimary,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ac.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavIconBtn(
                    icon: Icons.chevron_left,
                    onTap: cubit.goPrevious,
                  ),
                  const SizedBox(width: 4),
                  _TodayButton(onTap: cubit.goToToday),
                  const SizedBox(width: 4),
                  _NavIconBtn(icon: Icons.chevron_right, onTap: cubit.goToNext),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ViewModePill(
                selected: state.viewMode,
                onChanged: cubit.changeViewMode,
              ),
              const Spacer(),
              if (state.viewMode == CalendarioViewMode.diaria &&
                  citasHoy.isNotEmpty) ...[
                _SummaryChip(
                  icon: Icons.calendar_today_rounded,
                  label: '${citasHoy.length} citas',
                  color: ac.primaryBlue,
                ),
                if (urgentes > 0) ...[
                  const SizedBox(width: 6),
                  _SummaryChip(
                    icon: Icons.priority_high_rounded,
                    label: '$urgentes urgente${urgentes > 1 ? 's' : ''}',
                    color: ac.red,
                  ),
                ],
                if (pendientes > 0) ...[
                  const SizedBox(width: 6),
                  _SummaryChip(
                    icon: Icons.hourglass_empty_rounded,
                    label: '$pendientes pendiente${pendientes > 1 ? 's' : ''}',
                    color: ac.amber,
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _currentLabel() {
    if (state.viewMode == CalendarioViewMode.diaria) {
      final d = state.selectedDay;
      return '${_kWeekdays[d.weekday - 1]}, '
          '${d.day} de ${_kMonths[d.month - 1]} ${d.year}';
    }
    if (state.viewMode == CalendarioViewMode.semanal) {
      final weekStart = _weekStartFor(state.focusedDay);
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (weekStart.month == weekEnd.month) {
        return '${weekStart.day} – ${weekEnd.day} '
            'de ${_kMonths[weekStart.month - 1]} ${weekStart.year}';
      }
      return '${weekStart.day} ${_kMonthsShort[weekStart.month - 1]} '
          '– ${weekEnd.day} ${_kMonthsShort[weekEnd.month - 1]} '
          '${weekStart.year}';
    }
    return '${_kMonths[state.focusedDay.month - 1]} ${state.focusedDay.year}';
  }

  static DateTime _weekStartFor(DateTime day) =>
      day.subtract(Duration(days: day.weekday - 1));
}

class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ac.chipBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: ac.textSecondary),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ac.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ac.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Hoy',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ac.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarioBody extends StatelessWidget {
  final CitaCubitLoaded state;
  const _CalendarioBody({required this.state});

  static DateTime _weekStartFor(DateTime day) =>
      day.subtract(Duration(days: day.weekday - 1));

  @override
  Widget build(BuildContext context) {
    if (state.viewMode == CalendarioViewMode.diaria) {
      return BlocProvider.value(
        value: context.read<CitaCubit>(),
        child: DayTimelineView(
          citas: state.citasForDay(state.selectedDay),
          day: state.selectedDay,
        ),
      );
    }

    if (state.viewMode == CalendarioViewMode.semanal) {
      final weekStart = _weekStartFor(state.focusedDay);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekCitas = state.citas.where((c) {
        final d = c.date;
        return !d.isBefore(
              DateTime(weekStart.year, weekStart.month, weekStart.day),
            ) &&
            !d.isAfter(
              DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
            );
      }).toList();

      return BlocProvider.value(
        value: context.read<CitaCubit>(),
        child: WeekTimelineView(citas: weekCitas, weekStart: weekStart),
      );
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
                child: _CalendarSection(state: state, fillHeight: true),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 45, child: _DetailPanel(state: state)),
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              _CalendarSection(state: state),
              const SizedBox(height: 12),
              _DetailPanel(state: state, mobileMode: true),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarSection extends StatelessWidget {
  final CitaCubitLoaded state;
  final bool fillHeight;
  const _CalendarSection({required this.state, this.fillHeight = false});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final cubit = context.read<CitaCubit>();

    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [ac.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
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
    );
  }
}

class _DowCell extends StatelessWidget {
  final DateTime day;
  const _DowCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final label = _kWeekdaysShort[day.weekday - 1];
    final isWeekend = day.weekday >= 6;
    final isToday = day.weekday == DateTime.now().weekday;

    final textColor = isWeekend
        ? ac.red
        : isToday
        ? ac.primaryBlue
        : ac.textPrimary;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ac.cardBg,
        border: Border(
          bottom: BorderSide(
            color: isToday ? ac.primaryBlue.withValues(alpha: 0.3) : ac.divider,
            width: isToday ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 3),
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: ac.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _DayCellType { normal, today, selected }

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<Cita> events;
  final _DayCellType type;
  const _DayCell({required this.day, required this.events, required this.type});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final isSelected = type == _DayCellType.selected;
    final isToday = type == _DayCellType.today;
    final hasEvents = events.isNotEmpty;
    final isWeekend = day.weekday >= 6;
    final hasUrgent = events.any((c) => c.esEmergencia);

    final Color cellBg;
    final Color dayColor;
    final FontWeight dayWeight;

    if (isSelected) {
      cellBg = ac.primaryBlue;
      dayColor = Colors.white;
      dayWeight = FontWeight.w700;
    } else if (isToday) {
      cellBg = ac.primaryBlue.withValues(alpha: 0.12);
      dayColor = ac.primaryBlue;
      dayWeight = FontWeight.w700;
    } else {
      cellBg = Colors.transparent;
      dayColor = isWeekend ? ac.red.withValues(alpha: 0.7) : ac.textSecondary;
      dayWeight = hasEvents ? FontWeight.w600 : FontWeight.w400;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (hasUrgent && !isSelected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ac.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: ac.cardBg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          if (hasEvents) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                            : ac.textDisabled,
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
  final CitaCubitLoaded state;
  final bool mobileMode;
  const _DetailPanel({required this.state, this.mobileMode = false});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final citas = state.citasForDay(state.selectedDay);
    final d = state.selectedDay;

    final completadas = citas
        .where((c) => c.estado == EstadoCita.completada)
        .length;
    final enEspera = citas.where((c) => c.estado == EstadoCita.enEspera).length;
    final pendientes = citas
        .where((c) => c.estado == EstadoCita.programada)
        .length;

    final isToday = isSameDay(d, DateTime.now());
    final dayLabel = isToday ? 'Hoy' : _kWeekdays[d.weekday - 1];
    final dateLabel = '${d.day} de ${_kMonthsShort[d.month - 1]} ${d.year}';

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isToday ? ac.primaryBlue : ac.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ac.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ac.primaryBlue,
                              ),
                            ),
                          )
                        else
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: ac.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      citas.isEmpty
                          ? 'Sin citas programadas'
                          : '${citas.length} cita${citas.length == 1 ? '' : 's'} agendada${citas.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: citas.isEmpty ? ac.textMuted : ac.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (citas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (completadas > 0)
                  _StatusPill(
                    label:
                        '$completadas completada${completadas > 1 ? 's' : ''}',
                    color: ac.green,
                  ),
                if (enEspera > 0)
                  _StatusPill(label: '$enEspera en espera', color: ac.amber),
                if (pendientes > 0)
                  _StatusPill(
                    label: '$pendientes pendiente${pendientes > 1 ? 's' : ''}',
                    color: ac.indigo,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    final citasList = citas.isEmpty
        ? const _EmptyDay()
        : ListView.separated(
            shrinkWrap: mobileMode,
            physics: mobileMode
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: citas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _CitaCard(cita: citas[i]),
          );

    if (mobileMode) {
      return Container(
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ac.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [ac.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Divider(height: 1, thickness: 0.5, color: ac.divider),
            const SizedBox(height: 8),
            citasList,
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [ac.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Divider(height: 1, thickness: 0.5, color: ac.divider),
          Expanded(child: citasList),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
        final ac = dialogContext.appColors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: ac.red),
              const SizedBox(width: 8),
              Text(
                '¿Cancelar Cita?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Esta acción liberará el espacio en el calendario del odontólogo. '
            '¿Deseas continuar con la cancelación?',
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Atrás', style: TextStyle(color: ac.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ac.red,
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
              child: const Text('Confirmar cancelación'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final statusColor = cita.estado.color;
    final hour = cita.date.hour.toString().padLeft(2, '0');
    final min = cita.date.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [ac.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<CitaCubit>(),
                  child: CitaEditPage(cita: cita),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          hour,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          min,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor.withValues(alpha: 0.6),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: statusColor.withValues(alpha: 0.15),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cita.persona.fullName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ac.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cita.esEmergencia) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ac.red.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.priority_high_rounded,
                                        size: 10,
                                        color: ac.red,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Urgente',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: ac.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: ac.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ac.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EstadoDropdown(
                      cita: cita,
                      onCancelar: () =>
                          _mostrarDialogoCancelacion(context, cita.id!),
                    ),
                  ],
                ),
                _botonEfectuar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonEfectuar(BuildContext context) {
    final ac = context.appColors;
    final pacienteId = cita.persona.id;
    final doctorId = cita.doctor.id;
    final esEfectuable = cita.estado == EstadoCita.enEspera;
    if (!esEfectuable ||
        pacienteId == null ||
        doctorId == null ||
        cita.id == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: FilledButton.icon(
          onPressed: () async {
            final cubit = context.read<CitaCubit>();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EfectuarConsultaPage(
                  citaId: cita.id!,
                  pacienteId: pacienteId,
                  doctorId: doctorId,
                ),
              ),
            );
            cubit.load();
          },
          style: FilledButton.styleFrom(
            backgroundColor: ac.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.medical_services_outlined, size: 16),
          label: const Text('Efectuar Consulta'),
        ),
      ),
    );
  }
}

class _EstadoDropdown extends StatelessWidget {
  const _EstadoDropdown({required this.cita, required this.onCancelar});
  final Cita cita;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final statusColor = cita.estado.color;

    return PopupMenuButton<EstadoCita>(
      initialValue: cita.estado,
      tooltip: 'Cambiar estado',
      onSelected: (EstadoCita nuevoEstado) {
        if (nuevoEstado == cita.estado) return;
        if (nuevoEstado == EstadoCita.cancelada) {
          onCancelar();
        } else {
          context.read<CitaCubit>().cambiarEstadoCita(cita.id!, nuevoEstado);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        final ac = context.appColors;
        return cita.estado.transicionesPermitidas.map((e) {
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
                    fontWeight: FontWeight.w400,
                    color: ac.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ac.chipBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 28,
                color: ac.textDisabled,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sin citas este día',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ac.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona otro día o crea una nueva cita',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
            const SizedBox(height: 12),
            Text(
              'Error al cargar citas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: ac.textMuted),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ac.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: context.read<CitaCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModePill extends StatelessWidget {
  final CalendarioViewMode selected;
  final ValueChanged<CalendarioViewMode> onChanged;
  const _ViewModePill({required this.selected, required this.onChanged});

  static const _options = [
    (CalendarioViewMode.mensual, 'Mes'),
    (CalendarioViewMode.semanal, 'Semana'),
    (CalendarioViewMode.diaria, 'Día'),
  ];

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((opt) {
          final (mode, label) = opt;
          final isSelected = mode == selected;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? ac.cardBg : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected ? [ac.cardShadow] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? ac.textPrimary : ac.textMuted,
                  height: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
