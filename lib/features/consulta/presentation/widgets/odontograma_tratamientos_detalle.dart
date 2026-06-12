import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';

/// Odontograma read-only de la consulta y el desglose de tratamientos por
/// diente (nombres cargados por [ConsultaDetalleCubit]).
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

    final dientesConTratamientos = odontograma.dientes
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
      padding: const EdgeInsets.only(bottom: 8),
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
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in diente.tratamientosAplicadosIds)
                  Chip(
                    label: Text(state.nombreDe(id)),
                    avatar: Icon(
                      Icons.healing_rounded,
                      size: 14,
                      color: ac.teal,
                    ),
                    labelStyle: TextStyle(fontSize: 12, color: ac.textPrimary),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
