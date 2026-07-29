import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/presentation/widgets/receta_pdf_generator.dart';

class RecetaPage extends StatefulWidget {
  final Receta receta;
  final String nombrePaciente;
  final String? doctorNombre;
  final String? doctorTelefono;
  final String? doctorCelular;
  final String? doctorEmail;
  final String? pacienteFotoUrl;

  const RecetaPage({
    super.key,
    required this.receta,
    required this.nombrePaciente,
    this.doctorNombre,
    this.doctorTelefono,
    this.doctorCelular,
    this.doctorEmail,
    this.pacienteFotoUrl,
  });

  static Future<void> navegar(
    BuildContext context, {
    required Receta receta,
    required String nombrePaciente,
    String? doctorNombre,
    String? doctorTelefono,
    String? doctorCelular,
    String? doctorEmail,
    String? pacienteFotoUrl,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecetaPage(
          receta: receta,
          nombrePaciente: nombrePaciente,
          doctorNombre: doctorNombre,
          doctorTelefono: doctorTelefono,
          doctorCelular: doctorCelular,
          doctorEmail: doctorEmail,
          pacienteFotoUrl: pacienteFotoUrl,
        ),
      ),
    );
  }

  @override
  State<RecetaPage> createState() => _RecetaPageState();
}

class _RecetaPageState extends State<RecetaPage> {
  bool _procesando = false;
  pw.MemoryImage? _logoImage;
  pw.MemoryImage? _pacienteFotoImage;

  @override
  void initState() {
    super.initState();
    _precargarRecursosEnParalelo();
  }

  Future<void> _precargarRecursosEnParalelo() async {
    await Future.wait([_cargarLogo(), _cargarFotoPaciente()]);
  }

  Future<void> _cargarLogo() async {
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      if (mounted) {
        setState(() {
          _logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarFotoPaciente() async {
    final url = widget.pacienteFotoUrl?.trim();
    if (url == null || url.isEmpty) return;

    try {
      final bundle = NetworkAssetBundle(Uri.parse(url));
      final byteData = await bundle.load(url);
      if (mounted) {
        setState(() {
          _pacienteFotoImage = pw.MemoryImage(byteData.buffer.asUint8List());
        });
      }
    } catch (_) {}
  }

  String get _nombreArchivo =>
      'Receta_${widget.receta.codigoReceta}_${widget.nombrePaciente}'
          .replaceAll(' ', '_')
          .replaceAll('/', '-');

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await accion();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo procesar la receta. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _imprimir() => _ejecutar(() async {
    await Printing.layoutPdf(
      name: _nombreArchivo,
      onLayout: (_) => RecetaPdfGenerator.generatePdf(
        receta: widget.receta,
        pacienteNombre: widget.nombrePaciente,
        doctorNombre: widget.doctorNombre,
        doctorTelefono: widget.doctorTelefono,
        doctorCelular: widget.doctorCelular,
        doctorEmail: widget.doctorEmail,
        logoImage: _logoImage,
        pacienteFotoImage: _pacienteFotoImage,
        compress: true,
      ),
    );
  });

  Future<void> _guardarPdf() => _ejecutar(() async {
    final bytes = await RecetaPdfGenerator.generatePdf(
      receta: widget.receta,
      pacienteNombre: widget.nombrePaciente,
      doctorNombre: widget.doctorNombre,
      doctorTelefono: widget.doctorTelefono,
      doctorCelular: widget.doctorCelular,
      doctorEmail: widget.doctorEmail,
      logoImage: _logoImage,
      pacienteFotoImage: _pacienteFotoImage,
      compress: true,
    );
    await Printing.sharePdf(bytes: bytes, filename: _nombreArchivo);
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: ac.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_hospital_rounded,
                    color: ac.primaryGreen,
                    size: 18,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Receta Médica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                  ),
                ),
                Text(
                  '${widget.receta.codigoReceta} · ${widget.nombrePaciente}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ac.primaryGreen,
                  ),
                ),
              ],
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
            onImprimir: _imprimir,
            onGuardarPdf: _guardarPdf,
          ),
          Expanded(
            child: PdfPreview(
              build: (format) async {
                return RecetaPdfGenerator.generatePdf(
                  receta: widget.receta,
                  pacienteNombre: widget.nombrePaciente,
                  doctorNombre: widget.doctorNombre,
                  doctorTelefono: widget.doctorTelefono,
                  doctorCelular: widget.doctorCelular,
                  doctorEmail: widget.doctorEmail,
                  logoImage: _logoImage,
                  pacienteFotoImage: _pacienteFotoImage,
                  compress: false,
                );
              },
              pdfFileName: _nombreArchivo,
              useActions: false,
              maxPageWidth: 780,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  final bool procesando;
  final VoidCallback onImprimir;
  final VoidCallback onGuardarPdf;

  const _BarraAcciones({
    required this.procesando,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('guardar_pdf_receta_button'),
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
              const SizedBox(width: 12),
              FilledButton.icon(
                key: const Key('imprimir_receta_button'),
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
        ),
      ),
    );
  }
}
