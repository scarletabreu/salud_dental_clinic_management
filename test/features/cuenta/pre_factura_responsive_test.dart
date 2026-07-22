import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/pre_factura_page.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_metodo;

/// La página construye su cubit desde el service locator, así que el doble se
/// inyecta ahí. Solo necesita sostener un estado: no se ejercita ninguna
/// llamada al backend.
class _PreFacturaCubitDoble extends Cubit<PreFacturaState>
    implements PreFacturaCubit {
  _PreFacturaCubitDoble(super.initialState);

  @override
  Future<void> cargar(String cuentaId) async {}

  @override
  Future<void> recargar(String cuentaId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Cuenta _cuenta({required bool conPagos, required MetodoPago metodo}) => Cuenta(
  id: 'cuenta-1',
  consultaId: 'consulta-1',
  fechaCreacion: DateTime(2026, 7, 20),
  metodoPago: metodo,
  estado: conPagos ? EstadoCuenta.pendiente : EstadoCuenta.abierta,
  itemCuentas: [
    ItemCuenta(
      cuentaId: 'cuenta-1',
      descripcion: 'Endodoncia multirradicular con reconstrucción de muñón',
      precioUnitario: 18500,
      cantidad: 2,
    ),
    ItemCuenta(
      cuentaId: 'cuenta-1',
      descripcion: 'Corona de porcelana sobre metal',
      precioUnitario: 12750.5,
      cantidad: 1,
    ),
  ],
  pagos: conPagos
      ? [
          Pago(
            id: 'pago-1',
            cuentaId: 'cuenta-1',
            monto: 20000,
            fecha: DateTime(2026, 7, 21),
            metodoPago: pago_metodo.MetodoPago.efectivo,
            estado: pago_enums.EstadoPago.completado,
          ),
        ]
      : const [],
);

List<Cuota> _cuotas() => [
  for (var i = 0; i < 4; i++)
    Cuota(
      id: 'q$i',
      cuentaId: 'cuenta-1',
      monto: 7437.63,
      fechaVencimiento: DateTime(2026, 8 + i, 20),
      estado: EstadoCuota.pendiente,
    ),
];

Widget _app(PreFacturaState estado, {double textScale = 1}) {
  if (sl.isRegistered<PreFacturaCubit>()) {
    sl.unregister<PreFacturaCubit>();
  }
  sl.registerFactory<PreFacturaCubit>(() => _PreFacturaCubitDoble(estado));

  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: inner!,
    ),
    home: const PreFacturaPage(cuentaId: 'cuenta-1'),
  );
}

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 900),
  '360 px': const Size(360, 900),
  '390 px': const Size(390, 900),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 900),
};

void main() {
  tearDown(() {
    if (sl.isRegistered<PreFacturaCubit>()) {
      sl.unregister<PreFacturaCubit>();
    }
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('el desglose al contado se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          PreFacturaCargada(
            _cuenta(conPagos: true, metodo: MetodoPago.contado),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'la pre-factura no debe desbordar en $nombre',
      );
    });

    testWidgets('el plan de crédito con cuotas se lee en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          PreFacturaCargada(
            _cuenta(conPagos: true, metodo: MetodoPago.credito),
            cuotas: _cuotas(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el plan de cuotas de la cuenta no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('la pre-factura resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        PreFacturaCargada(_cuenta(conPagos: true, metodo: MetodoPago.credito)),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
