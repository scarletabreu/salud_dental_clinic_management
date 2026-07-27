import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

/// Avatar privado: la app solicita una URL firmada efímera solo al mostrarla.
class PacienteAvatar extends StatefulWidget {
  const PacienteAvatar({
    super.key,
    required this.paciente,
    this.size = 48,
    this.backgroundColor,
  });

  final Paciente paciente;
  final double size;
  final Color? backgroundColor;

  @override
  State<PacienteAvatar> createState() => _PacienteAvatarState();
}

class _PacienteAvatarState extends State<PacienteAvatar> {
  late Future<String>? _url;

  @override
  void initState() {
    super.initState();
    _url = _crearUrl();
  }

  @override
  void didUpdateWidget(covariant PacienteAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paciente.fotoRuta != widget.paciente.fotoRuta ||
        oldWidget.paciente.fotoActualizadaEn !=
            widget.paciente.fotoActualizadaEn) {
      _url = _crearUrl();
    }
  }

  Future<String>? _crearUrl() {
    final ruta = widget.paciente.fotoRuta;
    if (ruta == null || ruta.isEmpty) return null;
    return sl<PacienteFotoStorage>().urlFirmada(ruta);
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return _fallback();
    return FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _fallback(loading: true);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Tooltip(
            message: 'Foto no disponible',
            child: _fallback(error: true),
          );
        }
        return ClipOval(
          child: Image.network(
            snapshot.data!,
            key: ValueKey(
              '${widget.paciente.fotoRuta}:${widget.paciente.fotoActualizadaEn}',
            ),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(error: true),
          ),
        );
      },
    );
  }

  Widget _fallback({bool loading = false, bool error = false}) {
    final initials =
        '${_initial(widget.paciente.nombre)}${_initial(widget.paciente.apellido)}';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: widget.size * .38,
              height: widget.size * .38,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : error
          ? Icon(
              Icons.broken_image_outlined,
              size: widget.size * .42,
              color: Colors.white,
            )
          : Text(
              initials.isEmpty ? '?' : initials.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * .36,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  String _initial(String value) => value.trim().isEmpty ? '' : value.trim()[0];
}
