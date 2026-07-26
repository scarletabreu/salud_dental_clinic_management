import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/resumen_plan_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/resumen_plan_state.dart';

/// Vista de solo lectura del estado financiero de un plan de tratamiento (o de
/// todos los planes de un paciente): qué se presupuestó, ejecutó, facturó,
/// pagó y queda pendiente, por actividad.
///
/// No se puede ejecutar ni cambiar estados desde aquí — eso ocurre en el
/// workspace de la consulta. Esta pantalla es el reflejo, no la acción.
class ResumenPlanPage extends StatelessWidget {
  final String? planId;
  final String? pacienteId;
  final String? tituloPaciente;

  const ResumenPlanPage._({this.planId, this.pacienteId, this.tituloPaciente});

  factory ResumenPlanPage.porPlan(String planId, {String? tituloPaciente}) =>
      ResumenPlanPage._(planId: planId, tituloPaciente: tituloPaciente);

  factory ResumenPlanPage.porPaciente(
    String pacienteId, {
    String? tituloPaciente,
  }) => ResumenPlanPage._(
    pacienteId: pacienteId,
    tituloPaciente: tituloPaciente,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ResumenPlanCubit>();
        if (planId != null) {
          cubit.cargarPorPlan(planId!);
        } else if (pacienteId != null) {
          cubit.cargarPorPaciente(pacienteId!);
        }
        return cubit;
      },
      child: _ResumenPlanView(tituloPaciente: tituloPaciente),
    );
  }
}

class _ResumenPlanView extends StatelessWidget {
  const _ResumenPlanView({this.tituloPaciente});
  final String? tituloPaciente;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        backgroundColor: ac.cardBg,
        elevation: 0,
        title: Text(
          tituloPaciente == null
              ? 'Resumen del plan de tratamiento'
              : 'Plan de tratamiento · $tituloPaciente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ac.textPrimary,
          ),
        ),
      ),
      body: BlocBuilder<ResumenPlanCubit, ResumenPlanState>(
        builder: (context, state) {
          if (state is ResumenPlanCargando) {
            return Center(
              child: CircularProgressIndicator(color: ac.primaryBlue),
            );
          }
          if (state is ResumenPlanError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 40, color: ac.red),
                    const SizedBox(height: 12),
                    Text(
                      state.mensaje,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ac.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final cargado = state as ResumenPlanCargado;
          if (cargado.actividades.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Este plan todavía no tiene actividades con movimiento '
                  'financiero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _TotalesCard(cargado: cargado, ac: ac),
              const SizedBox(height: 20),
              Text(
                'Por actividad',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ac.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              for (final actividad in cargado.actividades)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActividadCard(actividad: actividad, ac: ac),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalesCard extends StatelessWidget {
  const _TotalesCard({required this.cargado, required this.ac});
  final ResumenPlanCargado cargado;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider.withValues(alpha: 0.5)),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Totales del plan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Totalito(
                'Presupuestado',
                cargado.totalPresupuestado,
                ac.textSecondary,
                ac,
              ),
              _Totalito('Facturado', cargado.totalFacturado, ac.primaryBlue, ac),
              _Totalito('Pagado', cargado.totalPagado, ac.green, ac),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Totalito('Realizado', cargado.totalRealizado, ac.indigo, ac),
              _Totalito('Pendiente', cargado.totalPendiente, ac.red, ac),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Totalito extends StatelessWidget {
  const _Totalito(this.etiqueta, this.monto, this.color, this.ac);
  final String etiqueta;
  final double monto;
  final Color color;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 10, color: ac.textMuted)),
          const SizedBox(height: 2),
          Text(
            formatMoneda(monto),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActividadCard extends StatelessWidget {
  const _ActividadCard({required this.actividad, required this.ac});
  final ResumenActividadPlan actividad;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final progreso = actividad.progresoSesiones;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  actividad.tratamientoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: ac.chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actividad.tipoEjecucion == TipoEjecucionItemPlan.porSesiones
                      ? 'Por sesiones'
                      : 'Única',
                  style: TextStyle(fontSize: 10, color: ac.textSecondary),
                ),
              ),
            ],
          ),
          if (progreso != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: ac.divider,
                color: ac.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${actividad.cantidadRealizada.toStringAsFixed(0)}'
              '${actividad.sesionesPlanificadas != null ? ' / ${actividad.sesionesPlanificadas}' : ''} sesiones',
              style: TextStyle(fontSize: 10, color: ac.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Cifra('Presupuestado', actividad.montoPresupuestado, ac),
              _Cifra('Facturado', actividad.montoFacturado, ac),
              _Cifra('Pagado', actividad.montoPagado, ac),
              _Cifra(
                'Pendiente',
                actividad.montoPendiente,
                ac,
                destacar: actividad.montoPendiente > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.etiqueta, this.monto, this.ac, {this.destacar = false});
  final String etiqueta;
  final double monto;
  final AppColors ac;
  final bool destacar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 9, color: ac.textMuted)),
        Text(
          formatMoneda(monto),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: destacar ? ac.red : ac.textSecondary,
          ),
        ),
      ],
    );
  }
}