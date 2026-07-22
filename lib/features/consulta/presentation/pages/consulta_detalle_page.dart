import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/odontograma_tratamientos_detalle.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

/// Resumen clínico de solo lectura de una consulta cerrada: datos del paciente,
/// signos vitales, odontograma con tratamientos (y su precio congelado),
/// recetas, documentos, notas y el resumen económico de la consulta.
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
                if (consulta.signosVitales != null &&
                    !consulta.signosVitales!.estaVacia) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Signos vitales',
                    Icons.monitor_heart_rounded,
                    ac.red,
                    _widgetSignosVitales(context, consulta.signosVitales!),
                  ),
                ],
                if (consulta.tempCondiciones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Condiciones temporales',
                    Icons.warning_amber_rounded,
                    ac.amber,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cond in consulta.tempCondiciones)
                          _chipCondicion(context, cond),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _seccion(
                  context,
                  'Odontograma y tratamientos',
                  Icons.healing_rounded,
                  ac.teal,
                  OdontogramaTratamientosDetalle(consulta: consulta),
                ),
                if (consulta.tieneRecetas) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Receta',
                    Icons.receipt_long_rounded,
                    ac.primaryBlue,
                    BlocBuilder<ConsultaDetalleCubit, ConsultaDetalleState>(
                      builder: (context, state) => Column(
                        children: [
                          for (var i = 0; i < consulta.recetas.length; i++)
                            _tarjetaReceta(
                              context,
                              consulta.recetas[i],
                              state is ConsultaDetalleListo
                                  ? state.nombreMedicina(
                                      consulta.recetas[i].medicinaId,
                                    )
                                  : 'Medicamento',
                              esUltima: i == consulta.recetas.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (consulta.documentosClinicos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Documentos clínicos',
                    Icons.folder_open_rounded,
                    ac.indigo,
                    Column(
                      children: [
                        for (final doc in consulta.documentosClinicos)
                          _filaDocumento(context, doc),
                      ],
                    ),
                  ),
                ],
                if ((consulta.notas ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Notas clínicas',
                    Icons.notes_rounded,
                    ac.purple,
                    Text(
                      consulta.notas!.trim(),
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _resumenFinanciero(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Datos generales
  // ---------------------------------------------------------------------------

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ac.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  color: ac.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombrePaciente,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fechaLargaEs(consulta.fecha),
                      style: TextStyle(color: ac.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: ac.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _fila(context, 'Doctor', nombreDoctor)),
              Expanded(
                child: _fila(
                  context,
                  'Facturación',
                  consulta.tienePreFactura ? 'Facturada' : 'Sin facturar',
                ),
              ),
            ],
          ),
          if ((consulta.motivoConsulta ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _fila(
              context,
              'Motivo de consulta',
              consulta.motivoConsulta!.trim(),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                context,
                icon: Icons.healing_rounded,
                label: consulta.tieneTratamientosAplicados
                    ? 'Con tratamientos'
                    : 'Sin tratamientos',
                color: ac.teal,
                activo: consulta.tieneTratamientosAplicados,
              ),
              _badge(
                context,
                icon: Icons.receipt_long_rounded,
                label: consulta.tieneRecetas
                    ? '${consulta.recetas.length} '
                          '${consulta.recetas.length == 1 ? 'receta' : 'recetas'}'
                    : 'Sin recetas',
                color: ac.primaryBlue,
                activo: consulta.tieneRecetas,
              ),
              _badge(
                context,
                icon: Icons.folder_open_rounded,
                label: consulta.documentosClinicos.isNotEmpty
                    ? '${consulta.documentosClinicos.length} '
                          '${consulta.documentosClinicos.length == 1 ? 'documento' : 'documentos'}'
                    : 'Sin documentos',
                color: ac.indigo,
                activo: consulta.documentosClinicos.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Signos vitales
  // ---------------------------------------------------------------------------

  Widget _widgetSignosVitales(BuildContext context, SignosVitales sv) {
    final tiles = <Widget>[];

    final ps = sv.presionSistolica;
    final pd = sv.presionDiastolica;
    if (ps != null && pd != null) {
      tiles.add(_tileSigno(context, 'Presión arterial', '$ps/$pd', 'mmHg'));
    } else if (ps != null) {
      tiles.add(_tileSigno(context, 'Presión sistólica', '$ps', 'mmHg'));
    } else if (pd != null) {
      tiles.add(_tileSigno(context, 'Presión diastólica', '$pd', 'mmHg'));
    }
    if (sv.pulso != null) {
      tiles.add(_tileSigno(context, 'Pulso', '${sv.pulso}', 'lpm'));
    }
    if (sv.temperatura != null) {
      tiles.add(_tileSigno(context, 'Temperatura', '${sv.temperatura}', '°C'));
    }
    if (sv.saturacionO2 != null) {
      tiles.add(
        _tileSigno(context, 'Saturación O₂', '${sv.saturacionO2}', '%'),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }

  Widget _tileSigno(
    BuildContext context,
    String label,
    String valor,
    String unidad,
  ) {
    final ac = context.appColors;
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ac.textMuted,
              letterSpacing: 0.6,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  valor,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  unidad,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ac.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Receta
  // ---------------------------------------------------------------------------

  Widget _tarjetaReceta(
    BuildContext context,
    Receta receta,
    String nombreMedicina, {
    required bool esUltima,
  }) {
    final ac = context.appColors;
    return Container(
      margin: EdgeInsets.only(bottom: esUltima ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_rounded, size: 18, color: ac.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombreMedicina,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (receta.title.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                receta.title.trim(),
                style: TextStyle(color: ac.textMuted, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pildoraReceta(context, 'Dosis', receta.dosis),
              _pildoraReceta(context, 'Frecuencia', receta.frecuencia),
              _pildoraReceta(context, 'Duración', receta.duracion),
            ],
          ),
          if (receta.indicaciones.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              receta.indicaciones.trim(),
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pildoraReceta(BuildContext context, String label, String valor) {
    final ac = context.appColors;
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ac.divider),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: ac.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: valor.trim(),
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Documentos
  // ---------------------------------------------------------------------------

  Widget _filaDocumento(BuildContext context, DocumentoClinico doc) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ac.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            _iconoDocumento(doc.tipoDocumento.name),
            color: ac.indigo,
            size: 19,
          ),
        ),
        title: Text(
          doc.descripcion,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _etiquetaTipoDoc(doc.tipoDocumento.name),
          style: TextStyle(color: ac.textMuted, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Copiar enlace del documento',
          icon: Icon(Icons.link_rounded, size: 18, color: ac.primaryBlue),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: doc.urlArchivo));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Enlace copiado.')));
          },
        ),
      ),
    );
  }

  IconData _iconoDocumento(String tipo) {
    switch (tipo) {
      case 'imagen':
        return Icons.image_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'radiografia':
        return Icons.medical_information_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _etiquetaTipoDoc(String tipo) {
    switch (tipo) {
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'radiografia':
        return 'Radiografía';
      default:
        return tipo;
    }
  }

  // ---------------------------------------------------------------------------
  // Resumen financiero
  // ---------------------------------------------------------------------------

  Widget _resumenFinanciero(BuildContext context) {
    final ac = context.appColors;
    return BlocBuilder<ConsultaDetalleCubit, ConsultaDetalleState>(
      builder: (context, state) {
        double total = 0;
        var cargando = state is! ConsultaDetalleListo;
        if (state is ConsultaDetalleListo) {
          for (final detalle in state.tratamientos.values) {
            total += detalle.precio ?? 0;
          }
        }

        final facturada = consulta.tienePreFactura;
        final estadoColor = facturada ? ac.green : ac.amber;

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
              _tituloSeccion(
                context,
                'Resumen económico',
                Icons.payments_rounded,
                ac.green,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTO TOTAL DE LA CONSULTA',
                          style: TextStyle(
                            color: ac.textMuted,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        cargando
                            ? SizedBox(
                                height: 30,
                                width: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ac.textMuted,
                                  ),
                                ),
                              )
                            : Text(
                                formatMoneda(total),
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          facturada
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 15,
                          color: estadoColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          facturada ? 'Facturada' : 'Sin facturar',
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total calculado sobre los precios congelados de los '
                'tratamientos aplicados en esta consulta.',
                style: TextStyle(
                  color: ac.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de layout comunes
  // ---------------------------------------------------------------------------

  Widget _seccion(
    BuildContext context,
    String titulo,
    IconData icono,
    Color colorIcono,
    Widget child,
  ) {
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
          _tituloSeccion(context, titulo, icono, colorIcono),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _tituloSeccion(
    BuildContext context,
    String titulo,
    IconData icono,
    Color colorIcono,
  ) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colorIcono.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icono, size: 17, color: colorIcono),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipCondicion(BuildContext context, String texto) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ac.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: ac.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
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
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
