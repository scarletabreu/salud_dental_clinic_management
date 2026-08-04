// Verificación MU-0 · ¿Realtime entrega eventos recortados por RLS?
//
// Todo el plan multiusuario descansa sobre una premisa: el recorte por rol de
// los eventos lo hace Postgres (policy `citas_select` de d11), no el cliente.
// Este script la comprueba contra el contenedor Realtime del stack LOCAL con
// dos sesiones reales:
//
//   · la doctora de certificación (ve sólo sus citas)
//   · el admin (ve todas)
//
// Ambas se suscriben a `postgres_changes` de `public.citas`. Luego se tocan
// por psql (rol postgres, fuera de RLS) dos citas: una de la doctora y una
// del admin. Lo esperado:
//
//   · cita de la doctora  → la ven las dos sesiones
//   · cita del admin      → la ve el admin; a la doctora NO le llega
//
// Requiere el seed de certificación aplicado. Corre con el wrapper:
//   tool/e2e/realtime_rls.sh
import 'dart:async';
import 'dart:io';

// El arnés usa el cliente puro de Dart, que llega como dependencia transitiva
// de supabase_flutter; declararlo aparte duplicaría la restricción de versión.
// ignore: depend_on_referenced_packages
import 'package:supabase/supabase.dart';

const _url = 'http://127.0.0.1:54321';
const _anon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
const _dbUrl = 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
const _password = 'Cert-2026!';

const _uuidAdmin = 'ce470000-0000-4000-8000-000000000001';
const _uuidDoctora = 'ce470000-0000-4000-8000-000000000002';

Future<void> main() async {
  var fallos = 0;
  final admin = SupabaseClient(_url, _anon);
  final doctora = SupabaseClient(_url, _anon);

  try {
    // El overlay de login E2E puede haber reescrito el dominio de los
    // correos; se toma el vigente directamente de auth.users.
    await admin.auth.signInWithPassword(
      email: await _emailDe(_uuidAdmin),
      password: _password,
    );
    await doctora.auth.signInWithPassword(
      email: await _emailDe(_uuidDoctora),
      password: _password,
    );
    stdout.writeln('✓ Sesiones abiertas: admin y doctora');

    final eventosAdmin = <String>[];
    final eventosDoctora = <String>[];

    await _suscribir(admin, 'admin', eventosAdmin);
    await _suscribir(doctora, 'doctora', eventosDoctora);
    stdout.writeln('✓ Ambas sesiones suscritas a postgres_changes de citas');

    // Escenario: una cita de cada uno, tocadas fuera de RLS por psql.
    final citaDoctora = await _psql(
      "select id from public.citas where doctor_id = '$_uuidDoctora' limit 1",
    );
    final citaAdmin = await _psql('''
      insert into public.citas
        (persona_id, doctor_id, fecha_hora, duracion_minutos, estado, motivo)
      select persona_id, '$_uuidAdmin', date_trunc('day', now()) + interval '19 hours',
             30, 'confirmada', 'MU-0 verificación realtime'
        from public.citas where doctor_id = '$_uuidDoctora' limit 1
      returning id''');
    if (citaDoctora.isEmpty || citaAdmin.isEmpty) {
      stderr.writeln('✗ El seed no dejó el escenario montado');
      exit(2);
    }

    Future<void> tocar(String citaId) => _psql(
          "update public.citas set motivo = motivo || '.' where id = '$citaId'",
        );

    // 1 · Cambio en la cita de la doctora: deben verlo las dos sesiones.
    await tocar(citaDoctora);
    final ambos = await Future.wait([
      _esperarEvento(eventosAdmin, citaDoctora),
      _esperarEvento(eventosDoctora, citaDoctora),
    ]);
    fallos += _veredicto(
      'cita de la doctora → la ve el admin (ve todo)',
      ambos[0],
    );
    fallos += _veredicto(
      'cita de la doctora → la ve la doctora (es suya)',
      ambos[1],
    );

    // 2 · Cambio en la cita del admin: el admin sí, la doctora NO.
    eventosAdmin.clear();
    eventosDoctora.clear();
    await tocar(citaAdmin);
    fallos += _veredicto(
      'cita del admin → la ve el admin',
      await _esperarEvento(eventosAdmin, citaAdmin),
    );
    fallos += _veredicto(
      'cita del admin → a la doctora NO le llega (RLS)',
      !await _esperarEvento(eventosDoctora, citaAdmin,
          espera: const Duration(seconds: 4)),
    );

    // Limpieza del escenario.
    await _psql("delete from public.citas where id = '$citaAdmin'");
  } finally {
    await admin.dispose();
    await doctora.dispose();
  }

  if (fallos > 0) {
    stderr.writeln('✗ $fallos comprobaciones fallaron');
    exit(1);
  }
  stdout.writeln('✓ Realtime local entrega eventos con recorte RLS por rol');
  exit(0);
}

Future<void> _suscribir(
  SupabaseClient client,
  String etiqueta,
  List<String> eventos,
) {
  final listo = Completer<void>();
  client
      .channel('mu0:$etiqueta')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'citas',
        callback: (payload) {
          final id = (payload.newRecord['id'] ?? payload.oldRecord['id'])
              ?.toString();
          if (id != null) eventos.add(id);
        },
      )
      .subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed &&
            !listo.isCompleted) {
          listo.complete();
        }
        if (status == RealtimeSubscribeStatus.channelError &&
            !listo.isCompleted) {
          listo.completeError(error ?? 'channelError en $etiqueta');
        }
      });
  return listo.future.timeout(const Duration(seconds: 10));
}

/// Espera hasta [espera] a que la lista contenga un evento de la cita.
Future<bool> _esperarEvento(
  List<String> eventos,
  String citaId, {
  Duration espera = const Duration(seconds: 8),
}) async {
  final limite = DateTime.now().add(espera);
  while (DateTime.now().isBefore(limite)) {
    if (eventos.contains(citaId)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return false;
}

int _veredicto(String descripcion, bool ok) {
  stdout.writeln('${ok ? '✓' : '✗'} $descripcion');
  return ok ? 0 : 1;
}

Future<String> _emailDe(String uuid) =>
    _psql("select email from auth.users where id = '$uuid'");

Future<String> _psql(String sql) async {
  final resultado = await Process.run(
    'psql',
    [_dbUrl, '-qAt', '-v', 'ON_ERROR_STOP=1', '-c', sql],
  );
  if (resultado.exitCode != 0) {
    stderr.writeln('✗ psql falló: ${resultado.stderr}');
    exit(2);
  }
  return (resultado.stdout as String).trim();
}
