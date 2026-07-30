import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper para subir documentos clínicos (radiografías) a Supabase Storage.
class SupabaseStorageHelper {
  final SupabaseClient supabaseClient;

  SupabaseStorageHelper({required this.supabaseClient});

  static const String bucket = 'documentos-clinicos';

  /// Sube [bytes] al bucket privado bajo paciente/actor y retorna la ruta que
  /// se persiste. Funciona en todas las plataformas (usa bytes en vez de un
  /// File para soportar también web).
  Future<String> subirDocumento({
    required Uint8List bytes,
    required String fileName,
    required String pacienteId,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final nombre = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final actorId = supabaseClient.auth.currentUser?.id;
    if (actorId == null) {
      throw const AuthException(
        'Sesión clínica requerida para subir archivos.',
      );
    }
    final ruta = '$pacienteId/$actorId/$nombre';

    await supabaseClient.storage
        .from(bucket)
        .uploadBinary(ruta, bytes, fileOptions: const FileOptions());

    return ruta;
  }

  Future<String> crearUrlFirmada(
    String ruta, {
    Duration duracion = const Duration(minutes: 5),
  }) {
    return supabaseClient.storage
        .from(bucket)
        .createSignedUrl(_extraerRutaRelativa(ruta), duracion.inSeconds);
  }

  String _extraerRutaRelativa(String valor) {
    final limpia = valor.trim();
    if (!limpia.startsWith('http://') && !limpia.startsWith('https://')) {
      return limpia;
    }
    final segmentos = Uri.parse(limpia).pathSegments;
    final indiceBucket = segmentos.indexOf(bucket);
    if (indiceBucket < 0 || indiceBucket == segmentos.length - 1) {
      throw const FormatException('Ruta de documento clínico inválida.');
    }
    return segmentos.sublist(indiceBucket + 1).join('/');
  }
}
