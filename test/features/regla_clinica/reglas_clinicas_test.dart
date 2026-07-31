import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/data/models/regla_clinica_model.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/repositories/regla_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_cubit.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_state.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/widgets/editor_regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/widgets/seccion_reglas_clinicas.dart';

class _RepositorioFalso implements ReglaClinicaRepository {
  _RepositorioFalso({
    List<ReglaClinica>? reglas,
    this.fallo,
    this.falloAlPublicar,
    this.sinCambios = false,
  }) : reglas = reglas ?? [_reglaPulso()];

  List<ReglaClinica> reglas;
  final Failure? fallo;

  /// Fallo que sólo aparece al publicar: la lectura funciona, así que la
  /// pantalla está cargada cuando la base rechaza el umbral.
  final Failure? falloAlPublicar;
  final bool sinCambios;

  ReglaClinica? publicada;
  String? notaRecibida;
  int lecturas = 0;

  @override
  Future<List<ReglaClinica>> getReglasVigentes() async {
    lecturas++;
    if (fallo != null) throw fallo!;
    return reglas;
  }

  @override
  Future<List<SignoVitalCatalogo>> getCatalogoSignosVitales() async => const [
    SignoVitalCatalogo(
      codigo: 'pulso',
      etiqueta: 'Pulso',
      unidad: 'lpm',
      minimoPosible: 10,
      maximoPosible: 300,
    ),
  ];

  @override
  Future<ResultadoPublicacion> publicar(
    ReglaClinica regla, {
    String? nota,
  }) async {
    publicada = regla;
    notaRecibida = nota;
    if (falloAlPublicar != null) throw falloAlPublicar!;
    if (fallo != null) throw fallo!;
    if (!sinCambios) {
      reglas = [
        for (final r in reglas)
          if (r.codigo == regla.codigo)
            _reglaPulso(
              version: r.version + 1,
              minimo: regla.parametros.minimo,
              maximo: regla.parametros.maximo,
            )
          else
            r,
      ];
    }
    return ResultadoPublicacion(
      codigo: regla.codigo,
      version: sinCambios ? regla.version : regla.version + 1,
      sinCambios: sinCambios,
    );
  }
}

ReglaClinica _reglaPulso({int version = 1, num? minimo = 50, num? maximo = 120}) =>
    ReglaClinica(
      id: 'r1',
      codigo: 'SV_PULSO_CRITICO',
      version: version,
      nombre: 'Pulso crítico',
      categoria: 'signo_vital',
      tipo: TipoRegla.valorCritico,
      parametros: ParametrosRegla(
        codigoSigno: 'pulso',
        minimo: minimo,
        maximo: maximo,
      ),
      severidad: SeveridadAlerta.critica,
      accion: AccionAlerta.documentar,
      estado: EstadoRegla.aprobada,
      editable: true,
    );

