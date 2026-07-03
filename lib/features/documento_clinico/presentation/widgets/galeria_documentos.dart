import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/presentation/pages/documento_viewer_page.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/presentation/util/documento_media.dart';

/// Galería de documentos clínicos: miniatura + descripción + tipo + fecha.
/// Al tocar una tarjeta se abre el documento a pantalla completa.
/// Reutilizada en el detalle de la consulta y en el expediente del paciente.
class GaleriaDocumentos extends StatelessWidget {
  final List<DocumentoClinico> documentos;

  /// Muestra la fecha bajo cada miniatura. Útil en el expediente (documentos
  /// de varias consultas); en el detalle de una sola consulta puede omitirse.
  final bool mostrarFecha;

  const GaleriaDocumentos({
    super.key,
    required this.documentos,
    this.mostrarFecha = true,
  });

  @override
  Widget build(BuildContext context) {
    if (documentos.isEmpty) {
      return _EstadoVacio();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final doc in documentos)
          _DocumentoCard(documento: doc, mostrarFecha: mostrarFecha),
      ],
    );
  }
}

class _DocumentoCard extends StatelessWidget {
  final DocumentoClinico documento;
  final bool mostrarFecha;

  const _DocumentoCard({required this.documento, required this.mostrarFecha});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final imagen = esImagen(documento.urlArchivo);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => DocumentoViewerPage.abrir(context, documento),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 150,
                height: 112,
                child: imagen
                    ? _Miniatura(url: documento.urlArchivo, ac: ac)
                    : _PlaceholderTipo(documento: documento, ac: ac),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              documento.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(iconoTipoDocumento(documento.tipoDocumento),
                    size: 12, color: ac.indigo),
                const SizedBox(width: 4),
                Text(
                  etiquetaTipoDocumento(documento.tipoDocumento),
                  style: TextStyle(color: ac.textMuted, fontSize: 11),
                ),
              ],
            ),
            if (mostrarFecha) ...[
              const SizedBox(height: 2),
              Text(
                fechaCortaEs(documento.fechaCreacion),
                style: TextStyle(color: ac.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final String url;
  final AppColors ac;

  const _Miniatura({required this.url, required this.ac});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: ac.chipBg,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: ac.textMuted),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: ac.chipBg,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_rounded, color: ac.textMuted, size: 28),
      ),
    );
  }
}

class _PlaceholderTipo extends StatelessWidget {
  final DocumentoClinico documento;
  final AppColors ac;

  const _PlaceholderTipo({required this.documento, required this.ac});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ac.indigo.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        esPdf(documento.urlArchivo)
            ? Icons.picture_as_pdf_rounded
            : iconoTipoDocumento(documento.tipoDocumento),
        color: ac.indigo,
        size: 34,
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 30, color: ac.textDisabled),
            const SizedBox(height: 8),
            Text(
              'Sin documentos ni imágenes',
              style: TextStyle(
                fontSize: 13,
                color: ac.textDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
