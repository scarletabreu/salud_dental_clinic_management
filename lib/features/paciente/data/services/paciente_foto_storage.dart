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

  Future<Uint8List> preparar(Uint8List original) async {
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

    final oriented = img.bakeOrientation(decoded);
    final largestSide = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final resized = largestSide > 1024
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1024 : null,
            height: oriented.height > oriented.width ? 1024 : null,
            interpolation: img.Interpolation.average,
          )
        : oriented;
    final bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    if (bytes.lengthInBytes > maxCompressedBytes) {
      throw const FormatoFotoInvalido(
        'La imagen optimizada aún supera el límite de 2 MB.',
      );
    }
    return bytes;
  }

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
  }

  Future<String> urlFirmada(String ruta) =>
      _client.storage.from(bucket).createSignedUrl(ruta, 300);

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

class FormatoFotoInvalido implements Exception {
  const FormatoFotoInvalido(this.message);
  final String message;

  @override
  String toString() => message;
}
