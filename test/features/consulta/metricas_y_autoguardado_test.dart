import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/metricas_clinicas.dart';

void main() {
  setUp(MetricasClinicas.limpiar);
  tearDown(MetricasClinicas.limpiar);

  group('métricas', () {
    test('mide una operación correcta con su código estable', () async {
      final valor = await MetricasClinicas.medir(
        OperacionClinica.consultaGuardada,
        () async => 42,
      );

      expect(valor, 42);
      final medicion = MetricasClinicas.historial.single;
      expect(medicion.operacion.codigo, 'consulta.guardar');
      expect(medicion.resultado, ResultadoOperacion.ok);
      expect(medicion.codigo, isNull);
    });

    test('un fallo se registra por código y relanza', () async {
      await expectLater(
        MetricasClinicas.medir(
          OperacionClinica.consultaCerrada,
          () async => throw const StockInsuficienteFailure(
            'Stock insuficiente de Gasas: quedan 1 y la consulta consume 3.',
          ),
          codigoDeError: (e) =>
              e is StockInsuficienteFailure ? 'STOCK_INSUFICIENTE' : null,
        ),
        throwsA(isA<StockInsuficienteFailure>()),
      );

      final medicion = MetricasClinicas.historial.single;
      expect(medicion.resultado, ResultadoOperacion.fallo);
      expect(medicion.codigo, 'STOCK_INSUFICIENTE');
    });

    test('la medición no tiene dónde guardar datos del paciente', () {
      // El contrato es negativo por construcción: si el texto de un fallo
      // llevara el nombre de un insumo o de un paciente, no hay campo donde
      // pudiera acabar. Lo comprobamos sobre lo que se escribe realmente.
      MetricasClinicas.registrar(
        const MedicionClinica(
          operacion: OperacionClinica.consultaGuardada,
          duracion: Duration(milliseconds: 120),
          resultado: ResultadoOperacion.fallo,
          codigo: 'CL014',
          bytesPayload: 4096,
          solicitudes: 1,
        ),
      );

      final linea = MetricasClinicas.historial.single.toString();
      expect(linea, contains('consulta.guardar'));
      expect(linea, contains('CL014'));
      expect(linea, contains('bytes=4096'));
      // Ni UUID, ni cédula, ni nombres: el formato sólo tiene números y
      // códigos.
      expect(
        RegExp(
          r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
        ).hasMatch(linea),
        isFalse,
      );
    });

    test('un guardado omitido se distingue de uno lento', () {
      MetricasClinicas.omitida(OperacionClinica.consultaGuardada);

      final medicion = MetricasClinicas.historial.single;
      expect(medicion.resultado, ResultadoOperacion.omitida);
      expect(medicion.solicitudes, 0);
      expect(medicion.duracion, Duration.zero);
    });

    test('el historial no crece sin límite', () {
      for (var i = 0; i < MetricasClinicas.maxHistorial + 20; i++) {
        MetricasClinicas.omitida(OperacionClinica.agendaCargada);
      }
      expect(
        MetricasClinicas.historial.length,
        MetricasClinicas.maxHistorial,
      );
    });

    test('el observador externo recibe cada medición', () {
      final vistas = <MedicionClinica>[];
      MetricasClinicas.observador = vistas.add;

      MetricasClinicas.omitida(OperacionClinica.lineaTiempoCargada);

      expect(vistas.single.operacion, OperacionClinica.lineaTiempoCargada);
    });
  });
}
