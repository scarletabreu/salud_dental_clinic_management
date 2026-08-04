import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auditoria/data/models/evento_auditoria_model.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/repositories/auditoria_repository.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/cubit/linea_tiempo_cubit.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/cubit/linea_tiempo_state.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/widgets/linea_tiempo_consulta.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';

class _RepositorioFalso implements AuditoriaRepository {
  _RepositorioFalso(this._eventos, {this.fallo});

  final List<EventoAuditoria> _eventos;
  final Failure? fallo;
  int llamadas = 0;

  @override
  Future<List<EventoAuditoria>> getLineaTiempo(String consultaId) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    return _eventos;
  }
}

EventoAuditoria _evento({
  String id = 'e1',
  required String evento,
  CategoriaEvento categoria = CategoriaEvento.clinico,
  DateTime? cuando,
  String? actorNombre,
  String? rol,
  String? motivo,
  Map<String, dynamic> metadata = const {},
}) => EventoAuditoria(
  id: id,
  evento: evento,
  categoria: categoria,
  ocurridoEn: cuando ?? DateTime(2026, 7, 31, 9, 30),
  actorNombre: actorNombre,
  rol: rol,
  motivo: motivo,
  metadata: metadata,
);

Widget _host(AuditoriaRepository repo) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: BlocProvider(
      create: (_) => LineaTiempoCubit(repo)..cargar('consulta-1'),
      child: const SingleChildScrollView(child: _ContenidoDePrueba()),
    ),
  ),
);

/// Monta el mismo árbol que `LineaTiempoConsulta` sin pasar por el service
/// locator, que en pruebas no está inicializado.
class _ContenidoDePrueba extends StatelessWidget {
  const _ContenidoDePrueba();

  @override
  Widget build(BuildContext context) =>
      const LineaTiempoConsultaVista(consultaId: 'consulta-1');
}

