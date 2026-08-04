import 'package:flutter/foundation.dart';

/// Qué operación se midió. Códigos estables: son lo que se correlaciona entre
/// una queja del consultorio y lo que pasó, así que no cambian aunque cambie el
/// texto de la pantalla.
enum OperacionClinica {
  agendaCargada('agenda.cargar'),
  consultaAbierta('consulta.abrir'),
  consultaGuardada('consulta.guardar'),
  consultaCerrada('consulta.cerrar'),
  lineaTiempoCargada('consulta.linea_tiempo');

  const OperacionClinica(this.codigo);

  final String codigo;
}

/// Cómo terminó. También es un código estable: `fallo:CL014` dice más que
/// cualquier frase, y no arrastra el mensaje —que sí puede llevar el nombre de
/// un medicamento o de un paciente—.
enum ResultadoOperacion { ok, fallo, conflicto, omitida }

/// Una medición. No lleva identificadores de paciente, doctor, consulta ni
/// texto clínico: sólo qué operación fue, cuánto tardó, cómo acabó y, cuando
/// existe, el código de error estable.
@immutable
class MedicionClinica {
  final OperacionClinica operacion;
  final Duration duracion;
  final ResultadoOperacion resultado;

  /// Código estable del fallo (`CL014`, `NETWORK`…). Nunca el mensaje.
  final String? codigo;

  /// Tamaño aproximado del payload enviado, en bytes. Sirve para ver crecer un
  /// autoguardado sin mirar su contenido.
  final int? bytesPayload;

  /// Solicitudes que costó la operación. Es como se detecta un N+1 sin
  /// instrumentar la red.
  final int solicitudes;

  const MedicionClinica({
    required this.operacion,
    required this.duracion,
    required this.resultado,
    this.codigo,
    this.bytesPayload,
    this.solicitudes = 1,
  });

  @override
  String toString() =>
      '${operacion.codigo} ${duracion.inMilliseconds}ms '
      '${resultado.name}${codigo == null ? '' : ':$codigo'} '
      'req=$solicitudes${bytesPayload == null ? '' : ' bytes=$bytesPayload'}';
}

/// Registro de rendimiento de las operaciones clínicas.
///
/// Existe para responder «¿por qué va lento hoy?» sin abrir un expediente. Por
/// eso su contrato es negativo antes que positivo: lo que entra aquí no puede
/// identificar a nadie. Los UUID, nombres, cédulas y notas se quedan fuera por
/// construcción —no hay ningún campo donde ponerlos— y no por acordarse de
/// redactarlos en cada llamada.
///
/// Por defecto sólo acumula en memoria y escribe en consola en depuración. El
/// destino real se enchufa con [observador] cuando exista uno.
abstract final class MetricasClinicas {
  static const maxHistorial = 100;

  static final List<MedicionClinica> _historial = [];

  /// Sumidero externo, si la app lo configura en el arranque.
  static void Function(MedicionClinica)? observador;

  static List<MedicionClinica> get historial => List.unmodifiable(_historial);

  static void registrar(MedicionClinica medicion) {
    _historial.add(medicion);
    if (_historial.length > maxHistorial) _historial.removeAt(0);
    observador?.call(medicion);
    if (kDebugMode) debugPrint('[metrica] $medicion');
  }

  /// Mide [accion] y registra el resultado, incluso si lanza.
  ///
  /// [codigoDeError] traduce la excepción a un código estable; si devuelve
  /// `null` se registra `DESCONOCIDO` antes que arriesgarse a filtrar el
  /// mensaje.
  static Future<T> medir<T>(
    OperacionClinica operacion,
    Future<T> Function() accion, {
    String? Function(Object error)? codigoDeError,
    int? bytesPayload,
    int solicitudes = 1,
  }) async {
    final reloj = Stopwatch()..start();
    try {
      final resultado = await accion();
      reloj.stop();
      registrar(
        MedicionClinica(
          operacion: operacion,
          duracion: reloj.elapsed,
          resultado: ResultadoOperacion.ok,
          bytesPayload: bytesPayload,
          solicitudes: solicitudes,
        ),
      );
      return resultado;
    } catch (error) {
      reloj.stop();
      registrar(
        MedicionClinica(
          operacion: operacion,
          duracion: reloj.elapsed,
          resultado: ResultadoOperacion.fallo,
          codigo: codigoDeError?.call(error) ?? 'DESCONOCIDO',
          bytesPayload: bytesPayload,
          solicitudes: solicitudes,
        ),
      );
      rethrow;
    }
  }

  /// Deja constancia de una operación que no llegó a salir a la red.
  ///
  /// Un autoguardado omitido porque nada cambió es información: distingue «la
  /// red va lenta» de «no había nada que mandar».
  static void omitida(OperacionClinica operacion) => registrar(
    MedicionClinica(
      operacion: operacion,
      duracion: Duration.zero,
      resultado: ResultadoOperacion.omitida,
      solicitudes: 0,
    ),
  );

  @visibleForTesting
  static void limpiar() {
    _historial.clear();
    observador = null;
  }
}
