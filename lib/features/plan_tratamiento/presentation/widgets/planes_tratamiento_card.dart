import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/planes_paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/estado_plan_estilos.dart';

/// Tarjeta del expediente con la vista longitudinal del plan: todos los planes
/// del paciente y, arriba, lo que quedó aceptado sin ejecutar.
///
/// Responde de un vistazo a «¿qué le falta a este paciente?», que antes de
/// SD-135 no se podía preguntar: una intención era indistinguible de algo hecho.
class PlanesTratamientoCard extends StatelessWidget {
  final String pacienteId;

  const PlanesTratamientoCard({super.key, required this.pacienteId});

  static bool _esUuid(String id) => id.length == 36 && id.contains('-');

  @override
  Widget build(BuildContext context) {
    // Un paciente de prueba no tiene expediente en la base; la tarjeta se
    // omite en vez de mostrar un error de red.
    if (!_esUuid(pacienteId)) return const SizedBox.shrink();

    return BlocProvider<PlanesPacienteCubit>(
      create: (_) =>
          PlanesPacienteCubit(repository: sl(), pacienteId: pacienteId)
            ..cargar(),
      child: const _PlanesView(),
    );
  }
}

class _PlanesView extends StatelessWidget {
  const _PlanesView();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocBuilder<PlanesPacienteCubit, PlanesPacienteState>(
      builder: (context, state) {
        if (state is PlanesPacienteCargando ||
            state is PlanesPacienteInicial) {
          return _Shell(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ac.primaryBlue,
                  ),
                ),
              ),
            ),
          );
        }

        if (state is PlanesPacienteError) {
          return _Shell(
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: ac.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.mensaje,
                    style: TextStyle(fontSize: 12, color: ac.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<PlanesPacienteCubit>().cargar(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final cargado = state as PlanesPacienteCargado;
        if (cargado.planes.isEmpty) {
          return _Shell(
            child: Text(
              'Este paciente no tiene planes de tratamiento registrados.',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            ),
          );
        }

        return _Shell(
          conteo: cargado.planes.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cargado.pendientesDeEjecutar.isNotEmpty) ...[
                _BandejaPendientes(
                  items: cargado.pendientesDeEjecutar,
                  total: cargado.totalPendiente,
                ),
                const SizedBox(height: 16),
              ],
              for (var i = 0; i < cargado.planes.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: ac.divider.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                ],
                _BloquePlan(plan: cargado.planes[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Lo aceptado y sin cerrar. Es lo único de esta tarjeta que exige una acción.
class _BandejaPendientes extends StatelessWidget {
  final List<ItemPlanTratamiento> items;
  final double total;

  const _BandejaPendientes({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ac.primaryBlue.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions_rounded, size: 15, color: ac.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aceptado y pendiente de ejecutar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ac.primaryBlue,
                  ),
                ),
              ),
              Text(
                formatMoneda(total),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ac.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) _FilaItem(item: item, compacta: true),
        ],
      ),
    );
  }
}

class _BloquePlan extends StatelessWidget {
  final PlanTratamiento plan;

  const _BloquePlan({required this.plan});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final estilo = estiloPlan(plan.estado, ac);
    final fecha = plan.fechaPropuesta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Plan del ${fecha.day}/${fecha.month}/${fecha.year}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ac.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            ChipEstado(
              texto: plan.estado.etiqueta,
              color: estilo.color,
              icono: estilo.icono,
            ),
            const Spacer(),
            Text(
              formatMoneda(plan.totalEstimado),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ac.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in plan.items) _FilaItem(item: item),
        if (plan.items.isEmpty)
          Text(
            'Sin actividades.',
            style: TextStyle(fontSize: 11, color: ac.textMuted),
          ),
      ],
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ItemPlanTratamiento item;
  final bool compacta;

  const _FilaItem({required this.item, this.compacta = false});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final estilo = estiloItemPlan(item.estado, ac);
    final nombre = item.nombreTratamiento ?? 'Tratamiento';
    final cara = item.superficie?.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(estilo.icono, size: 12, color: estilo.color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              cara == null ? nombre : '$nombre · $cara',
              style: TextStyle(fontSize: 11, color: ac.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compacta) ...[
            Text(
              formatMoneda(item.precioEstimado),
              style: TextStyle(fontSize: 10, color: ac.textMuted),
            ),
            const SizedBox(width: 8),
          ],
          ChipEstado(
            texto: item.estado.etiqueta,
            color: estilo.color,
            icono: estilo.icono,
          ),
        ],
      ),
    );
  }
}

/// Misma anatomía que el resto de tarjetas del expediente.
class _Shell extends StatelessWidget {
  final Widget child;
  final int? conteo;

  const _Shell({required this.child, this.conteo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [ac.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ac.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    size: 18,
                    color: ac.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Planes de tratamiento',
                    // El título cede antes que el contador: en 320 px no cabe
                    // entero junto al icono y la tarjeta desbordaba.
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
                if (conteo != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ac.primaryBlue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$conteo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ac.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