Widget _montar(Widget child, ReglaClinicaRepository repo) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: BlocProvider(
      create: (_) => ReglasClinicasCubit(repo)..cargar(),
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  group('Parámetros de la regla', () {
    test('un umbral se serializa con las claves que la base espera', () {
      final p = ParametrosRegla.fromJson({
        'codigo': 'pulso',
        'min': 50,
        'max': 120,
      });

      expect(p.toJson(TipoRegla.valorCritico), {
        'codigo': 'pulso',
        'min': 50,
        'max': 120,
      });
    });

    test('un campo vacío desaparece en vez de viajar como null', () {
      // La base distingue "sin límite" de "límite nulo": mandar `min: null`
      // pasaría la validación de forma y dejaría la regla vigilando la nada.
      final p = ParametrosRegla.fromJson({'codigo': 'pulso', 'max': 120});

      expect(p.toJson(TipoRegla.valorCritico).containsKey('min'), isFalse);
    });

    test('serializa según el tipo y no arrastra claves de otro', () {
      final p = ParametrosRegla.fromJson({
        'condicion': 'diabetes',
        'signos': [
          {'codigo': 'pulso', 'max': 110},
        ],
      });

      final json = p.toJson(TipoRegla.combinacionCondicionSigno);
      expect(json['condicion'], 'diabetes');
      expect(json['signos'], [
        {'codigo': 'pulso', 'max': 110},
      ]);
      expect(json.containsKey('min'), isFalse);
    });

    test('conserva las claves que no sabe interpretar', () {
      // Una pantalla de edición no puede devolver mutilada una regla cuyo
      // formato todavía no conoce.
      final p = ParametrosRegla.fromJson({
        'codigo': 'pulso',
        'max': 120,
        'origen': 'catalogo',
      });

      expect(p.toJson(TipoRegla.valorCritico)['origen'], 'catalogo');
    });

    test('un signo sin ningún límite no es coherente', () {
      expect(const UmbralSigno(codigo: 'pulso').esCoherente, isFalse);
      expect(
        const UmbralSigno(codigo: 'pulso', minimo: 150, maximo: 40).esCoherente,
        isFalse,
      );
      expect(
        const UmbralSigno(codigo: 'pulso', maximo: 110).esCoherente,
        isTrue,
      );
    });
  });

  group('Modelo', () {
    test('lee la regla tal como la devuelve la RPC', () {
      final regla = ReglaClinicaModel.fromJson({
        'id': 'r1',
        'codigo': 'SV_PULSO_CRITICO',
        'version': 2,
        'nombre': 'Pulso crítico',
        'categoria': 'signo_vital',
        'tipo': 'valor_critico',
        'parametros': {'codigo': 'pulso', 'min': 45, 'max': 130},
        'severidad': 'critica',
        'accion': 'documentar',
        'estado': 'aprobada',
        'editable': true,
      });

      expect(regla.version, 2);
      expect(regla.tipo, TipoRegla.valorCritico);
      expect(regla.severidad, SeveridadAlerta.critica);
      expect(regla.accion, AccionAlerta.documentar);
      expect(regla.parametros.maximo, 130);
      expect(regla.estaEnVigor, isTrue);
      expect(regla.editable, isTrue);
    });

    test('una regla de rango imposible llega marcada como no editable', () {
      final regla = ReglaClinicaModel.fromJson({
        'codigo': 'SV_RANGO_IMPOSIBLE',
        'tipo': 'rango_imposible',
        'estado': 'aprobada',
        'editable': false,
      });

      expect(regla.editable, isFalse);
      expect(regla.tipo, TipoRegla.rangoImposible);
    });
  });

  group('ReglasClinicasCubit', () {
    test('carga reglas y catálogo juntos', () async {
      final repo = _RepositorioFalso();
      final cubit = ReglasClinicasCubit(repo);

      await cubit.cargar();

      final estado = cubit.state;
      expect(estado, isA<ReglasClinicasCargadas>());
      estado as ReglasClinicasCargadas;
      expect(estado.reglas, hasLength(1));
      expect(estado.signo('pulso')?.unidad, 'lpm');
    });

    test('un fallo de red no deja la pantalla en blanco sin motivo', () async {
      final cubit = ReglasClinicasCubit(
        _RepositorioFalso(fallo: const NetworkFailure()),
      );

      await cubit.cargar();

      expect(cubit.state, isA<ReglasClinicasError>());
    });

    test('tras publicar relee de la base en vez de pintar lo enviado', () async {
      // Es lo que HFX-CLIN-005 vino a erradicar: la pantalla no puede afirmar
      // un estado que el servidor no ha confirmado.
      final repo = _RepositorioFalso();
      final cubit = ReglasClinicasCubit(repo);
      await cubit.cargar();
      final lecturasIniciales = repo.lecturas;

      await cubit.publicar(
        _reglaPulso().copyWith(
          parametros: const ParametrosRegla(
            codigoSigno: 'pulso',
            minimo: 45,
            maximo: 130,
          ),
        ),
        nota: 'Comité clínico',
      );

      expect(repo.lecturas, lecturasIniciales + 1);
      expect(repo.notaRecibida, 'Comité clínico');
      final estado = cubit.state as ReglasClinicasCargadas;
      expect(estado.reglas.single.version, 2);
      expect(estado.reglas.single.parametros.maximo, 130);
      expect(estado.publicando, isNull);
      expect(estado.aviso, contains('versión 2'));
    });

    test('distingue "guardado" de "no había nada que guardar"', () async {
      final repo = _RepositorioFalso(sinCambios: true);
      final cubit = ReglasClinicasCubit(repo);
      await cubit.cargar();

      await cubit.publicar(_reglaPulso());

      final estado = cubit.state as ReglasClinicasCargadas;
      expect(estado.aviso, contains('ya estaba así'));
    });

    test('un rechazo al publicar deja el motivo y el umbral anterior', () async {
      // La base es la autoridad: si rechaza el umbral, la fila no puede
      // quedarse pintada con el valor que se intentó guardar.
      final repo = _RepositorioFalso(
        falloAlPublicar: const ServerFailure(
          'El límite inferior no puede ser mayor que el superior.',
        ),
      );
      final cubit = ReglasClinicasCubit(repo);
      await cubit.cargar();

      await cubit.publicar(
        _reglaPulso().copyWith(
          parametros: const ParametrosRegla(
            codigoSigno: 'pulso',
            minimo: 150,
            maximo: 40,
          ),
        ),
      );

      final estado = cubit.state as ReglasClinicasCargadas;
      expect(estado.error, contains('límite inferior'));
      expect(estado.publicando, isNull);
      expect(estado.reglas.single.parametros.minimo, 50);
      expect(estado.reglas.single.version, 1);
    });

    test('no publica dos veces a la vez', () async {
      // Dos toques seguidos sobre la misma fila no deben versionar dos veces.
      final repo = _RepositorioFalso();
      final cubit = ReglasClinicasCubit(repo);
      await cubit.cargar();

      final futuro = cubit.publicar(_reglaPulso());
      await cubit.publicar(_reglaPulso(minimo: 40));
      await futuro;

      expect(repo.publicada!.parametros.minimo, 50);
    });
  });

  group('Sección de ajustes', () {
    testWidgets('resume qué vigila cada regla', (tester) async {
      final repo = _RepositorioFalso();
      await tester.pumpWidget(_montar(const SeccionReglasClinicas(), repo));
      await tester.pumpAndSettle();

      expect(find.text('Pulso crítico'), findsOneWidget);
      expect(
        find.textContaining('por debajo de 50 o por encima de 120'),
        findsOneWidget,
      );
      expect(find.textContaining('v1 · Crítica'), findsOneWidget);
    });

    testWidgets('una regla no editable se muestra bloqueada', (tester) async {
      final repo = _RepositorioFalso(
        reglas: [
          const ReglaClinica(
            id: 'r2',
            codigo: 'SV_RANGO_IMPOSIBLE',
            version: 1,
            nombre: 'Rango imposible',
            categoria: 'signo_vital',
            tipo: TipoRegla.rangoImposible,
            parametros: ParametrosRegla(),
            severidad: SeveridadAlerta.absoluta,
            accion: AccionAlerta.bloquearElectivo,
            estado: EstadoRegla.aprobada,
          ),
        ],
      );
      await tester.pumpWidget(_montar(const SeccionReglasClinicas(), repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('una regla sin aprobar no se pinta como si vigilara', (
      tester,
    ) async {
      final repo = _RepositorioFalso(
        reglas: [
          ReglaClinica(
            id: 'r3',
            codigo: 'SV_DOLOR_SEVERO',
            version: 1,
            nombre: 'Dolor severo',
            categoria: 'signo_vital',
            tipo: TipoRegla.valorCritico,
            parametros: const ParametrosRegla(codigoSigno: 'dolor'),
            severidad: SeveridadAlerta.critica,
            accion: AccionAlerta.documentar,
            estado: EstadoRegla.pendienteAprobacion,
            editable: true,
          ),
        ],
      );
      await tester.pumpWidget(_montar(const SeccionReglasClinicas(), repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sin aprobar'), findsOneWidget);
      expect(find.text('Sin umbral configurado.'), findsOneWidget);
    });
  });

  group('Editor', () {
    Future<void> abrir(WidgetTester tester, {ReglaClinica? regla}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: EditorReglaClinica(
              regla: regla ?? _reglaPulso(),
              catalogo: const [
                SignoVitalCatalogo(
                  codigo: 'pulso',
                  etiqueta: 'Pulso',
                  unidad: 'lpm',
                  minimoPosible: 10,
                  maximoPosible: 300,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('parte de los umbrales vigentes', (tester) async {
      await abrir(tester);

      expect(find.widgetWithText(TextFormField, '50'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '120'), findsOneWidget);
      expect(find.textContaining('posible: 10–300 lpm'), findsOneWidget);
    });

    testWidgets('rechaza un umbral fuera de lo medible', (tester) async {
      // 500 lpm no se alcanzaría jamás: la alerta existiría y no sonaría nunca.
      await abrir(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, '120'),
        '500',
      );
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();

      expect(find.text('Entre 10 y 300'), findsOneWidget);
    });

    testWidgets('avisa cuando la regla se quedaría sin vigilar nada', (
      tester,
    ) async {
      await abrir(tester);
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '');
      await tester.enterText(find.widgetWithText(TextFormField, '120'), '');
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('al menos un límite'),
        findsOneWidget,
      );
    });

    testWidgets('explica si la alerta bloqueará el cierre', (tester) async {
      await abrir(tester);

      expect(
        find.textContaining('no se podrá cerrar mientras esta alerta'),
        findsOneWidget,
      );
    });
  });
}
