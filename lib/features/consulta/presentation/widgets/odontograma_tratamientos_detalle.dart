import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';

/// Odontograma read-only de la consulta y el desglose de tratamientos por
/// diente (nombre + precio congelado, cargados por [ConsultaDetalleCubit]).
class OdontogramaTratamientosDetalle extends StatelessWidget {
  final Consulta consulta;

  const OdontogramaTratamientosDetalle({super.key, required this.consulta});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final odontograma = consulta.odontograma;

    if (odontograma == null || odontograma.dientes.isEmpty) {
      return Text(
        'Esta consulta no tiene odontograma registrado.',
        style: TextStyle(color: ac.textMuted, fontSize: 13),
      );
    }

    final dientesConTratamientos =
        odontograma.dientes
            .where((d) => d.tratamientosAplicadosIds.isNotEmpty)
            .toList()
          ..sort((a, b) => a.fdiCode.compareTo(b.fdiCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OdontogramWidget(odontograma: odontograma),
        const SizedBox(height: 16),
        if (dientesConTratamientos.isEmpty)
          Text(
            'No se registraron tratamientos en esta consulta.',
            style: TextStyle(color: ac.textMuted, fontSize: 13),
          )
        else
          BlocBuilder<ConsultaDetalleCubit, ConsultaDetalleState>(
            builder: (context, state) {
              if (state is! ConsultaDetalleListo) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final diente in dientesConTratamientos)
                    _filaDiente(context, diente, state),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _filaDiente(
    BuildContext context,
    Diente diente,
    ConsultaDetalleListo state,
  ) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: ac.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${diente.fdiCode}',
              style: TextStyle(
                color: ac.teal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in diente.tratamientosAplicadosIds)
                  _filaTratamiento(context, id, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTratamiento(
    BuildContext context,
    String id,
    ConsultaDetalleListo state,
  ) {
    final ac = context.appColors;
    final detalle = state.detalleDe(id);
    final nombre = detalle?.nombre ?? 'Tratamiento';
    final superficie = detalle?.tratamiento.superficie?.name;
    final precio = detalle?.precio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.healing_rounded, size: 15, color: ac.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (superficie != null)
                  Text(
                    'Superficie $superficie',
                    style: TextStyle(color: ac.textMuted, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            precio != null ? formatMoneda(precio) : '—',
            style: TextStyle(
              color: precio != null ? ac.textSecondary : ac.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
