import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/odontograma_tratamientos_detalle.dart';

/// Detalle de una consulta: datos generales, condiciones, notas, odontograma
/// con los tratamientos realizados y documentos clínicos. Recetas y
/// facturación siguen pendientes de sus propios tickets.
class ConsultaDetallePage extends StatelessWidget {
  final Consulta consulta;
  final String nombrePaciente;
  final String nombreDoctor;

  const ConsultaDetallePage({
    super.key,
    required this.consulta,
    required this.nombrePaciente,
    required this.nombreDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocProvider(
      create: (_) => sl<ConsultaDetalleCubit>()..cargar(consulta),
      child: Scaffold(
        backgroundColor: ac.bgPage,
        appBar: AppBar(
          title: const Text('Detalle de consulta'),
          backgroundColor: ac.cardBg,
          foregroundColor: ac.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _cardDatosGenerales(context),
                if (consulta.tempCondiciones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Condiciones temporales',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cond in consulta.tempCondiciones)
                          Chip(label: Text(cond)),
                      ],
                    ),
                  ),
                ],
                if ((consulta.notas ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Notas clínicas',
                    Text(
                      consulta.notas!.trim(),
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _seccion(
                  context,
                  'Odontograma y tratamientos',
                  OdontogramaTratamientosDetalle(consulta: consulta),
                ),
                if (consulta.documentosClinicos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Documentos clínicos',
                    Column(
                      children: [
                        for (final doc in consulta.documentosClinicos)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(
                              Icons.description_outlined,
                              color: ac.teal,
                            ),
                            title: Text(
                              doc.descripcion,
                              style: TextStyle(
                                color: ac.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              doc.tipoDocumento.name,
                              style: TextStyle(
                                color: ac.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Copiar enlace del documento',
                              icon: Icon(
                                Icons.link_rounded,
                                size: 18,
                                color: ac.primaryBlue,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: doc.urlArchivo),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enlace copiado.'),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _proximamente(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardDatosGenerales(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _fila(context, 'Fecha', fechaLargaEs(consulta.fecha)),
              ),
              _badge(
                context,
                icon: Icons.receipt_long_rounded,
                label: consulta.tieneRecetas
                    ? '${consulta.recetas.length} receta'
                          '${consulta.recetas.length == 1 ? '' : 's'}'
                    : 'Sin recetas',
                color: ac.primaryBlue,
                activo: consulta.tieneRecetas,
              ),
              const SizedBox(width: 8),
              _badge(
                context,
                icon: Icons.healing_rounded,
                label: consulta.tieneTratamientosAplicados
                    ? 'Con tratamientos'
                    : 'Sin tratamientos',
                color: ac.teal,
                activo: consulta.tieneTratamientosAplicados,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _fila(context, 'Paciente', nombrePaciente)),
              Expanded(child: _fila(context, 'Doctor', nombreDoctor)),
            ],
          ),
          if ((consulta.motivoConsulta ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _fila(context, 'Motivo', consulta.motivoConsulta!.trim()),
          ],
        ],
      ),
    );
  }

  Widget _seccion(BuildContext context, String titulo, Widget child) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _proximamente(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: ac.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Próximamente: recetas y facturación de la consulta.',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, String label, String valor) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: ac.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool activo,
  }) {
    final ac = context.appColors;
    final fg = activo ? color : ac.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
