import 'dart:async';

/// Memoria de corta duración para catálogos: listas que se consultan muchas
/// veces por sesión y cambian pocas veces al mes.
///
/// El catálogo de medicinas y el inventario se pedían a la red cada vez que se
/// montaba la sección correspondiente de la consulta. Abrir tres consultas
/// seguidas bajaba tres veces la misma lista, y en una conexión de clínica eso
/// es un formulario en blanco durante segundos.
///
/// Resuelve dos cosas distintas:
///
/// - **Vigencia.** Sirve el valor guardado mientras no pase [vigencia]. No es
///   una caché permanente a propósito: si alguien edita el catálogo desde otro
///   equipo, la copia local se corrige sola en el siguiente minuto.
/// - **Petición única.** Si llegan varias solicitudes mientras una carga está
///   en vuelo, todas esperan la misma. Sin esto, montar a la vez la sección de
///   receta y la de insumos dispara dos peticiones idénticas.
///
/// Un fallo no se guarda: si la carga lanza, la entrada se descarta para que
/// el siguiente intento vuelva a la red en lugar de heredar el error.
class CacheCatalogo {
  CacheCatalogo({this.vigencia = const Duration(minutes: 2), DateTime Function()? reloj})
    : _ahora = reloj ?? DateTime.now;

  final Duration vigencia;
  final DateTime Function() _ahora;

  final Map<String, _Entrada<Object?>> _entradas = {};

  /// Devuelve el catálogo de [clave], cargándolo con [cargar] solo si no hay
  /// copia vigente ni una carga en curso.
  Future<T> obtener<T>(String clave, Future<T> Function() cargar) {
    final entrada = _entradas[clave];

    if (entrada != null) {
      final enVuelo = entrada.enVuelo;
      if (enVuelo != null) return enVuelo as Future<T>;

      if (_ahora().difference(entrada.guardadoEn!) < vigencia) {
        return Future<T>.value(entrada.valor as T);
      }
    }

    final futuro = cargar();
    _entradas[clave] = _Entrada<Object?>(enVuelo: futuro);

    return futuro.then(
      (valor) {
        _entradas[clave] = _Entrada<Object?>(
          valor: valor,
          guardadoEn: _ahora(),
        );
        return valor;
      },
      onError: (Object e, StackTrace s) {
        _entradas.remove(clave);
        throw Error.throwWithStackTrace(e, s);
      },
    );
  }

  /// Descarta [clave]. La llama quien acaba de escribir en ese catálogo, para
  /// que el cambio se vea de inmediato y no al vencer la vigencia.
  void invalidar(String clave) => _entradas.remove(clave);

  void invalidarTodo() => _entradas.clear();
}

class _Entrada<T> {
  _Entrada({this.valor, this.guardadoEn, this.enVuelo});

  final T? valor;
  final DateTime? guardadoEn;
  final Future<T>? enVuelo;
}
