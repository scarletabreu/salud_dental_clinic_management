import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/network/connectivity_check.dart';
import 'package:salud_dental_clinic_management/core/presentation/connectivity_cubit.dart';

class _FakeConnectivityCheck implements ConnectivityCheck {
  _FakeConnectivityCheck(this._initial);

  bool _initial;
  final _controller = StreamController<bool>.broadcast();

  void push(bool online) => _controller.add(online);

  @override
  Future<bool> get hasConnection async => _initial;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> dispose() => _controller.close();
}

void main() {
  test('arranca online cuando hay conexión', () async {
    final fake = _FakeConnectivityCheck(true);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();
    expect(cubit.state, ConnectivityStatus.online);
    await cubit.close();
    await fake.dispose();
  });

  test('emite offline y luego online según el stream', () async {
    final fake = _FakeConnectivityCheck(true);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();

    final futuro = expectLater(
      cubit.stream,
      emitsInOrder([ConnectivityStatus.offline, ConnectivityStatus.online]),
    );

    fake.push(false);
    fake.push(true);

    await futuro;
    await cubit.close();
    await fake.dispose();
  });

  test('no re-emite si el estado no cambia', () async {
    final fake = _FakeConnectivityCheck(false);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();
    expect(cubit.state, ConnectivityStatus.offline);

    // Empujar el mismo estado no debe producir una nueva emisión.
    final emissions = <ConnectivityStatus>[];
    final sub = cubit.stream.listen(emissions.add);
    fake.push(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(emissions, isEmpty);

    await sub.cancel();
    await cubit.close();
    await fake.dispose();
  });
}
