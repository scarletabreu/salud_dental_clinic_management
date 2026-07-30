import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/odontograma_tratamientos_detalle.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/repositories/receta_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/presentation/pages/receta_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/receta/presentation/pages/receta_page.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

class ConsultaDetallePage extends StatelessWidget {
  final Consulta consulta;
  final String nombrePaciente;
  final String nombreDoctor;
  final String? pacienteFotoUrl;

  const ConsultaDetallePage({
    super.key,
    required this.consulta,
    required this.nombrePaciente,
    required this.nombreDoctor,
    this.pacienteFotoUrl,
  });

  void _imprimirRecetaDirecta(
    BuildContext context,
    Receta receta, {
    String? fotoUrlFinal,
  }) {
    RecetaPage.navegar(
      context,
      receta: receta,
      nombrePaciente: nombrePaciente,
      doctorNombre: nombreDoctor,
      pacienteFotoUrl: fotoUrlFinal ?? pacienteFotoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ConsultaDetalleCubit>()..cargar(consulta),
        ),
        BlocProvider(
          create: (_) => sl<PacienteCubit>()..loadById(consulta.pacienteId),
        ),
      ],
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
                const SizedBox(height: 16),
                _seccionCitaOrigen(context),
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
                  OdontogramaTratamientosDetalle(
                    consulta: consulta,
                    nombrePaciente: nombrePaciente,
                  ),
                ),
                if (consulta.tieneRecetas) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    'Recetas Médicas Emitidas',
                    Icons.receipt_long_rounded,
                    ac.primaryGreen,
                    Column(
                      children: [
                        for (var i = 0; i < consulta.recetas.length; i++)
                          _tarjetaRecetaCompleta(
                            context,
                            consulta.recetas[i],
                            esUltima: i == consulta.recetas.length - 1,
                          ),
                      ],
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BlocBuilder<PacienteCubit, PacienteState>(
                builder: (context, state) {
                  String? fotoUrl;

                  if (state is PacienteDetailLoaded) {
                    fotoUrl = state.paciente.fotoUrl ?? state.paciente.fotoRuta;
                  } else if (state is PacienteLoaded) {
                    for (final p in state.todos) {
                      if (p.id == consulta.pacienteId) {
                        fotoUrl = p.fotoUrl ?? p.fotoRuta;
                        break;
                      }
                    }
                  }

                  fotoUrl ??= pacienteFotoUrl;
                  final tieneFoto =
                      fotoUrl != null && fotoUrl.trim().isNotEmpty;

                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ac.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ac.primaryGreen.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: tieneFoto
                        ? Image.network(
                            fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: ac.primaryGreen,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: ac.primaryGreen,
                            size: 24,
                          ),
                  );
                },
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
                color: ac.primaryGreen,
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

  Widget _tarjetaRecetaCompleta(
    BuildContext context,
    Receta receta, {
    required bool esUltima,
  }) {
    final ac = context.appColors;
    final esAnulada = receta.estado == EstadoReceta.anulada;
    final esReemplazada = receta.estado == EstadoReceta.reemplazada;

    String? fotoCalculada = pacienteFotoUrl;
    try {
      final state = context.read<PacienteCubit>().state;
      if (state is PacienteDetailLoaded) {
        fotoCalculada = state.paciente.fotoUrl ?? state.paciente.fotoRuta;
      }
    } catch (_) {}

    return Container(
      margin: EdgeInsets.only(bottom: esUltima ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esAnulada || esReemplazada
              ? ac.red.withValues(alpha: 0.4)
              : ac.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: ac.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  receta.codigoReceta.isNotEmpty
                      ? receta.codigoReceta
                      : 'Receta Médica',
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!esAnulada && !esReemplazada) ...[
                IconButton(
                  tooltip: 'Imprimir Receta / Exportar PDF',
                  icon: Icon(Icons.print_rounded, color: ac.primaryGreen),
                  onPressed: () => _imprimirRecetaDirecta(
                    context,
                    receta,
                    fotoUrlFinal: fotoCalculada,
                  ),
                ),
                IconButton(
                  tooltip: 'Corregir / Formulario Formal',
                  icon: Icon(Icons.edit_note_rounded, color: ac.primaryGreen),
                  onPressed: () => _abrirRecetaFormDialog(context, receta),
                ),
              ],
              const SizedBox(width: 4),
              if (esAnulada)
                _pillStatus('ANULADA', ac.red)
              else if (esReemplazada)
                _pillStatus('REEMPLAZADA', ac.amber)
              else
                _pillStatus('ACTIVA', ac.green),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Emitida el ${fechaCortaEs(receta.fechaEmision)}',
            style: TextStyle(color: ac.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: 12),

          for (var i = 0; i < receta.items.length; i++)
            _itemRenglonMedicamento(context, receta.items[i], index: i + 1),

          if ((receta.indicacionesGenerales ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Indicaciones generales:',
              style: TextStyle(
                color: ac.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              receta.indicacionesGenerales!.trim(),
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],

          if ((receta.justificacionContraindicaciones ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: ac.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Justificación: ${receta.justificacionContraindicaciones!.trim()}',
                    style: TextStyle(
                      color: ac.amber,
                      fontSize: 11.5,
                      height: 1.3,
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

  Future<void> _abrirRecetaFormDialog(
    BuildContext context,
    Receta recetaOriginal,
  ) async {
    Paciente? paciente;
    try {
      final pacienteState = context.read<PacienteCubit>().state;
      if (pacienteState is PacienteDetailLoaded) {
        paciente = pacienteState.paciente;
      }
    } catch (_) {}

    if (paciente == null) {
      final partesNombre = nombrePaciente.trim().split(' ');
      final primerNombre = partesNombre.isNotEmpty ? partesNombre.first : '';
      final apellidoSeparado = partesNombre.length > 1
          ? partesNombre.sublist(1).join(' ')
          : '';

      paciente = Paciente(
        id: consulta.pacienteId,
        nombre: primerNombre,
        apellido: apellidoSeparado,
        birthDate: DateTime.now(),
        govID: '',
        contactos: const [],
        estatus: EstatusPersona.activo,
        genero: Genero.noPrefiereDecir,
        record: Record(
          pacienteId: consulta.pacienteId,
          tipoSangre: TipoSangre.aNegativo,
          condiciones: const [],
          cirugiasPrevias: const [],
          historialFamiliar: '',
        ),
        trabajo: '',
        referencia: '',
        citas: const [],
        tipoPaciente: TipoPaciente.integrado,
      );
    }

    final recetaCorregida = await RecetaFormDialog.mostrar(
      context,
      paciente: paciente,
      consultaId: consulta.id ?? '',
      recetaParaEditar: recetaOriginal,
    );

    if (recetaCorregida != null && context.mounted) {
      try {
        if (recetaOriginal.id != null && recetaOriginal.id!.isNotEmpty) {
          await sl<RecetaRepository>().reemitirRecetaModificada(
            recetaOriginalId: recetaOriginal.id!,
            motivoReemplazo: 'Corrección / Modificación formal de receta',
            nuevaReceta: recetaCorregida.copyWith(id: null),
          );
        } else {
          await sl<RecetaRepository>().emitirReceta(
            recetaCorregida.copyWith(id: null),
          );
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receta actualizada y reemitida correctamente.'),
          ),
        );

        _imprimirRecetaDirecta(
          context,
          recetaCorregida,
          fotoUrlFinal: paciente.fotoUrl ?? paciente.fotoRuta,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reemitir la receta: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
    }
  }

  Widget _itemRenglonMedicamento(
    BuildContext context,
    ItemReceta item, {
    required int index,
  }) {
    final ac = context.appColors;
    final titulo = item.presentacionConcentracion.isNotEmpty
        ? '$index. ${item.nombreMedicamento} (${item.presentacionConcentracion})'
        : '$index. ${item.nombreMedicamento}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ac.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pildoraReceta(context, 'Dosis', item.dosis),
              _pildoraReceta(context, 'Vía', item.viaAdministracion),
              _pildoraReceta(context, 'Frecuencia', item.frecuencia),
              _pildoraReceta(context, 'Duración', item.duracion),
              if (item.cantidadIndicada.isNotEmpty)
                _pildoraReceta(context, 'Cantidad', item.cantidadIndicada),
            ],
          ),
          if ((item.indicacionesEspecificas ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.indicacionesEspecificas!.trim(),
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pillStatus(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _pildoraReceta(BuildContext context, String label, String valor) {
    final ac = context.appColors;
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: ac.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: valor.trim(),
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          icon: Icon(Icons.link_rounded, size: 18, color: ac.primaryGreen),
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
                crossAxisAlignment: CrossAxisAlignment.center,
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

  /// Cita de la que salió esta consulta. `Consulta.citaId` se guardaba desde
  /// siempre pero no se mostraba en ninguna pantalla (SD-160): sin este bloque
  /// no había forma de saltar de la lista de consultas a la agenda ni de
  /// distinguir una atención sin cita de una cita perdida.
  Widget _seccionCitaOrigen(BuildContext context) {
    final ac = context.appColors;
    return BlocBuilder<ConsultaDetalleCubit, ConsultaDetalleState>(
      builder: (context, state) {
        final listo = state is ConsultaDetalleListo ? state : null;
        final cita = listo?.citaOrigen;

        final Widget cuerpo;
        if (listo == null) {
          cuerpo = Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Buscando la cita de origen…',
                style: TextStyle(color: ac.textMuted, fontSize: 13),
              ),
            ],
          );
        } else if (cita != null) {
          final hora = TimeOfDay.fromDateTime(cita.fechaHora);
          cuerpo = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _datoCitaOrigen(
                context,
                Icons.event_rounded,
                fechaLargaEs(cita.fechaHora),
              ),
              _datoCitaOrigen(
                context,
                Icons.schedule_rounded,
                hora.format(context),
              ),
              _chipEstadoCita(context, cita.estado),
            ],
          );
        } else if (listo.citaOrigenAusente) {
          cuerpo = _avisoCitaOrigen(
            context,
            ac.amber,
            Icons.link_off_rounded,
            'La cita de origen no está disponible: pudo eliminarse después de '
            'registrar la consulta.',
          );
        } else {
          cuerpo = _avisoCitaOrigen(
            context,
            ac.textMuted,
            Icons.event_busy_rounded,
            'Consulta sin cita: se atendió sin pasar por la agenda.',
          );
        }

        return _seccion(
          context,
          'Cita de origen',
          Icons.event_available_rounded,
          ac.indigo,
          cuerpo,
        );
      },
    );
  }

  Widget _datoCitaOrigen(BuildContext context, IconData icono, String texto) {
    final ac = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: ac.textMuted),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _chipEstadoCita(BuildContext context, EstadoCita estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estado.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: estado.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _avisoCitaOrigen(
    BuildContext context,
    Color color,
    IconData icono,
    String texto,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

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
