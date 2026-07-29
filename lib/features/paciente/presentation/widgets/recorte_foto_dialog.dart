import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';

/// Recorte cuadrado y previsualización dentro de la app.
///
/// Se hace en Dart a propósito: `image_cropper` solo cubre Android e iOS con
/// configuración nativa adicional, y esta app también se despliega en web y
/// escritorio, donde lanzaba `MissingPluginException`.
class RecorteFotoDialog extends StatefulWidget {
  const RecorteFotoDialog({
    super.key,
    required this.imagen,
    required this.storage,
  });

  /// Imagen ya decodificada y orientada por [PacienteFotoStorage.decodificar].
  final img.Image imagen;
  final PacienteFotoStorage storage;

  /// Devuelve los bytes JPEG listos para subir, o `null` si se cancela.
  static Future<Uint8List?> mostrar(
    BuildContext context, {
    required img.Image imagen,
    required PacienteFotoStorage storage,
  }) {
    return showDialog<Uint8List>(
      context: context,
      builder: (_) => RecorteFotoDialog(imagen: imagen, storage: storage),
    );
  }

  @override
  State<RecorteFotoDialog> createState() => _RecorteFotoDialogState();
}

class _RecorteFotoDialogState extends State<RecorteFotoDialog> {
  static const double _viewport = 320;

  final TransformationController _controller = TransformationController();
  late final Uint8List _previewBytes;

  /// Tamaño del hijo del visor: la imagen escalada a "cover" del cuadrado.
  late final double _escalaCover;
  late final double _anchoBase;
  late final double _altoBase;

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    // Vista previa en PNG: evita recomprimir en cada rebuild y conserva el
    // color exacto de la fuente mientras el usuario encuadra.
    _previewBytes = Uint8List.fromList(img.encodePng(widget.imagen));
    final ancho = widget.imagen.width.toDouble();
    final alto = widget.imagen.height.toDouble();
    _escalaCover = ancho < alto ? _viewport / ancho : _viewport / alto;
    _anchoBase = ancho * _escalaCover;
    _altoBase = alto * _escalaCover;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        (_viewport - _anchoBase) / 2,
        (_viewport - _altoBase) / 2,
        0,
        1,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mantiene el cuadrado siempre cubierto por la imagen: sin esto el usuario
  /// puede arrastrar hasta dejar franjas vacías en el recorte.
  void _ajustarDentroDeLimites() {
    final m = _controller.value.clone();
    final escala = m.getMaxScaleOnAxis();
    final ancho = _anchoBase * escala;
    final alto = _altoBase * escala;
    final t = m.getTranslation();
    final x = t.x.clamp(_viewport - ancho, 0.0);
    final y = t.y.clamp(_viewport - alto, 0.0);
    if (x == t.x && y == t.y) return;
    m.setTranslationRaw(x, y, 0);
    _controller.value = m;
  }

  Future<void> _confirmar() async {
    setState(() => _procesando = true);
    try {
      final m = _controller.value;
      final escala = m.getMaxScaleOnAxis();
      final t = m.getTranslation();
      // Píxeles de origen por píxel lógico del visor.
      final porPixel = 1 / (_escalaCover * escala);
      final bytes = widget.storage.comprimir(
        widget.storage.recortarCuadrado(
          widget.imagen,
          x: (-t.x * porPixel).round(),
          y: (-t.y * porPixel).round(),
          lado: (_viewport * porPixel).round(),
        ),
      );
      if (mounted) Navigator.pop(context, bytes);
    } on FormatoFotoInvalido catch (error) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.appColors.red,
          content: Text(error.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AppDialog(
      title: const Text('Ajustar fotografía'),
      preferredWidth: _viewport + 48,
      scrollable: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: _viewport,
              height: _viewport,
              child: InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                clipBehavior: Clip.hardEdge,
                minScale: 1,
                maxScale: 5,
                onInteractionUpdate: (_) => _ajustarDentroDeLimites(),
                onInteractionEnd: (_) => _ajustarDentroDeLimites(),
                child: SizedBox(
                  width: _anchoBase,
                  height: _altoBase,
                  child: Image.memory(
                    _previewBytes,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Arrastra para encuadrar y pellizca o usa la rueda para acercar.',
            style: TextStyle(fontSize: 12, color: ac.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _procesando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _procesando ? null : _confirmar,
          child: Text(_procesando ? 'Procesando…' : 'Usar esta foto'),
        ),
      ],
    );
  }
}
