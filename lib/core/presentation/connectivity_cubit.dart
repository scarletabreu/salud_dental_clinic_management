import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/connectivity_check.dart';

enum ConnectivityStatus { online, offline }

/// Deriva un estado online/offline del [ConnectivityCheck] para alimentar el
/// banner del shell. No bloquea peticiones: es solo señal de UI.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final ConnectivityCheck _check;
  StreamSubscription<bool>? _sub;

  ConnectivityCubit(this._check) : super(ConnectivityStatus.online);

  Future<void> start() async {
    _sub = _check.onStatusChange.listen(_apply);
    _apply(await _check.hasConnection);
  }

  void _apply(bool online) {
    final next =
        online ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (next != state) emit(next);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
