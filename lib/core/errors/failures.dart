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
    super.message =
        'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
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

/// Regla de negocio violada antes de tocar el backend (p. ej. un monto de pago
/// mayor que el saldo pendiente). Su mensaje describe la regla concreta y es
/// apto para mostrarse tal cual al usuario. A diferencia de [ServerFailure], no
/// implica un fallo remoto: la operación nunca llegó a intentarse.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Los datos no son válidos.']);
}

/// Otro actor guardó la misma consulta primero (HFX-CLIN-002, `CL001`). No se
/// escribió nada: el usuario debe recargar el estado confirmado y reintentar.
class ConflictoVersionFailure extends Failure {
  const ConflictoVersionFailure([
    super.message =
        'Otra sesión guardó esta consulta primero. Recarga para ver lo '
            'confirmado antes de volver a guardar.',
  ]);
}

/// La consulta ya está cerrada (`CL002`). Es un estado final, no un fallo
/// recuperable: la UI debe salir del workspace en vez de reintentar.
class ConsultaCerradaFailure extends Failure {
  const ConsultaCerradaFailure([
    super.message = 'Esta consulta ya fue finalizada y no admite cambios.',
  ]);
}

/// No hay inventario suficiente para el consumo declarado (`CL003`). El cierre
/// completo se revirtió: no se descontó stock ni se creó cuenta.
class StockInsuficienteFailure extends Failure {
  const StockInsuficienteFailure([
    super.message = 'No hay stock suficiente para cerrar la consulta.',
  ]);
}
