import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/presentation/util/documento_media.dart';

/// Visor a pantalla completa de un documento clínico. Las imágenes se muestran
/// con zoom (pinch/scroll); el resto de formatos (PDF, DICOM…) no son
/// previsualizables, así que se ofrece copiar el enlace del archivo.
class DocumentoViewerPage extends StatelessWidget {
  final DocumentoClinico documento;

  const DocumentoViewerPage({super.key, required this.documento});

  static Future<void> abrir(BuildContext context, DocumentoClinico documento) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DocumentoViewerPage(documento: documento),
      ),
    );
  }

  void _copiarEnlace(BuildContext context) {
    Clipboard.setData(ClipboardData(text: documento.urlArchivo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagen = esImagen(documento.urlArchivo);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          documento.descripcion,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Copiar enlace del documento',
            icon: const Icon(Icons.link_rounded),
            onPressed: () => _copiarEnlace(context),
          ),
        ],
      ),
      body: imagen ? _visorImagen() : _fallbackNoPrevisualizable(context),
      bottomNavigationBar: _barraInfo(),
    );
  }

  Widget _visorImagen() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 5,
      child: Center(
        child: Image.network(
          documento.urlArchivo,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            );
          },
          errorBuilder: (context, error, stack) => _mensajeError(),
        ),
      ),
    );
  }

  Widget _mensajeError() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.white38, size: 56),
          SizedBox(height: 12),
          Text(
            'No se pudo cargar la imagen',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _fallbackNoPrevisualizable(BuildContext context) {
    final esArchivoPdf = esPdf(documento.urlArchivo);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esArchivoPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              color: Colors.white38,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Este documento no se puede previsualizar aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Copia el enlace para abrirlo en tu navegador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _copiarEnlace(context),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Copiar enlace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraInfo() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Icon(iconoTipoDocumento(documento.tipoDocumento),
              color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            etiquetaTipoDocumento(documento.tipoDocumento),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          const Icon(Icons.calendar_today_rounded,
              color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Text(
            fechaCortaEs(documento.fechaCreacion),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
