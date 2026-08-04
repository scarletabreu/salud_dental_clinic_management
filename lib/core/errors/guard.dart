import 'package:dartz/dartz.dart';

import 'error_mapper.dart';
import 'failures.dart';

/// Comprobación de conectividad opcional, inyectada desde el service locator en
/// el arranque (Fase 2). Si está presente y devuelve `false`, el guard falla
/// rápido sin esperar el timeout. Se modela como función para no acoplar el
/// guard al paquete de red y para que los tests puedan sustituirla o dejarla
/// nula.
Future<bool> Function()? guardConnectivityCheck;

/// Envuelve una llamada remota y devuelve un [Either] tipado, centralizando el
/// manejo de errores: pre-check de conectividad, timeout y mapeo de excepciones.
///
/// Reemplaza los `try/catch → Left(ServerFailure('...: $e'))` repetidos en los
/// repositorios por una sola línea: `return guard(() => datasource.metodo());`.
///
/// Para métodos `void` funciona igual (`guard<void>(...)`): dentro del genérico
/// el valor tiene tipo `T`, así que no requiere un caso especial.
Future<Either<Failure, T>> guard<T>(
  Future<T> Function() action, {
  String? context,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final check = guardConnectivityCheck;
  if (check != null && !(await check())) {
    return Left(const NetworkFailure());
  }

  try {
    return Right(await action().timeout(timeout));
  } catch (e) {
    return Left(mapExceptionToFailure(e, context: context));
  }
}

/// Variante para repositorios que devuelven `Future<T>` crudo (sin dartz) y
/// propagan el error lanzando. Aplica el mismo pre-check de conectividad,
/// timeout y mapeo, pero en vez de un [Left] **lanza** el [Failure] tipado
/// ([NetworkFailure] / [ServerFailure]). Así los cubits pueden hacer
/// `catch (e) { if (e is NetworkFailure) ... }` sin string-matching.
///
/// Envolver SOLO la llamada remota: dejar fuera las validaciones de dominio
/// (fechas, transiciones de estado) para no perder sus mensajes específicos.
Future<T> runGuarded<T>(
  Future<T> Function() action, {
  String? context,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final check = guardConnectivityCheck;
  if (check != null && !(await check())) {
    throw const NetworkFailure();
  }

  try {
    return await action().timeout(timeout);
  } catch (e) {
    throw mapExceptionToFailure(e, context: context);
  }
}
