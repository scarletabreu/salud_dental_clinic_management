import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/efectuar_consulta_page.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';

/// Valor centinela para iniciar el flujo clínico unificado.
const _kEfectuarConsulta = 'efectuar_consulta';
const _kAbrirConsulta = 'abrir_consulta';

const _kHourStart = 8;
const _kHourEnd = 20;
const _kHourHeight = 64.0;
const _kHeaderHeight = 60.0;
const _kTimeAxisWidth = 52.0;

// ─────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────

class WeekTimelineView extends StatelessWidget {
  final List<Cita> citas;
  final DateTime weekStart;

  const WeekTimelineView({
    super.key,
    required this.citas,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return _TimelineScaffold(days: days, citas: citas);
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
    final ac = context.appColors;

    // El alto de cada franja lo fija el reloj, no la tipografía: por encima de
    // 1.3 el texto dejaría de caber en su hueco, así que se acota aquí en vez
    // de recortar el contenido.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.all(context.appLayout.isCompact ? 8 : 20),
        child: Container(
          decoration: BoxDecoration(
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [ac.cardShadow],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = days.length == 1
                  ? (constraints.maxWidth - _kTimeAxisWidth)
                  : (constraints.maxWidth - _kTimeAxisWidth) / days.length;

              return Column(
                children: [
                  _DayHeaders(days: days, columnWidth: columnWidth),
                  Divider(height: 1, color: ac.divider),
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
          ),
        ),
      ),
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
    final ac = context.appColors;
    final today = DateTime.now();

    return SizedBox(
      height: _kHeaderHeight,
      child: Row(
        children: [
          SizedBox(width: _kTimeAxisWidth),
          ...days.map((day) {
            final isToday =
                day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            final isWeekend = day.weekday >= 6;
            // En una semana de 320 px cada columna baja de 40 px: el círculo
            // del día se encoge para no romper la cabecera.
            final diametro = columnWidth < 40 ? 28.0 : 36.0;
            return SizedBox(
              width: columnWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _kDayLabels[day.weekday - 1],
                    // Con la columna estrecha la etiqueta se partía en dos
                    // líneas y reventaba el alto fijo de la cabecera.
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isToday
                          ? ac.primaryGreen
                          : isWeekend
                          ? ac.red.withValues(alpha: 0.7)
                          : ac.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: diametro,
                    height: diametro,
                    decoration: BoxDecoration(
                      color: isToday ? ac.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? Colors.white
                            : isWeekend
                            ? ac.red.withValues(alpha: 0.7)
                            : ac.textPrimary,
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
    final ac = context.appColors;

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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ac.textDisabled,
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
// Columna de un día
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
    final ac = context.appColors;
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    final totalHeight = (_kHourEnd - _kHourStart) * _kHourHeight;

    double? nowLine;
    if (isToday) {
      final diffMin = (now.hour - _kHourStart) * 60 + now.minute;
      final pct = diffMin / ((_kHourEnd - _kHourStart) * 60);
      if (pct >= 0 && pct <= 1) {
        nowLine = pct * totalHeight;
      }
    }

    final lanes = _assignLanes(citas);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ac.divider, width: 1),
          right: isLast
              ? BorderSide(color: ac.divider, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(_kHourEnd - _kHourStart, (i) {
            return Positioned(
              top: i * _kHourHeight,
              left: 0,
              right: 0,
              child: Divider(height: 1, color: ac.divider),
            );
          }),
          ...List.generate(_kHourEnd - _kHourStart, (i) {
            return Positioned(
              top: i * _kHourHeight + _kHourHeight / 2,
              left: 8,
              right: 0,
              child: Container(height: 1, color: ac.rowDivider),
            );
          }),
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
                    decoration: BoxDecoration(
                      color: ac.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: ac.primaryGreen)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Map<String, Map<String, int>> _assignLanes(List<Cita> citas) {
    final sorted = [...citas]..sort((a, b) => a.date.compareTo(b.date));
    final List<List<Cita>> groups = [];
    for (final cita in sorted) {
      bool placed = false;
      for (final group in groups) {
        final overlaps = group.any(
          (c) =>
              c.date.isBefore(cita.fechaFin) && cita.date.isBefore(c.fechaFin),
        );
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
    return h.clamp(26.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final top = _topOffset();
    final height = _blockHeight();
    final color = cita.estado.color;

    return Positioned(
      top: top + 1,
      left: left,
      width: width,
      height: height - 2,
      child: _CitaBlock(cita: cita, color: color, height: height - 2),
    );
  }
}

class _CitaBlock extends StatelessWidget {
  final Cita cita;
  final Color color;
  final double height;

  const _CitaBlock({
    required this.cita,
    required this.color,
    required this.height,
  });

  void _showStatusMenu(BuildContext context) {
    final ac = context.appColors;
    final cubit = context.read<CitaCubit>();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    final pacienteId = cita.persona.id;
    final doctorId = cita.doctor.id;
    // Solo se efectúan citas en espera; al efectuarse pasan a EN_CONSULTA.
    final esEfectuable = cita.estado == EstadoCita.enEspera;
    final puedeEfectuar =
        esEfectuable &&
        pacienteId != null &&
        doctorId != null &&
        cita.id != null;

    // Enlace hacia la consulta que esta cita ya originó (SD-160): sin él, desde
    // la agenda no había forma de llegar al acto clínico que le corresponde.
    final estado = cubit.state;
    final consulta = estado is CitaCubitLoaded ? estado.consultaDe(cita) : null;
    final puedeAbrirConsulta =
        consulta != null && pacienteId != null && doctorId != null;

    showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        if (puedeAbrirConsulta) ...[
          PopupMenuItem<Object>(
            value: _kAbrirConsulta,
            child: Row(
              children: [
                Icon(
                  consulta.estaAbierta
                      ? Icons.play_circle_outline_rounded
                      : Icons.assignment_turned_in_outlined,
                  size: 16,
                  color: consulta.estaAbierta ? ac.amber : ac.indigo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    consulta.estaAbierta
                        ? 'Continuar consulta'
                        : 'Ver consulta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        if (puedeEfectuar) ...[
          PopupMenuItem<Object>(
            value: _kEfectuarConsulta,
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: ac.primaryGreen,
                ),
                const SizedBox(width: 10),
                Expanded(child: _AccionClinicaMenu(color: ac.primaryGreen)),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        ...cita.estado.transicionesPermitidas.map((e) {
          return PopupMenuItem<Object>(
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
        }),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == _kAbrirConsulta && consulta != null) {
        // Abierta: se reanuda donde quedó. Finalizada: se abre en modo lectura
        // desde la misma pantalla, que ya distingue ambos casos por `finalizada`.
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => EfectuarConsultaPage(
                  citaId: cita.id,
                  pacienteId: pacienteId!,
                  doctorId: doctorId!,
                  consultaId: consulta.id,
                  motivoCita: cita.motivo,
                ),
              ),
            )
            .then((_) => cubit.load());
        return;
      }
      if (value == _kEfectuarConsulta) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => EfectuarConsultaPage(
                  citaId: cita.id!,
                  pacienteId: pacienteId!,
                  doctorId: doctorId!,
                  motivoCita: cita.motivo,
                ),
              ),
            )
            // Al volver, la cita pudo quedar completada.
            .then((_) => cubit.load());
        return;
      }
      if (value is! EstadoCita || value == cita.estado) return;
      if (value == EstadoCita.cancelada) {
        _showCancelDialog(context, cubit);
      } else {
        cubit.cambiarEstadoCita(cita.id!, value);
      }
    });
  }

  void _showCancelDialog(BuildContext context, CitaCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final ac = dialogCtx.appColors;
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
            'Esta acción liberará el espacio en el calendario del odontólogo. ¿Desea continuar?',
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
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
                cubit.cambiarEstadoCita(cita.id!, EstadoCita.cancelada);
                Navigator.pop(dialogCtx);
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
    final ac = context.appColors;
    final startH = cita.date.hour.toString().padLeft(2, '0');
    final startM = cita.date.minute.toString().padLeft(2, '0');
    final endH = cita.fechaFin.hour.toString().padLeft(2, '0');
    final endM = cita.fechaFin.minute.toString().padLeft(2, '0');
    final timeRange = '$startH:$startM – $endH:$endM';

    final isCompact = height < 44;
    final isFull = height >= 56;

    final nombreRow = LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Text(
              cita.persona.fullName,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: ac.textPrimary,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Por debajo de 28 px el bloque no da ni para el nombre: el aviso
          // de emergencia se apoya en el color del borde.
          if (cita.esEmergencia && constraints.maxWidth >= 28)
            Icon(Icons.priority_high_rounded, size: 10, color: ac.red),
        ],
      ),
    );

    final horaText = Text(
      timeRange,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1,
      ),
      overflow: TextOverflow.ellipsis,
    );

    final Widget content;
    if (isCompact) {
      content = nombreRow;
    } else if (!isFull) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [nombreRow, const SizedBox(height: 2), horaText],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nombreRow,
          const SizedBox(height: 3),
          Text(
            'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
            style: TextStyle(fontSize: 10, color: ac.textMuted, height: 1.1),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          horaText,
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showStatusMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [ac.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3, color: color),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, isCompact ? 3 : 6, 6, 4),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionClinicaMenu extends StatelessWidget {
  const _AccionClinicaMenu({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Iniciar consulta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          'Diagnostica, planifica y registra tratamientos sin salir.',
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
