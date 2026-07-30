import { createClient } from 'jsr:@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

const ROLES_VALIDOS = ['admin', 'doctor', 'asistente'] as const;
type Rol = typeof ROLES_VALIDOS[number];

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

/// El teléfono viaja de dos formas según quién llame: el repositorio de Flutter
/// lo manda dentro de `contactos`, y las pruebas manuales lo mandan suelto.
/// Aceptar ambas evita que el alta cree la persona sin contacto en silencio.
function extraerTelefono(body: Record<string, unknown>): string | null {
  const suelto = body.telefono;
  if (typeof suelto === 'string' && suelto.trim() !== '') return suelto.trim();

  const contactos = body.contactos;
  if (Array.isArray(contactos)) {
    for (const c of contactos) {
      const numero = (c as Record<string, unknown> | null)?.numero_telefono;
      if (typeof numero === 'string' && numero.trim() !== '') {
        return numero.trim();
      }
    }
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user: caller } } = await callerClient.auth.getUser();
    if (!caller) return json({ error: 'No autenticado' }, 401);

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // Admin activo: una baja lógica retira la capacidad de crear personal.
    const { data: esAdmin } = await admin
      .from('admins')
      .select('id')
      .eq('id', caller.id)
      .is('deleted_at', null)
      .maybeSingle();

    if (!esAdmin) return json({ error: 'No autorizado' }, 403);

    const body = await req.json() as Record<string, unknown>;
    const {
      email, password, nombre, apellido, fecha_nacimiento,
      cedula, username, rol, especialidad, departamento, turno,
    } = body as Record<string, string | undefined>;

    const telefono = extraerTelefono(body);

    // Validar antes de tocar Auth. El trigger `handle_new_user` también lo
    // comprueba —es la barrera real—, pero rechazar aquí devuelve un error que
    // el formulario puede mostrar campo a campo en vez de un fallo de base.
    const faltantes = Object.entries({
      email, password, nombre, apellido, fecha_nacimiento, cedula, username, rol,
    })
      .filter(([, v]) => typeof v !== 'string' || v.trim() === '')
      .map(([k]) => k);

    if (faltantes.length > 0) {
      return json({ error: `Faltan datos obligatorios: ${faltantes.join(', ')}.` }, 400);
    }
    if (!ROLES_VALIDOS.includes(rol as Rol)) {
      return json({ error: `Rol inválido: "${rol}".` }, 400);
    }
    if (rol === 'asistente' && (!turno || turno.trim() === '')) {
      return json({ error: 'Un asistente necesita turno.' }, 400);
    }
    // Doctor y admin comparten identidad clínica y los dos nacen con fila en
    // `doctores`, así que los dos necesitan especialidad.
    if ((rol === 'doctor' || rol === 'admin') &&
        (!especialidad || especialidad.trim() === '')) {
      return json({ error: 'Un doctor o administrador necesita especialidad.' }, 400);
    }
    if (rol === 'admin' && (!departamento || departamento.trim() === '')) {
      return json({ error: 'Un administrador necesita departamento.' }, 400);
    }

    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        nombre, apellido, fecha_nacimiento, cedula, username, rol,
        especialidad, departamento, turno, telefono,
      },
    });

    if (error) {
      // El trigger de perfil corre dentro del INSERT de auth.users: si aborta,
      // no queda usuario autenticable. El mensaje se devuelve sin stack ni
      // detalle interno.
      console.error('admin-crear-usuario: alta rechazada', {
        rol, codigo: error.code ?? error.status,
      });
      return json({ error: error.message }, 400);
    }

    const uuid = data.user?.id;
    if (!uuid) return json({ error: 'Auth no devolvió el usuario creado.' }, 500);

    // Red de seguridad: si por cualquier vía quedara un usuario de Auth sin
    // perfil operativo, no se deja autenticable.
    const { data: perfil } = await admin
      .from('usuarios')
      .select('id')
      .eq('id', uuid)
      .maybeSingle();

    if (!perfil) {
      await admin.auth.admin.deleteUser(uuid);
      return json(
        { error: 'El usuario no pudo aprovisionarse y se revirtió el alta.' },
        500,
      );
    }

    console.info('admin-crear-usuario: alta completada', { rol, uuid });
    return json({ uuid }, 200);
  } catch (e) {
    // Nunca se devuelve el error interno completo al cliente.
    console.error('admin-crear-usuario: fallo inesperado', e);
    return json({ error: 'No se pudo crear el usuario.' }, 400);
  }
});
