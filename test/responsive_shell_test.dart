import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';
import 'package:salud_dental_clinic_management/shell/responsive_shell_layout.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';

const _labels = [
  'Inicio',
  'Mis Citas del Día',
  'Consultas',
  'Pacientes',
  'Cuentas por Cobrar',
  'Perfiles',
  'Caja',
  'Equipos',
  'Medicinas',
  'Tratamientos',
  'Configuración',
];

List<ShellDestination> _destinations(List<String> labels) => [
  for (final label in labels)
    ShellDestination(
      icon: Icons.circle_outlined,
      selectedIcon: Icons.circle,
      label: label,
      builder: (_) => Text(label),
    ),
];

Widget _mobileShell(
  List<String> labels,
  ValueChanged<int> onSelect, {
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: ShellMobileNavigation(
        destinations: _destinations(labels),
        selectedIndex: 0,
        onDestinationSelected: onSelect,
      ),
    ),
  );
}

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

      await tester.pumpWidget(_mobileShell(_labels, (_) {}));

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

  testWidgets('mobile exposes every administrator module through Más', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var selected = -1;

    await tester.pumpWidget(_mobileShell(_labels, (index) => selected = index));
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Perfiles'), findsNothing);

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    for (final label in _labels.skip(3)) {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();
    expect(selected, _labels.indexOf('Configuración'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile navigation remains usable with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_mobileShell(_labels, (_) {}, textScale: 2));
    expect(find.text('Más'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('permissions expose exactly the modules permitted by each role', () {
    final admin = _labels
        .where(
          (label) => ShellDestinationAccess.allows(label, [RolUsuario.admin]),
        )
        .toList();
    final doctor = _labels
        .where(
          (label) => ShellDestinationAccess.allows(label, [RolUsuario.doctor]),
        )
        .toList();
    final assistant = _labels
        .where(
          (label) =>
              ShellDestinationAccess.allows(label, [RolUsuario.asistente]),
        )
        .toList();

    expect(admin, _labels);
    expect(doctor, [
      'Inicio',
      'Mis Citas del Día',
      'Consultas',
      'Pacientes',
      'Cuentas por Cobrar',
      'Medicinas',
      'Tratamientos',
      'Configuración',
    ]);
    expect(assistant, [
      'Inicio',
      'Mis Citas del Día',
      'Pacientes',
      'Cuentas por Cobrar',
      'Caja',
      'Configuración',
    ]);
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
