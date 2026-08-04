import { createClient } from "jsr:@supabase/supabase-js";
import { corsHeaders } from "../_shared/cors.ts";
import { origenPermitido, validarAlta } from "./validation.ts";

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (req.method !== "POST") {
      return json(
        { error: "Método no permitido", code: "METHOD_NOT_ALLOWED" },
        405,
      );
    }
    if (!authHeader.startsWith("Bearer ") || authHeader.length < 20) {
      return json({ error: "No autenticado", code: "AUTH_REQUIRED" }, 401);
    }
    if (!(req.headers.get("content-type") ?? "").includes("application/json")) {
      return json({
        error: "El body debe ser JSON",
        code: "INVALID_CONTENT_TYPE",
      }, 415);
    }

    const origin = req.headers.get("Origin");
    if (!origenPermitido(origin, Deno.env.get("ALLOWED_ORIGINS") ?? "")) {
      return json(
        { error: "Origen no permitido", code: "ORIGIN_NOT_ALLOWED" },
        403,
      );
    }

    const callerClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user: caller } } = await callerClient.auth.getUser();
    if (!caller) {
      return json({ error: "No autenticado", code: "AUTH_REQUIRED" }, 401);
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // Admin activo: una baja lógica retira la capacidad de crear personal.
    const [{ data: esAdmin }, { data: perfilActivo }] = await Promise.all([
      admin
        .from("admins")
        .select("id")
        .eq("id", caller.id)
        .is("deleted_at", null)
        .maybeSingle(),
      admin
        .from("usuarios")
        .select("id")
        .eq("id", caller.id)
        .is("deleted_at", null)
        .maybeSingle(),
    ]);

    if (!esAdmin || !perfilActivo) {
      return json({ error: "No autorizado", code: "ADMIN_REQUIRED" }, 403);
    }

    const body = await req.json() as Record<string, unknown>;
    const validacion = validarAlta(body);
    if (!validacion.ok) {
      return json({
        error: validacion.error,
        code: validacion.code,
      }, 400);
    }
    const {
      email,
      password,
      nombre,
      apellido,
      fecha_nacimiento,
      cedula,
      username,
      rol,
      especialidad,
      departamento,
      turno,
      telefono,
    } = validacion.datos;

    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        nombre,
        apellido,
        fecha_nacimiento,
        cedula,
        username,
        rol,
        especialidad,
        departamento,
        turno,
        telefono,
      },
    });

    if (error) {
      // El trigger de perfil corre dentro del INSERT de auth.users: si aborta,
      // no queda usuario autenticable. El mensaje se devuelve sin stack ni
      // detalle interno.
      console.error("admin-crear-usuario: alta rechazada", {
        rol,
        codigo: error.code ?? error.status ?? "AUTH_CREATE_FAILED",
      });
      return json({
        error: "No se pudo crear el usuario con los datos suministrados.",
        code: "USER_CREATE_REJECTED",
      }, 400);
    }

    const uuid = data.user?.id;
    if (!uuid) {
      return json({
        error: "No se pudo confirmar el usuario creado.",
        code: "USER_CREATE_INCOMPLETE",
      }, 500);
    }

    // Red de seguridad: si por cualquier vía quedara un usuario de Auth sin
    // perfil operativo, no se deja autenticable.
    const { data: perfil } = await admin
      .from("usuarios")
      .select("id")
      .eq("id", uuid)
      .maybeSingle();

    if (!perfil) {
      await admin.auth.admin.deleteUser(uuid);
      return json(
        {
          error: "El usuario no pudo aprovisionarse y se revirtió el alta.",
          code: "PROFILE_PROVISION_FAILED",
        },
        500,
      );
    }

    const { error: auditError } = await admin
      .from("auditoria_operaciones_admin")
      .insert({
        actor_id: caller.id,
        operacion: "crear_usuario",
        recurso_tipo: "usuario",
        recurso_id: uuid,
        metadata: { rol },
      });
    if (auditError) {
      await admin.auth.admin.deleteUser(uuid);
      console.error("admin-crear-usuario: auditoría rechazada", {
        codigo: auditError.code ?? "AUDIT_FAILED",
      });
      return json({
        error: "El alta no pudo auditarse y fue revertida.",
        code: "AUDIT_FAILED",
      }, 500);
    }

    console.info("admin-crear-usuario: alta completada", { rol });
    return json({ uuid }, 200);
  } catch (e) {
    // Nunca se devuelve el error interno completo al cliente.
    console.error("admin-crear-usuario: fallo inesperado", {
      tipo: e instanceof Error ? e.name : "UnknownError",
    });
    return json({
      error: "No se pudo crear el usuario.",
      code: "UNEXPECTED_ERROR",
    }, 500);
  }
});