void main() {
  group('modelo', () {
    test('lee la fila de la RPC y la pasa a hora local', () {
      final evento = EventoAuditoriaModel.fromJson({
        'id': 'e1',
        'evento': 'receta_emitida',
        'categoria': 'receta',
        'ocurrido_en': '2026-07-31T13:30:00+00:00',
        'actor_id': 'u1',
        'actor_nombre': 'Aida Auditoría',
        'rol': 'doctor',
        'motivo': null,
        'metadata': {'items': 2},
      });

      expect(evento.categoria, CategoriaEvento.receta);
      expect(evento.ocurridoEn.isUtc, isFalse);
      expect(
        evento.ocurridoEn.toUtc(),
        DateTime.utc(2026, 7, 31, 13, 30),
      );
      expect(evento.metadata['items'], 2);
    });

    test('una categoría desconocida no rompe la lectura', () {
      final evento = EventoAuditoriaModel.fromJson({
        'id': 'e1',
        'evento': 'algo_nuevo',
        'categoria': 'inventada',
        'ocurrido_en': '2026-07-31T13:30:00Z',
      });

      expect(evento.categoria, CategoriaEvento.clinico);
    });
  });

  group('autoría', () {
    test('un evento sin sesión se atribuye al sistema, no a una persona', () {
      final evento = _evento(evento: 'cita_reprogramada', rol: 'sistema');
      expect(evento.autor, 'Sistema');
    });

    test('el nombre viaja acompañado del rol', () {
      final evento = _evento(
        evento: 'consulta_cerrada',
        actorNombre: 'Aida Auditoría',
        rol: 'doctor',
      );
      expect(evento.autor, 'Aida Auditoría · Doctor');
    });

    test('sin nombre resuelto queda el rol legible', () {
      final evento = _evento(
        evento: 'consulta_cerrada',
        rol: 'admin',
      );
      // Hay actor pero su ficha no se pudo resolver: decir "Sistema" sería
      // mentir sobre quién firmó.
      expect(
        EventoAuditoria(
          id: 'x',
          evento: 'consulta_cerrada',
          categoria: CategoriaEvento.clinico,
          ocurridoEn: evento.ocurridoEn,
          actorId: 'u9',
          rol: 'admin',
        ).autor,
        'Administración',
      );
    });
  });

  group('terminología', () {
    test('cada evento se nombra con el vocabulario del expediente', () {
      expect(
        _evento(evento: 'receta_emitida').descripcion,
        'Receta emitida',
      );
      expect(
        _evento(evento: 'receta_reemplazada').descripcion,
        'Receta reemplazada',
      );
      expect(
        _evento(
          evento: 'tratamiento_ejecutado',
          metadata: const {'tratamiento': 'Resina'},
        ).descripcion,
        'Tratamiento ejecutado: Resina',
      );
      expect(
        _evento(evento: 'plan_aceptado').descripcion,
        'Plan de tratamiento aceptado',
      );
    });

    test('una cita de emergencia se distingue en la historia', () {
      expect(
        _evento(
          evento: 'cita_creada',
          metadata: const {'es_emergencia': true},
        ).descripcion,
        'Cita de emergencia creada',
      );
    });
  });

  group('pantalla', () {
    testWidgets('muestra la historia con actor, fecha y motivo', (tester) async {
      final repo = _RepositorioFalso([
        _evento(
          id: 'e1',
          evento: 'cita_llegada',
          categoria: CategoriaEvento.agenda,
          cuando: DateTime(2026, 7, 31, 8, 55),
          actorNombre: 'Clara Recepción',
          rol: 'asistente',
        ),
        _evento(
          id: 'e2',
          evento: 'correccion_administrativa',
          categoria: CategoriaEvento.correccion,
          cuando: DateTime(2026, 7, 31, 11, 5),
          actorNombre: 'Delia Dirección',
          rol: 'admin',
          motivo: 'Pieza equivocada',
        ),
      ]);

      await tester.pumpWidget(_host(repo));
      await tester.pumpAndSettle();

      expect(find.text('Llegada del paciente registrada'), findsOneWidget);
      expect(find.text('Clara Recepción · Asistente'), findsOneWidget);
      expect(find.text('31 jul 2026 · 08:55'), findsOneWidget);
      expect(find.text('Corrección administrativa'), findsOneWidget);
      expect(find.text('Motivo: Pieza equivocada'), findsOneWidget);
    });

    testWidgets('cada evento se anuncia como una sola frase completa', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = _RepositorioFalso([
        _evento(
          evento: 'consulta_cerrada',
          cuando: DateTime(2026, 7, 31, 12, 0),
          actorNombre: 'Aida Auditoría',
          rol: 'doctor',
        ),
      ]);

      await tester.pumpWidget(_host(repo));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Consulta finalizada. Aida Auditoría · Doctor. 31 jul 2026 a las 12:00',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('un fallo se queda visible y ofrece reintentar', (tester) async {
      final repo = _RepositorioFalso(
        const [],
        fallo: const NetworkFailure(),
      );

      await tester.pumpWidget(_host(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(repo.llamadas, 1);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.llamadas, 2);
      // El error no se autodescarta: sigue ahí hasta que la carga funcione.
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });

    testWidgets('una consulta sin eventos lo dice en vez de quedarse vacía', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_RepositorioFalso(const [])));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta consulta todavía no tiene eventos registrados.'),
        findsOneWidget,
      );
    });
  });

  group('estado', () {
    test('el cubit traduce el fallo tipado a su mensaje', () async {
      final cubit = LineaTiempoCubit(
        _RepositorioFalso(const [], fallo: const ServerFailure('Se cayó')),
      );
      await cubit.cargar('c1');
      expect(cubit.state, isA<LineaTiempoError>());
      expect((cubit.state as LineaTiempoError).mensaje, 'Se cayó');
      await cubit.close();
    });
  });
}
