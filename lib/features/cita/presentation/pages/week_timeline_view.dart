import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/nueva_cita_dialog.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

class WeekTimelineView extends StatelessWidget {
  final List<Cita> citas;
  final DateTime weekStart;

  const WeekTimelineView({
    super.key,
    required this.citas,
    required this.weekStart,
  });

  static const int startHour = 8;
  static const int endHour = 18;
  static const double rowHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      margin: const EdgeInsets.only(top: 8),
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
        children: [
          _buildWeekHeader(context),
          Divider(height: 1, thickness: 0.5, color: ac.divider),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeColumn(context),
                  VerticalDivider(width: 1, thickness: 0.5, color: ac.divider),

                  Expanded(
                    child: Row(
                      children: List.generate(7, (index) {
                        final currentDay = weekStart.add(Duration(days: index));
                        return Expanded(
                          child: _buildDayColumn(context, currentDay),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final ac = context.appColors;
    final List<String> shortDays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    return Row(
      children: [
        const SizedBox(width: 60, height: 45),
        ...List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isToday = DateUtils.isSameDay(day, DateTime.now());

          return Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isToday
                  ? ac.primaryBlue.withValues(alpha: 0.05)
                  : Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shortDays[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? ac.primaryBlue : ac.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isToday ? ac.primaryBlue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isToday ? Colors.white : ac.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeColumn(BuildContext context) {
    final ac = context.appColors;
    return SizedBox(
      width: 60,
      child: Column(
        children: List.generate(endHour - startHour, (index) {
          final hour = startHour + index;
          final label = '${hour.toString().padLeft(2, '0')}:00';
          return Container(
            height: rowHeight,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ac.textMuted,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, DateTime day) {
    final ac = context.appColors;

    final citasDelDia = citas
        .where((c) => DateUtils.isSameDay(c.date, day))
        .toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: ac.divider.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: List.generate(endHour - startHour, (index) {
              final hour = startHour + index;
              return GestureDetector(
                onTap: () => _onSlotTapped(context, day, hour),
                child: Container(
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: ac.divider.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          ...citasDelDia.map((cita) => _buildPositionedCitaCard(context, cita)),
        ],
      ),
    );
  }

  Widget _buildPositionedCitaCard(BuildContext context, Cita cita) {
    final ac = context.appColors;

    final double horaInicioDecimal = cita.date.hour + (cita.date.minute / 60.0);
    final double horaFinDecimal =
        cita.fechaFin.hour + (cita.fechaFin.minute / 60.0);

    if (horaInicioDecimal < startHour || horaInicioDecimal >= endHour) {
      return const SizedBox.shrink();
    }

    final double top = (horaInicioDecimal - startHour) * rowHeight;
    final double height = (horaFinDecimal - horaInicioDecimal) * rowHeight;

    return Positioned(
      top: top + 2,
      left: 2,
      right: 2,
      height: height - 4,
      child: Tooltip(
        message:
            'Paciente: ${cita.persona.fullName}\nDr. ${cita.doctor.nombre}',
        child: Container(
          decoration: BoxDecoration(
            color: cita.estado.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: cita.estado.color, width: 3),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                cita.persona.fullName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Expanded(
                child: Text(
                  '${cita.date.hour}:${cita.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: cita.estado.color,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSlotTapped(BuildContext context, DateTime day, int hour) async {
    final fechaPrellenada = DateTime(day.year, day.month, day.day, hour, 0);

    await NuevaCitaDialog.show(
      context,
      personaRepository: sl<PersonaRepository>(),
      doctorRepository: sl<DoctorRepository>(),
      pacienteRepository: sl<IPacienteRepository>(),
      fechaInicial: fechaPrellenada,
    );

    if (context.mounted) {
      context.read<CitaCubit>().load();
    }
  }
}
