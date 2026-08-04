import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';

void main() {
  tearDown(() => guardConnectivityCheck = null);

  group('guard (Either)', () {
    test('éxito -> Right', () async {
      final result = await guard(() async => 42);
      expect(result, const Right<Failure, int>(42));
    });

    test('SocketException -> Left(NetworkFailure)', () async {
      final result = await guard<int>(
        () async => throw const SocketException('down'),
      );
      expect(result.isLeft(), isTrue);
      result.fold((l) => expect(l, isA<NetworkFailure>()), (_) => fail('esperaba Left'));
    });

    test('timeout -> Left(NetworkFailure)', () async {
      final result = await guard<int>(
        () => Future.delayed(const Duration(seconds: 1), () => 1),
        timeout: const Duration(milliseconds: 10),
      );
      result.fold((l) => expect(l, isA<NetworkFailure>()), (_) => fail('esperaba Left'));
    });

    test('sin conexión (check falso) -> fail-fast sin ejecutar la acción', () async {
      guardConnectivityCheck = () async => false;
      var ejecutada = false;
      final result = await guard<int>(() async {
        ejecutada = true;
        return 1;
      });
      expect(ejecutada, isFalse);
      result.fold((l) => expect(l, isA<NetworkFailure>()), (_) => fail('esperaba Left'));
    });

    test('void compila y devuelve Right', () async {
      final result = await guard<void>(() async {});
      expect(result.isRight(), isTrue);
    });
  });

  group('runGuarded (lanza Failure)', () {
    test('éxito devuelve el valor', () async {
      expect(await runGuarded(() async => 'ok'), 'ok');
    });

    test('SocketException -> lanza NetworkFailure', () async {
      expect(
        () => runGuarded<int>(() async => throw const SocketException('down')),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('sin conexión -> lanza NetworkFailure sin ejecutar la acción', () async {
      guardConnectivityCheck = () async => false;
      var ejecutada = false;
      await expectLater(
        () => runGuarded<int>(() async {
          ejecutada = true;
          return 1;
        }),
        throwsA(isA<NetworkFailure>()),
      );
      expect(ejecutada, isFalse);
    });
  });
}
