import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/helpers/expediente_pdf_builder.dart';

enum TipoFormatoExpediente {
  conOdontograma('Con Odontograma', true),
  sinOdontograma('Sin Odontograma', false);

  final String label;
  final bool incluirOdontograma;
  const TipoFormatoExpediente(this.label, this.incluirOdontograma);
}

class ExpedientePage extends StatefulWidget {
  final Paciente paciente;
  final Odontograma? odontogramaActual;
  final List<Consulta> consultasConOdontograma;
  final HistorialPiezas? historialPiezas;

  const ExpedientePage({
    super.key,
    required this.paciente,
    this.odontogramaActual,
    this.consultasConOdontograma = const [],
    this.historialPiezas,
  });

  static Future<void> navegar(
    BuildContext context, {
    required Paciente paciente,
    Odontograma? odontogramaActual,
    List<Consulta> consultasConOdontograma = const [],
    HistorialPiezas? historialPiezas,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpedientePage(
          paciente: paciente,
          odontogramaActual: odontogramaActual,
          consultasConOdontograma: consultasConOdontograma,
          historialPiezas: historialPiezas,
        ),
      ),
    );
  }

  @override
  State<ExpedientePage> createState() => _ExpedientePageState();
}

class _ExpedientePageState extends State<ExpedientePage> {
  bool _procesando = false;
  TipoFormatoExpediente _formatoSeleccionado =
      TipoFormatoExpediente.conOdontograma;

  pw.MemoryImage? _logoImage;

  @override
  void initState() {
    super.initState();
    _precargarLogo();
  }

  Future<void> _precargarLogo() async {
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      if (mounted) {
        setState(() {
          _logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        });
      }
    } catch (_) {}
  }

  String get _nombreArchivo =>
      'Expediente_${widget.paciente.nombre}_${widget.paciente.apellido}.pdf'
          .replaceAll(' ', '_');

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await accion();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo preparar el expediente. Inténtalo de nuevo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  List<Odontograma> _obtenerHistorialOdontogramas() {
    return _formatoSeleccionado.incluirOdontograma
        ? widget.consultasConOdontograma
              .map((c) => c.odontograma)
              .whereType<Odontograma>()
              .toList()
        : const <Odontograma>[];
  }

  Future<void> _imprimir() => _ejecutar(() async {
    final historial = _obtenerHistorialOdontogramas();
    await Printing.layoutPdf(
      name: _nombreArchivo,
      onLayout: (_) => ExpedientePdfBuilder.buildPdf(
        paciente: widget.paciente,
        options: ExpedientePrintOptions(
          incluirOdontograma: _formatoSeleccionado.incluirOdontograma,
        ),
        odontograma: _formatoSeleccionado.incluirOdontograma
            ? widget.odontogramaActual
            : null,
        historialOdontogramas: historial,
        historialPiezas: _formatoSeleccionado.incluirOdontograma
            ? widget.historialPiezas
            : null,
        compress: true,
      ),
    );
  });

  Future<void> _guardarPdf() => _ejecutar(() async {
    final historial = _obtenerHistorialOdontogramas();
    final bytes = await ExpedientePdfBuilder.buildPdf(
      paciente: widget.paciente,
      options: ExpedientePrintOptions(
        incluirOdontograma: _formatoSeleccionado.incluirOdontograma,
      ),
      odontograma: _formatoSeleccionado.incluirOdontograma
          ? widget.odontogramaActual
          : null,
      historialOdontogramas: historial,
      historialPiezas: _formatoSeleccionado.incluirOdontograma
          ? widget.historialPiezas
          : null,
      compress: true,
    );
    await Printing.sharePdf(bytes: bytes, filename: _nombreArchivo);
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expediente Clínico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ac.textPrimary,
              ),
            ),
            Text(
              '${widget.paciente.nombre} ${widget.paciente.apellido}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ac.primaryGreen,
              ),
            ),
          ],
        ),
        backgroundColor: ac.cardBg,
        foregroundColor: ac.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          _BarraAcciones(
            procesando: _procesando,
            formatoActual: _formatoSeleccionado,
            onFormatoChanged: (nuevoFormato) {
              if (nuevoFormato != null) {
                setState(() => _formatoSeleccionado = nuevoFormato);
              }
            },
            onImprimir: _imprimir,
            onGuardarPdf: _guardarPdf,
          ),
          Expanded(
            child: PdfPreview(
              build: (format) async {
                final historial = _obtenerHistorialOdontogramas();
                return ExpedientePdfBuilder.buildPdf(
                  paciente: widget.paciente,
                  options: ExpedientePrintOptions(
                    incluirOdontograma: _formatoSeleccionado.incluirOdontograma,
                  ),
                  odontograma: _formatoSeleccionado.incluirOdontograma
                      ? widget.odontogramaActual
                      : null,
                  historialOdontogramas: historial,
                  historialPiezas: _formatoSeleccionado.incluirOdontograma
                      ? widget.historialPiezas
                      : null,
                  compress: false,
                );
              },
              pdfFileName: _nombreArchivo,
              useActions: false,
              maxPageWidth: 780,
              loadingWidget: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: ac.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ac.divider),
                    boxShadow: [ac.cardShadow],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: ac.primaryGreen,
                          strokeWidth: 2.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Generando documento clínico...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  final bool procesando;
  final TipoFormatoExpediente formatoActual;
  final ValueChanged<TipoFormatoExpediente?> onFormatoChanged;
  final VoidCallback onImprimir;
  final VoidCallback onGuardarPdf;

  const _BarraAcciones({
    required this.procesando,
    required this.formatoActual,
    required this.onFormatoChanged,
    required this.onImprimir,
    required this.onGuardarPdf,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: ac.cardBg,
        border: Border(bottom: BorderSide(color: ac.divider, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ac.divider),
                  color: ac.chipBg,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoFormatoExpediente>(
                    value: formatoActual,
                    icon: Icon(
                      Icons.layers_outlined,
                      size: 18,
                      color: ac.primaryGreen,
                    ),
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: procesando ? null : onFormatoChanged,
                    items: TipoFormatoExpediente.values.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f.label));
                    }).toList(),
                  ),
                ),
              ),

              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('guardar_pdf_expediente_button'),
                    onPressed: procesando ? null : onGuardarPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                    label: const Text('Guardar PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ac.textSecondary,
                      side: BorderSide(color: ac.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('imprimir_expediente_button'),
                    onPressed: procesando ? null : onImprimir,
                    icon: procesando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 19),
                    label: Text(procesando ? 'Preparando…' : 'Imprimir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
