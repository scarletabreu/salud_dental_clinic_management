import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failures.dart';

/// Traduce cualquier excepción a un [Failure] tipado. Es el ÚNICO lugar del
/// código donde se decide si un error es de red o de servidor: los repositorios
/// lo usan a través del guard y ningún cubit debe volver a inspeccionar strings.
Failure mapExceptionToFailure(Object error, {String? context}) {
  // 1. Fallos de red evidentes por su tipo.
  if (error is SocketException || error is TimeoutException) {
    return error is TimeoutException
        ? const TimeoutFailure()
        : const NetworkFailure();
  }

  // Supabase (gotrue) lanza esto cuando el fetch de auth falla por red.
  if (error is AuthRetryableFetchException) {
    return const NetworkFailure();
  }

  // http.ClientException indica un fallo de transporte. Se reconoce por nombre
  // para no depender del paquete http directamente.
  if (error.runtimeType.toString() == 'ClientException') {
    return const NetworkFailure();
  }

  // 2. Fallback por string: SOLO aquí, nunca en cubits. Cubre excepciones
  // genéricas cuyo mensaje delata un problema de red subyacente.
  final text = error.toString().toLowerCase();
  if (_networkMarkers.any(text.contains)) {
    return const NetworkFailure();
  }

  // 3. Excepciones tipadas de Supabase → error de servidor con su mensaje limpio.
  if (error is PostgrestException) {
    return ServerFailure(_serverMessage(context, error.message));
  }
  if (error is StorageException) {
    return ServerFailure(_serverMessage(context, error.message));
  }
  if (error is AuthException) {
    return ServerFailure(_serverMessage(context, error.message));
  }

  // 4. Cualquier otra cosa: error de servidor genérico.
  return ServerFailure(_serverMessage(context, null));
}

const _networkMarkers = [
  'failed host lookup',
  'connection refused',
  'connection reset',
  'connection closed',
  'network is unreachable',
  'software caused connection abort',
  'connection timed out',
  'no address associated with hostname',
];

String _serverMessage(String? context, String? detail) {
  final base = context != null ? 'Error al $context' : 'Error en el servidor';
  if (detail != null && detail.isNotEmpty) return '$base: $detail';
  return base;
}
