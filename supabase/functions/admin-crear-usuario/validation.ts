export const ROLES_VALIDOS = ["admin", "doctor", "asistente"] as const;
export type Rol = typeof ROLES_VALIDOS[number];

export type DatosAlta = {
  email: string;
  password: string;
  nombre: string;
  apellido: string;
  fecha_nacimiento: string;
  cedula: string;
  username: string;
  rol: Rol;
  especialidad?: string;
  departamento?: string;
  turno?: string;
  telefono: string | null;
};

export type ResultadoValidacion =
  | { ok: true; datos: DatosAlta }
  | { ok: false; error: string; code: "INVALID_INPUT" | "INVALID_ROLE" };

export function origenPermitido(
  origin: string | null,
  listaConfigurada: string,
): boolean {
  const permitidos = listaConfigurada.split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return origin === null || permitidos.length === 0 ||
    permitidos.includes(origin);
}

function extraerTelefono(body: Record<string, unknown>): string | null {
  const suelto = body.telefono;
  if (typeof suelto === "string" && suelto.trim() !== "") return suelto.trim();

  const contactos = body.contactos;
  if (Array.isArray(contactos)) {
    for (const contacto of contactos) {
      const numero = (contacto as Record<string, unknown> | null)
        ?.numero_telefono;
      if (typeof numero === "string" && numero.trim() !== "") {
        return numero.trim();
      }
    }
  }
  return null;
}

export function validarAlta(
  body: Record<string, unknown>,
): ResultadoValidacion {
  const requeridos = [
    "email",
    "password",
    "nombre",
    "apellido",
    "fecha_nacimiento",
    "cedula",
    "username",
    "rol",
  ] as const;
  const faltantes = requeridos.filter((campo) =>
    typeof body[campo] !== "string" ||
    (body[campo] as string).trim() === ""
  );

  if (faltantes.length > 0) {
    return {
      ok: false,
      error: `Faltan datos obligatorios: ${faltantes.join(", ")}.`,
      code: "INVALID_INPUT",
    };
  }

  const rol = body.rol as string;
  if (!ROLES_VALIDOS.includes(rol as Rol)) {
    return { ok: false, error: "Rol inválido.", code: "INVALID_ROLE" };
  }
  if (
    rol === "asistente" &&
    (typeof body.turno !== "string" || body.turno.trim() === "")
  ) {
    return {
      ok: false,
      error: "Un asistente necesita turno.",
      code: "INVALID_INPUT",
    };
  }
  if (
    (rol === "doctor" || rol === "admin") &&
    (typeof body.especialidad !== "string" ||
      body.especialidad.trim() === "")
  ) {
    return {
      ok: false,
      error: "Un doctor o administrador necesita especialidad.",
      code: "INVALID_INPUT",
    };
  }
  if (
    rol === "admin" &&
    (typeof body.departamento !== "string" ||
      body.departamento.trim() === "")
  ) {
    return {
      ok: false,
      error: "Un administrador necesita departamento.",
      code: "INVALID_INPUT",
    };
  }

  return {
    ok: true,
    datos: {
      email: (body.email as string).trim(),
      password: body.password as string,
      nombre: (body.nombre as string).trim(),
      apellido: (body.apellido as string).trim(),
      fecha_nacimiento: (body.fecha_nacimiento as string).trim(),
      cedula: (body.cedula as string).trim(),
      username: (body.username as string).trim(),
      rol: rol as Rol,
      especialidad: typeof body.especialidad === "string"
        ? body.especialidad.trim()
        : undefined,
      departamento: typeof body.departamento === "string"
        ? body.departamento.trim()
        : undefined,
      turno: typeof body.turno === "string" ? body.turno.trim() : undefined,
      telefono: extraerTelefono(body),
    },
  };
}
