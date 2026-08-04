import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/pre_factura_page.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// Cobrar es de caja, y la pantalla tiene que decirlo antes, no después.
///
/// El doctor llegaba a la pre-factura de la consulta que acababa de cerrar,
/// pulsaba «Registrar Cobro / Pago», tecleaba el monto y sólo entonces la base
/// le respondía «Capacidad de caja requerida» (`registrar_pago`, errcode
/// 42501). La regla es correcta —la matriz de HFX-CLIN-000 da la caja al admin
/// y a la asistente— pero el rechazo llegaba al final del camino.
///
/// «Ajustar» no entra en esta regla: toca el resultado clínico facturado y es
/// de quien lo firmó.
void main() {
  tearDown(() {
    if (sl.isRegistered<PreFacturaCubit>()) sl.unregister<PreFacturaCubit>();
  });

  testWidgets('el doctor no recibe el botón de cobro, y se le explica', (
    tester,
  ) async {
    _viewport(tester);
    await tester.pumpWidget(_app(usuario: _doctor));
    await tester.pumpAndSettle();

    expect(find.text('Registrar Cobro / Pago'), findsNothing);
    expect(find.text('Plan de cuotas'), findsNothing);
    expect(
      find.textContaining('El cobro lo registra caja'),
      findsOneWidget,
      reason:
          'esconder el botón sin explicar deja al doctor sin saber qué pasa',
    );
    expect(
      find.text('Ajustar'),
      findsOneWidget,
      reason: 'ajustar lo facturado sigue siendo de quien ejerce',
    );
  });

  testWidgets('quien lleva la caja sí cobra', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_app(usuario: _admin));
    await tester.pumpAndSettle();

    expect(find.text('Registrar Cobro / Pago'), findsOneWidget);
    expect(find.text('Plan de cuotas'), findsOneWidget);
    expect(find.textContaining('El cobro lo registra caja'), findsNothing);
  });
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app({required Usuario usuario}) {
  if (sl.isRegistered<PreFacturaCubit>()) sl.unregister<PreFacturaCubit>();
  sl.registerFactory<PreFacturaCubit>(
    () => _PreFacturaCubitDoble(PreFacturaCargada(_cuenta)),
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<AuthCubit>(
      create: (_) =>
          _AuthCubitDoble(AuthState(isAuthenticated: true, usuario: usuario)),
      child: const PreFacturaPage(cuentaId: 'cuenta-1'),
    ),
  );
}

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

class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _cuenta = Cuenta(
  id: 'cuenta-1',
  consultaId: 'consulta-1',
  fechaCreacion: DateTime(2026, 8, 1),
  metodoPago: MetodoPago.contado,
  estado: EstadoCuenta.abierta,
  itemCuentas: [
    ItemCuenta(
      cuentaId: 'cuenta-1',
      descripcion: 'Endodoncia',
      precioUnitario: 35000,
      cantidad: 1,
    ),
  ],
  pagos: const [],
);

final _doctor = Doctor(
  id: 'doctor-1',
  nombre: 'Gregory',
  apellido: 'House',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: 'ghouse',
  specialty: 'General',
  assistants: const [],
);

final _admin = Admin(
  id: 'admin-1',
  nombre: 'Alma',
  apellido: 'Dirección',
  birthDate: DateTime(1978, 4, 12),
  govID: '402-7654321-9',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: 'alma',
  specialty: 'General',
  assistants: const [],
  departamento: 'Dirección',
);
