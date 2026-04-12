import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'Ha ocurrido un error inesperado']);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error en el servidor']);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'No hay conexión a internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error al acceder a los datos locales']);
}
