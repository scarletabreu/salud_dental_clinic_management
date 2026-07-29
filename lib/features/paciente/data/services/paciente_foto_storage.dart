import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestiona fotos de pacientes en Storage. Las rutas son estables para que al
/// reemplazar una foto no se acumulen objetos huérfanos.
class PacienteFotoStorage {
  PacienteFotoStorage(this._client);

  final SupabaseClient _client;

  static const bucket = 'fotos-pacientes';
  static const maxOriginalBytes = 10 * 1024 * 1024;
  static const maxCompressedBytes = 2 * 1024 * 1024;
  static const ladoMaximo = 1024;

  /// Vida de la URL firmada. Se renueva con margen para que una lista abierta
  /// mucho tiempo no muestre imágenes rotas.
  static const duracionUrlFirmada = Duration(minutes: 30);
  static const _margenRenovacion = Duration(minutes: 2);

  final Map<String, _UrlFirmada> _cacheUrls = {};

  /// Valida el original y lo deja listo para recortar: orientación EXIF
  /// aplicada y decodificado una sola vez.
  img.Image decodificar(Uint8List original) {
    if (original.lengthInBytes > maxOriginalBytes) {
      throw const FormatoFotoInvalido(
        'La imagen no puede superar 10 MB antes de procesarla.',
      );
    }
    if (!_esImagenPermitida(original)) {
      throw const FormatoFotoInvalido(
        'Selecciona una imagen JPG, PNG o WebP válida.',
      );
    }

    final decoded = img.decodeImage(original);
    if (decoded == null) {
      throw const FormatoFotoInvalido('No fue posible leer la imagen.');
    }
    return img.bakeOrientation(decoded);
  }

  /// Reduce el lado mayor a [ladoMaximo] y codifica en JPEG, que es el único
  /// mime aceptado por la restricción de la tabla.
  Uint8List comprimir(img.Image imagen) {
    final largestSide = imagen.width > imagen.height
        ? imagen.width
        : imagen.height;
    final resized = largestSide > ladoMaximo
        ? img.copyResize(
            imagen,
            width: imagen.width >= imagen.height ? ladoMaximo : null,
            height: imagen.height > imagen.width ? ladoMaximo : null,
            interpolation: img.Interpolation.average,
          )
        : imagen;
    final bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    if (bytes.lengthInBytes > maxCompressedBytes) {
      throw const FormatoFotoInvalido(
        'La imagen optimizada aún supera el límite de 2 MB.',
      );
    }
    return bytes;
  }

  /// Recorta [imagen] al cuadrado indicado, saneando el rectángulo contra los
  /// bordes para que un gesto en el visor nunca produzca un recorte inválido.
  img.Image recortarCuadrado(
    img.Image imagen, {
    required int x,
    required int y,
    required int lado,
  }) {
    final maxLado = imagen.width < imagen.height ? imagen.width : imagen.height;
    final ladoSeguro = lado.clamp(1, maxLado);
    final xSeguro = x.clamp(0, imagen.width - ladoSeguro);
    final ySeguro = y.clamp(0, imagen.height - ladoSeguro);
    return img.copyCrop(
      imagen,
      x: xSeguro,
      y: ySeguro,
      width: ladoSeguro,
      height: ladoSeguro,
    );
  }

  /// Camino directo sin recorte manual: valida, orienta y comprime.
  Uint8List preparar(Uint8List original) => comprimir(decodificar(original));

  Future<void> guardar({
    required String pacienteId,
    required Uint8List bytes,
  }) async {
    final ruta = _rutaPara(pacienteId);
    await _client.storage
        .from(bucket)
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
            cacheControl: '3600',
          ),
        );
    await _client
        .from('pacientes')
        .update({
          'foto_ruta': ruta,
          'foto_mime_type': 'image/jpeg',
          'foto_tamano_bytes': bytes.lengthInBytes,
          'foto_actualizada_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pacienteId);
    _cacheUrls.remove(ruta);
  }

  Future<void> eliminar({
    required String pacienteId,
    required String ruta,
  }) async {
    await _client.storage.from(bucket).remove([ruta]);
    await _client
        .from('pacientes')
        .update({
          'foto_ruta': null,
          'foto_mime_type': null,
          'foto_tamano_bytes': null,
          'foto_actualizada_en': null,
        })
        .eq('id', pacienteId);
    _cacheUrls.remove(ruta);
  }

  /// URL firmada con caché por ruta: un listado de pacientes reconstruye sus
  /// filas constantemente y sin esto firmaba una URL por cada rebuild.
  Future<String> urlFirmada(String ruta) {
    final vigente = _cacheUrls[ruta];
    if (vigente != null && !vigente.expirada) return vigente.url;

    final pendiente = _client.storage
        .from(bucket)
        .createSignedUrl(ruta, duracionUrlFirmada.inSeconds);
    _cacheUrls[ruta] = _UrlFirmada(
      url: pendiente,
      expiraEn: DateTime.now().add(duracionUrlFirmada - _margenRenovacion),
    );
    // Un fallo no debe quedar cacheado: la siguiente lectura vuelve a firmar.
    pendiente.catchError((Object error) {
      _cacheUrls.remove(ruta);
      throw error;
    });
    return pendiente;
  }

  void invalidarCache() => _cacheUrls.clear();

  String _rutaPara(String pacienteId) => '$pacienteId/perfil.jpg';

  bool _esImagenPermitida(Uint8List bytes) {
    if (bytes.lengthInBytes < 12) return false;
    final jpg = bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff;
    final png =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
    final webp =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return jpg || png || webp;
  }
}

class _UrlFirmada {
  _UrlFirmada({required this.url, required this.expiraEn});

  final Future<String> url;
  final DateTime expiraEn;

  bool get expirada => DateTime.now().isAfter(expiraEn);
}

class FormatoFotoInvalido implements Exception {
  const FormatoFotoInvalido(this.message);
  final String message;

  @override
  String toString() => message;
}
