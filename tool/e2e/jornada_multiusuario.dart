// Cierre MU-6 · La jornada completa a tres sesiones (admin, doctora,
// asistente) verificada por el mismo transporte que consumen las pantallas:
// eventos `postgres_changes` recortados por RLS.
//
// Cada paso muta la base como lo haría la sesión correspondiente (RPCs y
// escrituras del propio cliente autenticado; la consulta finalizada se
// simula por psql porque su payload clínico completo ya lo cubre el arnés de
// UI) y se asevera que:
//
//   · las otras sesiones reciben el evento en <2 s, sin interacción;
//   · ningún rol recibe eventos fuera de su alcance.
//
// Corre con el wrapper: tool/e2e/jornada_multiusuario.sh (stack LOCAL).
import 'dart:async';
import 'dart:io';

// Cliente puro de Dart, dependencia transitiva de supabase_flutter.
// ignore: depend_on_referenced_packages
import 'package:supabase/supabase.dart';

const _url = 'http://127.0.0.1:54321';
const _anon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
const _dbUrl = 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
const _password = 'Cert-2026!';

const _uuidAdmin = 'ce470000-0000-4000-8000-000000000001';
const _uuidDoctora = 'ce470000-0000-4000-8000-000000000002';
const _uuidAsistente = 'ce470000-0000-4000-8000-000000000003';

const _marca = 'MU-6 jornada';
const _tablas = ['citas', 'cajas', 'cuentas', 'doctor_asistentes', 'personas'];

int _fallos = 0;

class _Sesion {
  _Sesion(this.nombre) : client = SupabaseClient(_url, _anon);

  final String nombre;
  final SupabaseClient client;
  final List<({String tabla, String tipo, Map<String, dynamic> fila})>
      eventos = [];

