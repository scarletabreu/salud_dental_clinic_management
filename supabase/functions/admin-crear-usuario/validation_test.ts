import { origenPermitido, validarAlta } from "./validation.ts";

const base = {
  email: "admin@local.test",
  password: "Secret-123!",
  nombre: "Ana",
  apellido: "Admin",
  fecha_nacimiento: "1980-01-01",
  cedula: "001-0000000-1",
  username: "aadmin",
};

Deno.test("exige los atributos del rol antes de tocar Auth", () => {
  const admin = validarAlta({ ...base, rol: "admin", especialidad: "General" });
  if (admin.ok) throw new Error("aceptó un admin sin departamento");
  if (admin.code !== "INVALID_INPUT") throw new Error("código inestable");

  const doctor = validarAlta({ ...base, rol: "doctor" });
  if (doctor.ok) throw new Error("aceptó un doctor sin especialidad");

  const asistente = validarAlta({ ...base, rol: "asistente" });
  if (asistente.ok) throw new Error("aceptó un asistente sin turno");
});

Deno.test("normaliza el alta válida sin registrar la contraseña", () => {
  const resultado = validarAlta({
    ...base,
    rol: "admin",
    especialidad: " General ",
    departamento: " Clínica ",
    contactos: [{ numero_telefono: " 809-555-0101 " }],
  });
  if (!resultado.ok) throw new Error(resultado.error);
  if (resultado.datos.telefono !== "809-555-0101") {
    throw new Error("no normalizó el teléfono");
  }
  if (resultado.datos.departamento !== "Clínica") {
    throw new Error("no normalizó el departamento");
  }
});

Deno.test("la allowlist CORS rechaza un origen ajeno", () => {
  const lista = "https://clinica.example, https://admin.example";
  if (!origenPermitido("https://clinica.example", lista)) {
    throw new Error("rechazó un origen configurado");
  }
  if (origenPermitido("https://evil.example", lista)) {
    throw new Error("aceptó un origen ajeno");
  }
});
