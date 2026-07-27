import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_state.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/equipo_list_page.dart';
import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/domain/entities/equipo_mantenimiento.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_cubit.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_state.dart';

class _EquipoCubitDoble extends Cubit<EquipoState> implements EquipoCubit {
  _EquipoCubitDoble(Equipo equipo)
    : super(EquipoLoaded(todos: [equipo], filtrados: [equipo]));

  EquipoMantenimiento? mantenimientoRegistrado;

  @override
  Future<void> cargarEquipos() async {}

  @override
  Future<bool> registrarMantenimiento(EquipoMantenimiento mantenimiento) async {
    mantenimientoRegistrado = mantenimiento;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SuplidorCubitDoble extends Cubit<SuplidorState>
    implements SuplidorCubit {
  _SuplidorCubitDoble(List<Suplidor> suplidores)
    : super(SuplidorLoaded(suplidores: suplidores));

  @override
  Future<void> cargar() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('registra un mantenimiento desde el inventario de equipos', (
    tester,
  ) async {
    final equipo = Equipo(
      id: 'b7e1a6b0-6225-4ac2-b4cf-f4f68e700001',
      nombre: 'Autoclave',
      descripcion: 'Esterilizador',
      ultimoMantenimiento: DateTime(2026, 1, 1),
      tiempoParaMantenimiento: 90,
    );
    final equipoCubit = _EquipoCubitDoble(equipo);
    final suplidor = Suplidor(
      id: 'a7e1a6b0-6225-4ac2-b4cf-f4f68e700001',
      nombre: 'Proveedor validado',
      tipoSuplidor: TipoSuplidor.servicio,
      contactos: const <Contacto>[],
      summary: 'Servicio técnico',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<EquipoCubit>.value(value: equipoCubit),
            BlocProvider<SuplidorCubit>(
              create: (_) => _SuplidorCubitDoble([suplidor]),
            ),
          ],
          child: const EquipoListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Registrar mantenimiento'));
    await tester.pumpAndSettle();

    expect(find.text('Mantenimiento · Autoclave'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proveedor validado').last);
    await tester.enterText(find.byType(TextFormField).first, '1250,50');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();

    expect(equipoCubit.mantenimientoRegistrado, isNotNull);
    expect(equipoCubit.mantenimientoRegistrado!.equipoId, equipo.id);
    expect(equipoCubit.mantenimientoRegistrado!.suplidorId, suplidor.id);
    expect(equipoCubit.mantenimientoRegistrado!.costo, 1250.50);
  });
}
