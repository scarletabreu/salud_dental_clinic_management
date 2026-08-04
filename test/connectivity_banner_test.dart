import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/network/connectivity_check.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/connectivity_cubit.dart';
import 'package:salud_dental_clinic_management/shell/widgets/connectivity_banner.dart';

class _FakeConnectivityCheck implements ConnectivityCheck {
  _FakeConnectivityCheck(this._initial);

  final bool _initial;
  final _controller = StreamController<bool>.broadcast();

  void push(bool online) => _controller.add(online);

  @override
  Future<bool> get hasConnection async => _initial;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> dispose() => _controller.close();
}

Widget _wrap(ConnectivityCubit cubit) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    home: BlocProvider.value(
      value: cubit,
      child: const Scaffold(body: ConnectivityBanner()),
    ),
  );
}

void main() {
  const offlineText = 'Sin conexión — los cambios no se están sincronizando';
  const restoredText = 'Conexión restablecida';

  testWidgets('oculto al inicio con conexión', (tester) async {
    final fake = _FakeConnectivityCheck(true);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();

    await tester.pumpWidget(_wrap(cubit));
    await tester.pump();

    expect(find.text(offlineText), findsNothing);
    expect(find.text(restoredText), findsNothing);

    await cubit.close();
    await fake.dispose();
  });

  testWidgets('muestra el aviso offline al perder la red', (tester) async {
    final fake = _FakeConnectivityCheck(true);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();

    await tester.pumpWidget(_wrap(cubit));
    fake.push(false);
    await tester.pumpAndSettle();

    expect(find.text(offlineText), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await cubit.close();
    await fake.dispose();
  });

  testWidgets('al volver la red muestra "restablecida" y luego se oculta', (
    tester,
  ) async {
    final fake = _FakeConnectivityCheck(true);
    final cubit = ConnectivityCubit(fake);
    await cubit.start();

    await tester.pumpWidget(_wrap(cubit));

    // Cae la red -> aviso offline.
    fake.push(false);
    await tester.pumpAndSettle();
    expect(find.text(offlineText), findsOneWidget);

    // Vuelve la red -> confirmación verde.
    fake.push(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(restoredText), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

    // Tras el temporizador de 3s, el banner desaparece.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(restoredText), findsNothing);
    expect(find.text(offlineText), findsNothing);

    await cubit.close();
    await fake.dispose();
  });
}
