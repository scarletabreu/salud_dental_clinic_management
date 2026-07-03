import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';

/// Extensiones que el visor puede renderizar como imagen con `Image.network`.
const _extensionesImagen = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

/// Deriva la extensión del archivo desde la URL pública de Storage,
/// ignorando el querystring (`?token=…`) y la carpeta del paciente.
String extensionDe(String url) {
  final sinQuery = url.split('?').first;
  final ultimoSegmento = sinQuery.split('/').last;
  if (!ultimoSegmento.contains('.')) return '';
  return ultimoSegmento.split('.').last.toLowerCase();
}

/// True si la URL apunta a una imagen que se puede previsualizar en el visor.
bool esImagen(String url) => _extensionesImagen.contains(extensionDe(url));

/// True si la URL apunta a un PDF (no previsualizable, se ofrece copiar enlace).
bool esPdf(String url) => extensionDe(url) == 'pdf';

String etiquetaTipoDocumento(TipoDocumento tipo) {
  switch (tipo) {
    case TipoDocumento.imagen:
      return 'Imagen';
    case TipoDocumento.video:
      return 'Video';
    case TipoDocumento.radiografia:
      return 'Radiografía';
  }
}

IconData iconoTipoDocumento(TipoDocumento tipo) {
  switch (tipo) {
    case TipoDocumento.imagen:
      return Icons.image_rounded;
    case TipoDocumento.video:
      return Icons.videocam_rounded;
    case TipoDocumento.radiografia:
      return Icons.medical_information_rounded;
  }
}