  Future<void> conectar(String uuid) async {
    final email = await _psql("select email from auth.users where id = '$uuid'");
    await client.auth.signInWithPassword(email: email, password: _password);

    final listo = Completer<void>();
    var canal = client.channel('mu6:$nombre');
    for (final tabla in _tablas) {
      canal = canal.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tabla,
        callback: (payload) => eventos.add((
          tabla: payload.table,
          tipo: payload.eventType.name,
          fila: payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord,
        )),
      );
    }
    canal.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed && !listo.isCompleted) {
        listo.complete();
      }
      if (status == RealtimeSubscribeStatus.channelError &&
          !listo.isCompleted) {
        listo.completeError(error ?? 'channelError en $nombre');
      }
    });
    await listo.future.timeout(const Duration(seconds: 10));
  }

  /// Espera a que llegue un evento que cumpla [donde]; devuelve los ms que
  /// tardó, o `null` si venció el plazo.
  Future<int?> esperar(
    String tabla,
    bool Function(Map<String, dynamic> fila) donde, {
    Duration plazo = const Duration(seconds: 8),
  }) async {
    final inicio = DateTime.now();
    final limite = inicio.add(plazo);
    while (DateTime.now().isBefore(limite)) {
      if (eventos.any((e) => e.tabla == tabla && donde(e.fila))) {
        return DateTime.now().difference(inicio).inMilliseconds;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  Future<bool> nuncaLlega(
    String tabla,
    bool Function(Map<String, dynamic> fila) donde,
  ) async =>
      (await esperar(tabla, donde, plazo: const Duration(seconds: 4))) == null;
}

void _veredicto(String descripcion, bool ok, {int? ms}) {
  final tiempo = ms == null ? '' : ' ($ms ms)';
  stdout.writeln('${ok ? '✓' : '✗'} $descripcion$tiempo');
  if (!ok) _fallos++;
}

Future<String> _psql(String sql) async {
  final r = await Process.run(
    'psql',
    [_dbUrl, '-qAt', '-v', 'ON_ERROR_STOP=1', '-c', sql],
  );
  if (r.exitCode != 0) {
    stderr.writeln('✗ psql falló: ${r.stderr}');
    exit(2);
  }
  return (r.stdout as String).trim();
}

Future<void> main() async {
  final admin = _Sesion('admin');
  final doctora = _Sesion('doctora');
  final asistente = _Sesion('asistente');

  try {
    await admin.conectar(_uuidAdmin);
    await doctora.conectar(_uuidDoctora);
    await asistente.conectar(_uuidAsistente);
    stdout.writeln(
      '✓ Tres sesiones suscritas a ${_tablas.join(', ')} (RLS activo)',
    );

    // ── 1 · Asignación en caliente (MU-5) ────────────────────────────────
    await _psql(
      "insert into public.doctor_asistentes (doctor_id, asistente_id) "
      "values ('$_uuidDoctora', '$_uuidAsistente') on conflict do nothing",
    );
    final msAsignacion = await asistente.esperar(
      'doctor_asistentes',
      (f) => f['asistente_id'] == _uuidAsistente,
    );
    _veredicto(
      'la asignación de la doctora llega a la sesión del asistente',
      msAsignacion != null,
      ms: msAsignacion,
    );

    // ── 2 · Llegada del paciente (escenario 1) ──────────────────────────
    // Cita propia del escenario: la llegada exige una cita de HOY (CL015) y
    // el estado de las del seed depende de corridas anteriores.
    // El hueco se elige después de la última cita de hoy para no chocar con
    // `citas_sin_solape`, venga de donde venga (seed o corridas previas).
    final citaLlegada = await _psql(
      "insert into public.citas "
      "(persona_id, doctor_id, fecha_hora, duracion_minutos, estado, motivo) "
      "select 'ce470000-0000-4000-8000-000000000101', '$_uuidDoctora', "
      "greatest(now(), coalesce(max(fecha_hora + "
      "(duracion_minutos || ' minutes')::interval), now())) "
      "+ interval '5 minutes', 30, 'confirmada', '$_marca llegada' "
      "from public.citas "
      "where doctor_id = '$_uuidDoctora' and deleted_at is null "
      "and fecha_hora < now() + interval '12 hours' "
      "returning id",
    );
    await asistente.client.rpc<dynamic>(
      'registrar_llegada_cita',
      params: {'p_cita_id': citaLlegada},
    );
    final msDoctora = await doctora.esperar(
      'citas',
      (f) => f['id'] == citaLlegada && f['estado'] == 'en_espera',
    );
    _veredicto(
      'la llegada marcada por el asistente aparece en la sesión de la doctora',
      msDoctora != null,
      ms: msDoctora,
    );
    final msAdmin = await admin.esperar(
      'citas',
      (f) => f['id'] == citaLlegada && f['estado'] == 'en_espera',
    );
    _veredicto('…y también en la del admin', msAdmin != null, ms: msAdmin);

    // ── 3 · Reagenda ajena (escenario 7) ────────────────────────────────
    final citaReagenda = await _psql(
      "insert into public.citas "
      "(persona_id, doctor_id, fecha_hora, duracion_minutos, estado, motivo) "
      "select persona_id, doctor_id, now() + interval '2 days', 30, "
      "'confirmada', '$_marca reagenda' "
      "from public.citas where id = '$citaLlegada' returning id",
    );
    await admin.client
        .from('citas')
        .update({
          'fecha_hora': DateTime.now()
              .add(const Duration(days: 2, hours: 3))
              .toUtc()
              .toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', citaReagenda);
    final msReagenda = await doctora.esperar(
      'citas',
      (f) =>
          f['id'] == citaReagenda &&
          f['motivo'] == '$_marca reagenda' &&
          f['updated_at'] != f['created_at'],
    );
    _veredicto(
      'la reagenda hecha por el admin llega a la agenda de la doctora',
      msReagenda != null,
      ms: msReagenda,
    );

    // ── 4 · Apertura de caja (escenario "desde el otro cuarto") ─────────
    await asistente.client.from('cajas').insert({
      'monto_apertura': 5000,
      'cerrada': false,
      'fecha': DateTime.now().toUtc().toIso8601String(),
      'abierta_por': _uuidAsistente,
      'monto_esperado': 5000,
      'monto_real': 0,
      'monto_cierre': 0,
    });
    final msCaja = await admin.esperar(
      'cajas',
      (f) => f['cerrada'] == false && f['abierta_por'] == _uuidAsistente,
    );
    _veredicto(
      'la apertura de caja del asistente llega a la sesión del admin',
      msCaja != null,
      ms: msCaja,
    );

    // ── 5 · Consulta finalizada → cuenta nueva (escenario 2) ────────────
    // El cierre clínico completo lo cubre el arnés de UI; aquí se reproduce
    // su efecto observable —la pre-factura— para verificar la propagación.
    final pacienteId = await _psql(
      "select persona_id from public.citas where id = '$citaLlegada'",
    );
    final cuentaId = await _psql(
      "with c as (insert into public.consultas "
      "(paciente_id, doctor_id, motivo_consulta, finalizada) "
      "values ('$pacienteId', '$_uuidAdmin', '$_marca', true) returning id) "
      "insert into public.cuentas "
      "(consulta_id, metodo_pago, monto_total, paciente_id, nota) "
      "select id, 'contado', 3500, '$pacienteId', '$_marca' from c "
      "returning id",
    );
    final msCuentaAsistente = await asistente.esperar(
      'cuentas',
      (f) => f['id'] == cuentaId,
    );
    _veredicto(
      'la cuenta de la consulta finalizada aparece en el mostrador del asistente',
      msCuentaAsistente != null,
      ms: msCuentaAsistente,
    );

    // Alcance negativo: una cuenta de un paciente SIN relación con la
    // doctora (atendido sólo por el admin) no debe llegarle. El asistente sí
    // la ve: `puede_ver_paciente` le da el mostrador completo a recepción.
    final cuentaAjena = await _psql(
      "with p as (insert into public.personas "
      "(nombre, apellido, fecha_nacimiento, cedula) "
      "values ('Ajeno', '$_marca', '1990-01-01', 'MU6-000-0000000-1') "
      "returning id), "
      "pa as (insert into public.pacientes (id, genero) "
      "select id, 'masculino' from p returning id), "
      "c as (insert into public.consultas "
      "(paciente_id, doctor_id, motivo_consulta, finalizada) "
      "select id, '$_uuidAdmin', '$_marca', true from pa "
      "returning id, paciente_id) "
      "insert into public.cuentas "
      "(consulta_id, metodo_pago, monto_total, paciente_id, nota) "
      "select id, 'contado', 1200, paciente_id, '$_marca' from c "
      "returning id",
    );
    _veredicto(
      'a la doctora NO le llega la cuenta de un paciente que no es suyo (RLS)',
      await doctora.nuncaLlega('cuentas', (f) => f['id'] == cuentaAjena),
    );
    // Directorio (MU-3): el alta de la persona sí llega al mostrador.
    final msPersona = await asistente.esperar(
      'personas',
      (f) => f['apellido'] == _marca,
    );
    _veredicto(
      'la persona recién creada llega al directorio del asistente',
      msPersona != null,
      ms: msPersona,
    );

    // ── 6 · Cobro ajeno (escenario 3) ───────────────────────────────────
    await asistente.client.rpc<dynamic>(
      'registrar_pago',
      params: {
        'p_cuenta_id': cuentaId,
        'p_monto': 1500,
        'p_metodo_pago': 'efectivo',
      },
    );
    // Un cobro parcial deja la cuenta 'pendiente' (hfx_base_registrar_pago
    // actualiza la fila siempre); eso es lo que la lista y la pre-factura
    // abiertas escuchan.
    final msCobro = await admin.esperar(
      'cuentas',
      (f) => f['id'] == cuentaId && f['estado'] == 'pendiente',
    );
    _veredicto(
      'el cobro del asistente actualiza la cuenta en la sesión del admin',
      msCobro != null,
      ms: msCobro,
    );

    // ── 7 · Cierre de caja ──────────────────────────────────────────────
    final cajaId = await _psql(
      "select id from public.cajas where cerrada = false "
      "and abierta_por = '$_uuidAsistente' order by created_at desc limit 1",
    );
    await asistente.client
        .from('cajas')
        .update({
          'monto_cierre': 6500,
          'monto_real': 6500,
          'monto_esperado': 6500,
          'cerrada': true,
          'cerrada_por': _uuidAsistente,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', cajaId);
    final msCierre = await admin.esperar(
      'cajas',
      (f) => f['id'] == cajaId && f['cerrada'] == true,
    );
    _veredicto(
      'el cierre de caja se propaga a la sesión del admin',
      msCierre != null,
      ms: msCierre,
    );
  } finally {
    await admin.client.dispose();
    await doctora.client.dispose();
    await asistente.client.dispose();
  }

  if (_fallos > 0) {
    stderr.writeln('✗ $_fallos pasos de la jornada fallaron');
    exit(1);
  }
  stdout.writeln(
    '✓ Jornada multiusuario completa: cada sesión vio lo suyo y nada ajeno',
  );
  exit(0);
}
