import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:web/web.dart' as web;

Future<Uint8List?> mostrarDialogoCamaraWeb(BuildContext context) async {
  final ac = context.appColors;
  final viewType = 'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

  final videoElement = web.HTMLVideoElement()
    ..autoplay = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => videoElement,
  );

  web.MediaStream? stream;

  try {
    final mediaDevices = web.window.navigator.mediaDevices;
    final constraints = web.MediaStreamConstraints(
      video: true.toJS,
      audio: false.toJS,
    );

    final mediaStreamPromise = mediaDevices.getUserMedia(constraints);
    stream = await mediaStreamPromise.toDart;
    videoElement.srcObject = stream;
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ac.red,
        content: const Text(
          'No se pudo acceder a la cámara. Permite el acceso en el navegador.',
        ),
      ),
    );
    return null;
  }

  Uint8List? fotoCapturadaBytes;
  if (!context.mounted) return null;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: ac.cardBg,
        title: Text(
          'Capturar fotografía',
          style: TextStyle(color: ac.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HtmlElementView(viewType: viewType),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              stream?.getTracks().toDart.forEach((track) {
                (track as web.MediaStreamTrack).stop();
              });
              Navigator.pop(dialogCtx);
            },
            child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
            icon: const Icon(Icons.camera_rounded, size: 18),
            label: const Text('Tirar foto'),
            onPressed: () {
              final canvas = web.HTMLCanvasElement()
                ..width = videoElement.videoWidth
                ..height = videoElement.videoHeight;

              final ctx = canvas.context2D;
              ctx.drawImage(videoElement, 0, 0);

              final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
              fotoCapturadaBytes = Uri.parse(dataUrl).data?.contentAsBytes();

              stream?.getTracks().toDart.forEach((track) {
                (track as web.MediaStreamTrack).stop();
              });

              Navigator.pop(dialogCtx);
            },
          ),
        ],
      );
    },
  );

  return fotoCapturadaBytes;
}
