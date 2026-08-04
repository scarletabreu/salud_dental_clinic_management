import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/presentation/app_colors.dart';
import '../../core/presentation/connectivity_cubit.dart';

/// Banner discreto de estado de conexión. Aparece al perder la red y muestra
/// brevemente "Conexión restablecida" al volver. No bloquea ni tapa el
/// contenido clínico. Usa AppColors (sistema de diseño B).
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _visible = false;
  bool _restored = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onStatus(ConnectivityStatus status) {
    _hideTimer?.cancel();
    if (status == ConnectivityStatus.offline) {
      setState(() {
        _visible = true;
        _restored = false;
      });
    } else if (_visible) {
      // Volvió la conexión: confirma brevemente y luego oculta.
      setState(() => _restored = true);
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _visible = false;
          _restored = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final background = _restored ? colors.green : colors.red;
    final message = _restored
        ? 'Conexión restablecida'
        : 'Sin conexión — los cambios no se están sincronizando';
    final icon = _restored ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      listener: (_, status) => _onStatus(status),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _visible
            ? Container(
                width: double.infinity,
                color: background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
