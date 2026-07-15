import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/errors/error_mapper.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('SocketException -> NetworkFailure', () {
      final f = mapExceptionToFailure(const SocketException('no route'));
      expect(f, isA<NetworkFailure>());
    });

    test('TimeoutException -> TimeoutFailure (es NetworkFailure)', () {
      final f = mapExceptionToFailure(TimeoutException('slow'));
      expect(f, isA<TimeoutFailure>());
      expect(f, isA<NetworkFailure>());
    });

    test('mensaje con "Failed host lookup" -> NetworkFailure (fallback string)', () {
      final f = mapExceptionToFailure(
        Exception('Error: Failed host lookup: supabase.co'),
      );
      expect(f, isA<NetworkFailure>());
    });

    test('mensaje con "Connection refused" -> NetworkFailure', () {
      final f = mapExceptionToFailure(Exception('Connection refused'));
      expect(f, isA<NetworkFailure>());
    });

    test('PostgrestException -> ServerFailure con su mensaje', () {
      final f = mapExceptionToFailure(
        PostgrestException(message: 'duplicate key'),
      );
      expect(f, isA<ServerFailure>());
      expect(f.message, contains('duplicate key'));
    });

    test('PostgrestException con context antepone "Error al <context>"', () {
      final f = mapExceptionToFailure(
        PostgrestException(message: 'boom'),
        context: 'crear la cita',
      );
      expect(f, isA<ServerFailure>());
      expect(f.message, 'Error al crear la cita: boom');
    });

    test('excepción desconocida -> ServerFailure genérico', () {
      final f = mapExceptionToFailure(Exception('algo raro'));
      expect(f, isA<ServerFailure>());
    });

    test('un Failure ya tipado pasa tal cual (sin re-envolver)', () {
      const original = NetworkFailure();
      final f = mapExceptionToFailure(original);
      expect(identical(f, original), isTrue);
    });
  });
}
