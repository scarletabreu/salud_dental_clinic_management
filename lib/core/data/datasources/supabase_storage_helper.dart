import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper para subir documentos clínicos (radiografías) a Supabase Storage.
class SupabaseStorageHelper {
  final SupabaseClient supabaseClient;

  SupabaseStorageHelper({required this.supabaseClient});

  static const String bucket = 'documentos-clinicos';

  /// Sube [bytes] al bucket bajo la carpeta del paciente y retorna la URL
  /// pública del archivo. Funciona en todas las plataformas (usa bytes en vez
  /// de un File para soportar también web).
  Future<String> subirDocumento({
    required Uint8List bytes,
    required String fileName,
    required String pacienteId,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final nombre = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ruta = '$pacienteId/$nombre';

    await supabaseClient.storage
        .from(bucket)
        .uploadBinary(ruta, bytes, fileOptions: const FileOptions());

    return supabaseClient.storage.from(bucket).getPublicUrl(ruta);
  }
}
