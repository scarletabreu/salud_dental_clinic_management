import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/helpers/expediente_pdf_builder.dart';

class GenerarExpedienteModal extends StatefulWidget {
  final Paciente paciente;
  final Odontograma? odontogramaActual;
  final List<Consulta> consultasConOdontograma;
  final HistorialPiezas? historialPiezas;

  const GenerarExpedienteModal({
    super.key,
    required this.paciente,
    this.odontogramaActual,
    this.consultasConOdontograma = const [],
    this.historialPiezas,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required Paciente paciente,
    Odontograma? odontogramaActual,
    List<Consulta> consultasConOdontograma = const [],
    HistorialPiezas? historialPiezas,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerarExpedienteModal(
        paciente: paciente,
        odontogramaActual: odontogramaActual,
        consultasConOdontograma: consultasConOdontograma,
        historialPiezas: historialPiezas,
      ),
    );
  }

  @override
  State<GenerarExpedienteModal> createState() => _GenerarExpedienteModalState();
}

enum TipoOdontogramaImpresion {
  consolidadoHistorico,
  consultaEspecifica,
  sinOdontograma,
}

class _GenerarExpedienteModalState extends State<GenerarExpedienteModal> {
  TipoOdontogramaImpresion _opcionSeleccionada =
      TipoOdontogramaImpresion.consolidadoHistorico;
  Consulta? _consultaSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.consultasConOdontograma.isNotEmpty) {
      _consultaSeleccionada = widget.consultasConOdontograma.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final nombrePaciente =
        '${widget.paciente.nombre} ${widget.paciente.apellido}';

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ac.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ac.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.print_rounded,
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
                          'Generar Expediente Clínico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ac.textPrimary,
                          ),
                        ),
                        Text(
                          nombrePaciente,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ac.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _OptionTile(
                    titulo: 'Odontograma Histórico Consolidado',
                    subtitulo:
                        'Acumula todos los hallazgos y tratamientos hechos al paciente',
                    icono: Icons.layers_rounded,
                    selected:
                        _opcionSeleccionada ==
                        TipoOdontogramaImpresion.consolidadoHistorico,
                    onTap: () => setState(
                      () => _opcionSeleccionada =
                          TipoOdontogramaImpresion.consolidadoHistorico,
                    ),
                    ac: ac,
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    titulo: 'Odontograma de una Consulta Específica',
                    subtitulo:
                        'Imprime únicamente el estado registrado en una fecha concreta',
                    icono: Icons.event_note_rounded,
                    selected:
                        _opcionSeleccionada ==
                        TipoOdontogramaImpresion.consultaEspecifica,
                    onTap: () => setState(
                      () => _opcionSeleccionada =
                          TipoOdontogramaImpresion.consultaEspecifica,
                    ),
                    ac: ac,
                  ),
                  if (_opcionSeleccionada ==
                          TipoOdontogramaImpresion.consultaEspecifica &&
                      widget.consultasConOdontograma.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ac.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ac.primaryBlue),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Consulta>(
                          value: _consultaSeleccionada,
                          isExpanded: true,
                          items: widget.consultasConOdontograma.map((c) {
                            return DropdownMenuItem<Consulta>(
                              value: c,
                              child: Text(
                                'Consulta del ${fechaLargaEs(c.fecha)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _consultaSeleccionada = val),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _OptionTile(
                    titulo: 'Sin Odontograma',
                    subtitulo:
                        'Imprime solo datos del paciente, antecedentes e historial',
                    icono: Icons.description_rounded,
                    selected:
                        _opcionSeleccionada ==
                        TipoOdontogramaImpresion.sinOdontograma,
                    onTap: () => setState(
                      () => _opcionSeleccionada =
                          TipoOdontogramaImpresion.sinOdontograma,
                    ),
                    ac: ac,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        _abrirPrevisualizacion(navigator);
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Generar PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirPrevisualizacion(NavigatorState navigator) {
    final incluirOdontograma =
        _opcionSeleccionada != TipoOdontogramaImpresion.sinOdontograma;

    final odontogramaIndividual =
        _opcionSeleccionada == TipoOdontogramaImpresion.consultaEspecifica
        ? _consultaSeleccionada?.odontograma
        : widget.odontogramaActual;

    final historialOdontogramas =
        _opcionSeleccionada == TipoOdontogramaImpresion.consolidadoHistorico
        ? widget.consultasConOdontograma
              .map((c) => c.odontograma)
              .whereType<Odontograma>()
              .toList()
        : const <Odontograma>[];

    final hp =
        _opcionSeleccionada == TipoOdontogramaImpresion.consolidadoHistorico
        ? widget.historialPiezas
        : null;

    final options = ExpedientePrintOptions(
      incluirOdontograma: incluirOdontograma,
    );
    final nombrePaciente =
        '${widget.paciente.nombre} ${widget.paciente.apellido}';

    navigator.push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            backgroundColor: context.appColors.primaryBlue,
            foregroundColor: Colors.white,
            title: Text('Expediente de $nombrePaciente'),
          ),
          body: PdfPreview(
            build: (format) => ExpedientePdfBuilder.buildPdf(
              paciente: widget.paciente,
              options: options,
              odontograma: odontogramaIndividual,
              historialOdontogramas: historialOdontogramas,
              historialPiezas: hp,
            ),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool selected;
  final VoidCallback onTap;
  final AppColors ac;

  const _OptionTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.selected,
    required this.onTap,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? ac.primaryBlue.withValues(alpha: 0.08) : ac.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ac.primaryBlue : ac.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: selected ? ac.primaryBlue : ac.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 11, color: ac.textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ac.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? ac.primaryBlue : ac.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
