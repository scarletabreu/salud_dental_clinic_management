import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart'
    as cuenta_enums;
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/presentation/pages/recibo_pago_page.dart';
import 'package:salud_dental_clinic_management/features/pago/presentation/pdf/recibo_pdf.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';

Pago _pago(String id, double monto, DateTime fecha) => Pago(
  id: id,
  cuentaId: 'cuenta-1',
  monto: monto,
  fecha: fecha,
  estado: EstadoPago.completado,
  metodoPago: MetodoPago.transferenciaBancaria,
);

ReciboPago _recibo() {
  final pagoAnterior = _pago('pago-anterior', 300, DateTime(2026, 7, 18, 9));
  final pagoActual = _pago(
    '12345678-abcd-efgh-ijkl-123456789012',
    400,
    DateTime(2026, 7, 20, 14, 30),
  );
  final pagoPosterior = _pago('pago-posterior', 300, DateTime(2026, 7, 22, 10));
  final cuenta = Cuenta(
    id: 'cuenta-1',
    consultaId: 'consulta-12345678',
    fechaCreacion: DateTime(2026, 7, 18),
    metodoPago: cuenta_enums.MetodoPago.credito,
    pagos: [pagoAnterior, pagoActual, pagoPosterior],
    itemCuentas: [
      ItemCuenta(
        cuentaId: 'cuenta-1',
        descripcion: 'Limpieza dental',
        precioUnitario: 600,
        cantidad: 1,
      ),
      ItemCuenta(
        cuentaId: 'cuenta-1',
        descripcion: 'Radiografía periapical',
        precioUnitario: 200,
        cantidad: 2,
      ),
    ],
  );
  final consulta = Consulta(
    id: 'consulta-12345678',
    pacienteId: 'paciente-1',
    doctorId: 'doctor-1',
    fecha: DateTime(2026, 7, 18),
    finalizada: true,
  );
  final paciente = Paciente(
    id: 'paciente-1',
    nombre: 'María',
    apellido: 'Santos',
    birthDate: DateTime(1990, 2, 3),
    govID: '001-1234567-8',
    contactos: [
      ContactoModel(
        id: 'contacto-1',
        email: 'maria@example.com',
        numeroTelefono: '809-555-0101',
        direccion: 'Santo Domingo',
      ),
    ],
    estatus: EstatusPersona.activo,
    genero: Genero.femenino,
    record: RecordModel.empty(),
    trabajo: '',
    referencia: '',
    citas: const [],
    tipoPaciente: TipoPaciente.integrado,
  );
  return ReciboPago(
    cuenta: cuenta,
    pago: pagoActual,
    consulta: consulta,
    paciente: paciente,
  );
}

void main() {
  group('ReciboPago', () {
    test('calcula el estado financiero al momento del pago', () {
      final recibo = _recibo();

      expect(recibo.numero, '12345678');
      expect(recibo.pagadoAntes, 300);
      expect(recibo.saldoDespues, 300);
      expect(recibo.nombreArchivo, 'recibo-12345678.pdf');
    });

    test('genera un PDF válido con contenido', () async {
      final bytes = await generarReciboPdf(_recibo());

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  testWidgets('muestra los datos requeridos y acciones de entrega', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReciboPagoPage(recibo: _recibo()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salud Dental'), findsOneWidget);
    expect(find.text('María Santos'), findsOneWidget);
    expect(find.text('Limpieza dental'), findsOneWidget);
    expect(find.text('Transferencia Bancaria'), findsOneWidget);
    expect(find.byKey(const Key('monto_pago_recibo')), findsOneWidget);
    expect(find.byKey(const Key('guardar_pdf_button')), findsOneWidget);
    expect(find.byKey(const Key('imprimir_recibo_button')), findsOneWidget);
    expect(find.textContaining('No constituye factura'), findsOneWidget);
  });

  testWidgets('se adapta a una ventana angosta sin desbordarse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReciboPagoPage(recibo: _recibo()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recibo_documento')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
