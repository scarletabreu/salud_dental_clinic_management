import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/repositories/auditoria_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consulta_detalle_page.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';

/// Desde la consulta se llega a su cuenta.
///
/// El detalle de cuenta sólo se alcanzaba desde la ficha del paciente: para ver
/// qué se le facturó a la consulta que se estaba mirando había que salir,
/// buscar al paciente y volver a entrar. El acceso aparece únicamente cuando la
/// consulta tiene pre-factura; sin cuenta que abrir, un botón sería una
/// promesa falsa.
void main() {
  tearDown(() {
    if (sl.isRegistered<ConsultaDetalleCubit>()) {
      sl.unregister<ConsultaDetalleCubit>();
    }
    if (sl.isRegistered<PacienteCubit>()) sl.unregister<PacienteCubit>();
    if (sl.isRegistered<CuentaRepository>()) sl.unregister<CuentaRepository>();
    if (sl.isRegistered<PreFacturaCubit>()) sl.unregister<PreFacturaCubit>();
    if (sl.isRegistered<AuditoriaRepository>()) {
      sl.unregister<AuditoriaRepository>();
    }
  });

  testWidgets('la consulta facturada ofrece abrir su cuenta', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_app(facturada: true));
    await tester.pumpAndSettle();

    final boton = find.byKey(const Key('abrir_cuenta_de_la_consulta'));
    expect(boton, findsOneWidget);
    expect(find.text('Ver detalle de la cuenta'), findsOneWidget);
  });

  testWidgets('sin pre-factura no se ofrece cuenta que abrir', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_app(facturada: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('abrir_cuenta_de_la_consulta')), findsNothing);
  });

  testWidgets('pulsar busca la cuenta de esa consulta y no otra', (
    tester,
  ) async {
    _viewport(tester);
    final repositorio = _CuentaRepositorioDoble();
    await tester.pumpWidget(_app(facturada: true, repositorio: repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('abrir_cuenta_de_la_consulta')));
    // Sin `pumpAndSettle`: la pre-factura a la que se navega tiene su propio
    // indicador de carga girando, y esperar a que todo se asiente no termina.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repositorio.consultasPedidas, [_consultaId]);
  });
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _consultaId = '55555555-5555-5555-5555-555555555555';

Widget _app({required bool facturada, _CuentaRepositorioDoble? repositorio}) {
  if (sl.isRegistered<ConsultaDetalleCubit>()) {
    sl.unregister<ConsultaDetalleCubit>();
  }
  sl.registerFactory<ConsultaDetalleCubit>(
    () => _ConsultaDetalleCubitDoble(const ConsultaDetalleListo()),
  );

  if (sl.isRegistered<PacienteCubit>()) sl.unregister<PacienteCubit>();
  sl.registerFactory<PacienteCubit>(_PacienteCubitDoble.new);

  if (sl.isRegistered<CuentaRepository>()) sl.unregister<CuentaRepository>();
  final doble = repositorio ?? _CuentaRepositorioDoble();
  sl.registerFactory<CuentaRepository>(() => doble);

  // La línea de tiempo de la consulta cuelga de esta pantalla.
  if (sl.isRegistered<AuditoriaRepository>()) {
    sl.unregister<AuditoriaRepository>();
  }
  sl.registerFactory<AuditoriaRepository>(_AuditoriaRepositorioDoble.new);

  // Al pulsar se navega de verdad a la pre-factura, así que necesita su cubit.
  if (sl.isRegistered<PreFacturaCubit>()) sl.unregister<PreFacturaCubit>();
  sl.registerFactory<PreFacturaCubit>(
    () =>
        _PreFacturaCubitDoble(const PreFacturaError('sin datos en la prueba')),
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: ConsultaDetallePage(
      consulta: Consulta(
        id: _consultaId,
        pacienteId: '11111111-1111-1111-1111-111111111111',
        doctorId: '22222222-2222-2222-2222-222222222222',
        fecha: DateTime(2026, 8, 1, 10),
        finalizada: true,
        tienePreFactura: facturada,
      ),
      nombrePaciente: 'Ana Rodríguez',
      nombreDoctor: 'Gregory House',
    ),
  );
}

class _ConsultaDetalleCubitDoble extends Cubit<ConsultaDetalleState>
    implements ConsultaDetalleCubit {
  _ConsultaDetalleCubitDoble(super.initialState);

  @override
  Future<void> cargar(Consulta consulta) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PacienteCubitDoble extends Cubit<PacienteState>
    implements PacienteCubit {
  _PacienteCubitDoble() : super(const PacienteLoading());

  @override
  Future<void> loadById(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PreFacturaCubitDoble extends Cubit<PreFacturaState>
    implements PreFacturaCubit {
  _PreFacturaCubitDoble(super.initialState);

  @override
  Future<void> cargar(String cuentaId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _AuditoriaRepositorioDoble implements AuditoriaRepository {
  @override
  Future<List<EventoAuditoria>> getLineaTiempo(String consultaId) async =>
      const [];
}

class _CuentaRepositorioDoble implements CuentaRepository {
  final List<String> consultasPedidas = [];

  @override
  Future<Cuenta?> getCuentaByConsultaId(String consultaId) async {
    consultasPedidas.add(consultaId);
    return Cuenta(
      id: 'cuenta-1',
      consultaId: consultaId,
      fechaCreacion: DateTime(2026, 8, 1),
      metodoPago: MetodoPago.contado,
      estado: EstadoCuenta.abierta,
      itemCuentas: const [],
      pagos: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
