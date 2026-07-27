import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/cuentas_por_cobrar_page.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class _ConsultasListCubitDoble extends Cubit<ConsultasListState>
    implements ConsultasListCubit {
  _ConsultasListCubitDoble(super.initialState);

  @override
  Future<void> recargar() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CuentasCubitDoble extends Cubit<CuentasPorCobrarState>
    implements CuentasPorCobrarCubit {
  _CuentasCubitDoble(super.initialState);

  @override
  Future<void> cargarCuentas() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Doctor _doctor() => Doctor(
  id: 'doc-1',
  nombre: 'Bartolomé',
  apellido: 'Santana Villalona',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'b.santana@clinica.do',
      direccion: 'Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  passwordHash: 'x',
  specialty: 'Endodoncia',
  assistants: const [],
);

ConsultasLoaded _consultas() {
  final lista = [
    Consulta(
      id: 'con-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      fecha: DateTime(2026, 7, 21, 10, 30),
      finalizada: true,
      motivoConsulta: 'Dolor en el segundo molar inferior derecho',
    ),
    Consulta(
      id: 'con-2',
      pacienteId: 'pac-2',
      doctorId: 'doc-1',
      fecha: DateTime(2026, 7, 22, 9),
      motivoConsulta: 'Revisión de ortodoncia',
    ),
  ];
  return ConsultasLoaded(
    todas: lista,
    filtradas: lista,
    pacienteNombres: const {
      'pac-1': 'Ana Mercedes Rodríguez Montás',
      'pac-2': 'Juan Carlos De la Cruz Peralta',
    },
    doctorNombres: const {'doc-1': 'Bartolomé Santana Villalona'},
    doctores: [_doctor()],
  );
}

CuentasPorCobrarLoaded _cuentas() {
  final lista = [
    Cuenta(
      id: 'cta-1',
      consultaId: 'con-1',
      fechaCreacion: DateTime(2026, 7, 20),
      metodoPago: MetodoPago.credito,
      estado: EstadoCuenta.pendiente,
      itemCuentas: [
        ItemCuenta(
          cuentaId: 'cta-1',
          descripcion: 'Endodoncia multirradicular con corona',
          precioUnitario: 18500,
          cantidad: 2,
        ),
      ],
    ),
  ];
  return CuentasPorCobrarLoaded(
    todas: lista,
    filtradas: lista,
    totalPorCobrar: 37000,
    totalCobrado: 12000,
  );
}

Widget _app(Widget pagina, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  // En la app estas páginas viven dentro del Scaffold del shell.
  home: Scaffold(body: pagina),
);

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
  _viewports.forEach((nombre, tamano) {
    testWidgets('el listado de consultas se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          BlocProvider<ConsultasListCubit>(
            create: (_) => _ConsultasListCubitDoble(_consultas()),
            child: const ConsultasListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el listado de consultas no debe desbordar en $nombre',
      );
    });

    testWidgets('las cuentas por cobrar se leen en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          BlocProvider<CuentasPorCobrarCubit>(
            create: (_) => _CuentasCubitDoble(_cuentas()),
            child: const CuentasPorCobrarPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'las cuentas por cobrar no deben desbordar en $nombre',
      );
    });
  });

  testWidgets('el listado de consultas resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        BlocProvider<ConsultasListCubit>(
          create: (_) => _ConsultasListCubitDoble(_consultas()),
          child: const ConsultasListPage(),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('actualizar listado queda anclado al borde derecho', (
    tester,
  ) async {
    _viewport(tester, const Size(1280, 900));
    await tester.pumpWidget(
      _app(
        BlocProvider<ConsultasListCubit>(
          create: (_) => _ConsultasListCubitDoble(_consultas()),
          child: const ConsultasListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refresh = tester.getRect(
      find.byKey(ConsultasListPage.refreshButtonKey),
    );
    expect(1280 - refresh.right, closeTo(28, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('las cuentas por cobrar resisten el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        BlocProvider<CuentasPorCobrarCubit>(
          create: (_) => _CuentasCubitDoble(_cuentas()),
          child: const CuentasPorCobrarPage(),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
