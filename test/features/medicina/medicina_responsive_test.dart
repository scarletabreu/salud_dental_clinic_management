import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';

class _MedicinaRepositorioFalso implements IMedicinaRepository {
  _MedicinaRepositorioFalso(this._catalogo);

  final List<Medicina> _catalogo;

  @override
  Future<List<Medicina>> getCatalogoMedicinas() async => _catalogo;

  @override
  Future<void> guardarMedicina(Medicina medicina) async {}

  @override
  Future<void> eliminarMedicina(String id) async {}

  @override
  Future<void> agregarMedicina(Medicina medicina) async {}
}

List<Medicina> _catalogo() => [
  Medicina(
    id: 'med-1',
    nombre: 'Amoxicilina con ácido clavulánico 875/125 mg',
    contraindicaciones: [
      Contraindicacion(
        id: 'c-1',
        condicionId: 'cond-1',
        medicinaId: 'med-1',
        descripcion: 'Alergia documentada a penicilinas',
        tipoContraindicacion: TipoContraindicacion.values.first,
        efectosAdversos: const [EfectoAdverso.nauseas, EfectoAdverso.fatiga],
      ),
    ],
  ),
  Medicina(
    id: 'med-2',
    nombre: 'Ibuprofeno 600 mg',
    contraindicaciones: const [],
  ),
];

Widget _app(Widget pagina, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  // En la app la página vive dentro del Scaffold del shell.
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
    testWidgets('el catálogo de medicinas se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          MedicinaListPage(repository: _MedicinaRepositorioFalso(_catalogo())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el catálogo de medicinas no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('el catálogo resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        MedicinaListPage(repository: _MedicinaRepositorioFalso(_catalogo())),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
