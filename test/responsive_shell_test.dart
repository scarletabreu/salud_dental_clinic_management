import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';
import 'package:salud_dental_clinic_management/shell/responsive_shell_layout.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';

const _ids = ShellDestinationId.values;

List<ShellDestination> _destinations(List<ShellDestinationId> ids) => [
  for (final id in ids)
    ShellDestination(
      id: id,
      icon: Icons.circle_outlined,
      selectedIcon: Icons.circle,
      label: id.name,
      builder: (_) => Text(id.name),
    ),
];

Widget _mobileShell(
  List<ShellDestinationId> ids,
  ValueChanged<int> onSelect, {
  double textScale = 1,
  ValueChanged<ShellDestinationId>? onNavigateTo,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: ShellMobileNavigation(
        destinations: _destinations(ids),
        primaryDestinations: _destinations(ids.take(4).toList()),
        selectedIndex: 0,
        onDestinationSelected: onSelect,
        onNavigateTo: onNavigateTo ?? (_) {},
      ),
    ),
  );
}

/// Opacidad del panel de módulos secundarios: 0 cerrado, 1 abierto.
double _opacidadDelMenu(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.text(ShellDestinationId.perfiles.name),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  final sizes = <double, ShellLayout>{
    320: ShellLayout.narrowMobile,
    360: ShellLayout.mobile,
    390: ShellLayout.mobile,
    600: ShellLayout.tablet,
    768: ShellLayout.tablet,
    1024: ShellLayout.desktop,
  };

  for (final entry in sizes.entries) {
    testWidgets('shell policy is stable at ${entry.key.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(entry.key, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_mobileShell(_ids, (_) {}));

      expect(
        ShellLayoutResolution.of(
          MediaQuery.of(tester.element(find.byType(Scaffold))),
        ).name,
        entry.value.name,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'no navigation overflow at this width',
      );
    });
  }

  testWidgets('mobile exposes every secondary module through «Más módulos»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navegados = <ShellDestinationId>[];

    await tester.pumpWidget(
      _mobileShell(_ids, (_) {}, onNavigateTo: navegados.add),
    );

    // Los cuatro primarios viven en la barra; el resto está montado pero
    // invisible hasta abrir el menú.
    expect(_opacidadDelMenu(tester), 0);

    await tester.tap(find.bySemanticsLabel('Más módulos'));
    await tester.pumpAndSettle();
    expect(_opacidadDelMenu(tester), 1);

    for (final id in _ids.skip(4)) {
      await tester.scrollUntilVisible(
        find.text(id.name),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(id.name), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.text(ShellDestinationId.configuracion.name),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(ShellDestinationId.configuracion.name));
    await tester.pumpAndSettle();
    expect(navegados, [ShellDestinationId.configuracion]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile navigation remains usable with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_mobileShell(_ids, (_) {}, textScale: 2));
    expect(find.bySemanticsLabel('Más módulos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile navigation uses the sidebar visual language', (
    tester,
  ) async {
    await tester.pumpWidget(_mobileShell(_ids, (_) {}));

    final verde = AppTheme.light.extension<AppColors>()!.primaryGreen;
    final itemDecorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>();

    // La barra no es un `NavigationBar` de serie: es una píldora redondeada
    // con el verde de la marca, igual que el rail de escritorio.
    expect(
      itemDecorations.any(
        (decoration) =>
            decoration.color == verde && decoration.borderRadius != null,
      ),
      isTrue,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('permissions expose exactly the modules permitted by each role', () {
    final admin = _ids
        .where((id) => ShellDestinationAccess.allows(id, [RolUsuario.admin]))
        .toList();
    final doctor = _ids
        .where((id) => ShellDestinationAccess.allows(id, [RolUsuario.doctor]))
        .toList();
    final assistant = _ids
        .where(
          (id) => ShellDestinationAccess.allows(id, [RolUsuario.asistente]),
        )
        .toList();

    expect(admin, _ids);
    // Matriz fijada por la jornada de QA del 1 ago 2026: el doctor no lleva
    // dinero (Caja, Cuentas por Cobrar) ni administra personal (Perfiles).
    // Los catálogos sí los ve —los necesita para trabajar—, pero sin botones
    // de edición ni precios; eso lo comprueban las pruebas de catálogo.
    expect(doctor, [
      ShellDestinationId.inicio,
      ShellDestinationId.citasDelDia,
      ShellDestinationId.consultas,
      ShellDestinationId.pacientes,
      ShellDestinationId.tratamientos,
      ShellDestinationId.procedimientos,
      ShellDestinationId.diagnosticos,
      ShellDestinationId.medicinas,
      ShellDestinationId.inventario,
      ShellDestinationId.equipos,
      ShellDestinationId.configuracion,
    ]);
    expect(
      doctor,
      isNot(contains(ShellDestinationId.caja)),
      reason: 'gestionar caja no es capacidad clínica',
    );
    expect(
      doctor,
      isNot(contains(ShellDestinationId.cuentasPorCobrar)),
      reason: 'cobrar es de quien lleva la caja (defecto D9)',
    );
    expect(
      doctor,
      isNot(contains(ShellDestinationId.perfiles)),
      reason: 'administrar personal es capacidad sólo del admin (defecto D9)',
    );
    expect(assistant, [
      ShellDestinationId.inicio,
      ShellDestinationId.citasDelDia,
      ShellDestinationId.pacientes,
      ShellDestinationId.cuentasPorCobrar,
      ShellDestinationId.caja,
      ShellDestinationId.configuracion,
    ]);
  });

  test('renaming a destination label does not change its permissions', () {
    final renamed = ShellDestination(
      id: ShellDestinationId.consultas,
      icon: Icons.circle_outlined,
      selectedIcon: Icons.circle,
      label: 'Clinical workspace',
      builder: (_) => const SizedBox.shrink(),
    );

    expect(
      ShellDestinationAccess.allows(renamed.id, [RolUsuario.doctor]),
      isTrue,
    );
    expect(
      ShellDestinationAccess.allows(renamed.id, [RolUsuario.asistente]),
      isFalse,
    );
  });

  test('each role sees only non-empty work sections in role order', () {
    final sections = [
      ShellSection(
        title: 'Atención',
        destinations: _destinations(const [
          ShellDestinationId.inicio,
          ShellDestinationId.citasDelDia,
          ShellDestinationId.consultas,
          ShellDestinationId.pacientes,
        ]),
      ),
      ShellSection(
        title: 'Facturación',
        destinations: _destinations(const [
          ShellDestinationId.cuentasPorCobrar,
          ShellDestinationId.caja,
        ]),
      ),
      ShellSection(
        title: 'Catálogos',
        destinations: _destinations(const [
          ShellDestinationId.tratamientos,
          ShellDestinationId.medicinas,
          ShellDestinationId.inventario,
        ]),
      ),
      ShellSection(
        title: 'Administración',
        destinations: _destinations(const [
          ShellDestinationId.perfiles,
          ShellDestinationId.equipos,
        ]),
      ),
    ];

    List<List<ShellDestinationId>> visibleFor(RolUsuario role) =>
        ShellDestinationAccess.visibleSections(sections, [role])
            .map(
              (section) => section.destinations.map((item) => item.id).toList(),
            )
            .toList();

    expect(visibleFor(RolUsuario.admin), [
      [
        ShellDestinationId.inicio,
        ShellDestinationId.citasDelDia,
        ShellDestinationId.consultas,
        ShellDestinationId.pacientes,
      ],
      [ShellDestinationId.cuentasPorCobrar, ShellDestinationId.caja],
      [
        ShellDestinationId.tratamientos,
        ShellDestinationId.medicinas,
        ShellDestinationId.inventario,
      ],
      [ShellDestinationId.perfiles, ShellDestinationId.equipos],
    ]);
    // Al doctor le desaparece la sección de Facturación entera: no ve
    // Cuentas por Cobrar ni Caja (defecto D9). Y Administración le queda sólo
    // con Equipos, porque Perfiles es del admin.
    expect(visibleFor(RolUsuario.doctor), [
      [
        ShellDestinationId.inicio,
        ShellDestinationId.citasDelDia,
        ShellDestinationId.consultas,
        ShellDestinationId.pacientes,
      ],
      [
        ShellDestinationId.tratamientos,
        ShellDestinationId.medicinas,
        ShellDestinationId.inventario,
      ],
      [ShellDestinationId.equipos],
    ]);
    expect(visibleFor(RolUsuario.asistente), [
      [
        ShellDestinationId.citasDelDia,
        ShellDestinationId.inicio,
        ShellDestinationId.pacientes,
      ],
      [ShellDestinationId.cuentasPorCobrar, ShellDestinationId.caja],
    ]);

    for (final role in RolUsuario.values) {
      expect(
        ShellDestinationAccess.visibleSections(sections, [role]),
        everyElement(
          predicate<ShellSection>((section) => section.destinations.isNotEmpty),
        ),
      );
    }
  });

  test('landscape and keyboard remain compact', () {
    expect(
      ShellLayoutResolution.of(
        const MediaQueryData(size: Size(800, 390)),
      ).usesBottomNavigation,
      isTrue,
    );
    expect(
      ShellLayoutResolution.of(
        const MediaQueryData(
          size: Size(1024, 800),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ).usesBottomNavigation,
      isTrue,
    );
  });
}
