import 'package:equatable/equatable.dart';

/// Implementa [Exception] para que los `catch`/`on Exception catch` existentes
/// capturen los Failures que lanza `runGuarded`. `toString` devuelve el mensaje
/// para que la depuración y cualquier inspección heredada sean legibles.
abstract class Failure extends Equatable implements Exception {
  final String message;

  const Failure([this.message = 'Ha ocurrido un error inesperado']);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error en el servidor']);
}

/// Fallo de conectividad: no hay internet o el backend no respondió a tiempo.
/// Su mensaje es fijo y apto para mostrarse tal cual al usuario.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
  ]);
}

/// Caso particular de [NetworkFailure] para cuando la petición sí salió pero
/// venció el tiempo de espera. Se mapea igual que un fallo de red en la UI.
class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure([
    super.message = 'La conexión tardó demasiado. Inténtalo de nuevo.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error al acceder a los datos locales']);
}
