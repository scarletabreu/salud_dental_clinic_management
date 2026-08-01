import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

/// Lo que un actor puede hacer, con independencia de cómo se llame su rol.
///
/// Repartir `rol == RolUsuario.doctor` por las pantallas dejó fuera al
/// administrador de todo lo clínico, aunque el dominio lo declara
/// `Admin extends Doctor` y la base le da fila en `doctores`. Cada pantalla
/// pregunta aquí por la capacidad que necesita, no por el nombre del rol.
///
/// La tabla es la acordada con la clínica en HFX-CLIN-000:
///
/// | Capacidad                       | Admin | Doctor | Asistente |
/// |---------------------------------|-------|--------|-----------|
/// | Ejercer clínica                 | Sí    | Sí     | No        |
/// | Firmar actuaciones propias      | Sí    | Sí     | No        |
/// | Ver expedientes                 | Sí    | Sí     | No        |
/// | Ver contacto y gestión paciente | Sí    | No     | Sí        |
/// | Gestionar agenda completa       | Sí    | No     | Sí        |
/// | Registrar llegada               | Sí    | Sí     | Sí        |
/// | Registrar emergencia / walk-in  | Sí    | Sí     | Sí        |
/// | Administrar personal            | Sí    | No     | No        |
/// | Gestionar caja                  | Sí    | No     | Sí        |
/// | Ver catálogos clínicos          | Sí    | Sí     | No        |
/// | Editar catálogos clínicos       | Sí    | No     | No        |
/// | Ver precios de tratamiento      | Sí    | No     | Sí        |
/// | Agendar cita propia             | Sí    | Sí     | Sí        |
/// | Ver cuentas por cobrar          | Sí    | No     | Sí        |
/// | Corregir registro ajeno         | Sí    | No     | No        |
/// | Acceder a compras               | Sí    | No     | No        |
///
/// Tener más permisos no equivale a poder firmar por otro: quién puede
/// atender *una cita concreta* se resuelve además comparando UUIDs, y eso
/// vive en `CapacidadesDeSesion` porque necesita saber quién ha iniciado
/// sesión.
///
/// La jornada de QA del 1 ago 2026 obligó a partir dos capacidades que
/// agrupaban cosas distintas:
///
///   · `gestionarCatalogosClinicos` mezclaba «ver el catálogo» con
///     «editarlo». El doctor necesita consultarlo para trabajar; cambiar
///     precios y borrar tratamientos es administración (defecto D8).
///   · `gestionarAgendaCompleta` mezclaba «agendar para mí» con «agendar para
///     todos». El doctor podía agendarse a sí mismo en la base desde
///     HFX-CLIN-001, pero la pantalla lo degradaba a urgencia (defecto D10).
enum Capacidad {
  ejercerClinica,
  firmarActuacionPropia,
  verExpedientes,
  verDatosDeContactoPaciente,
  gestionarAgendaCompleta,
  registrarLlegada,
  registrarEmergencia,
  administrarPersonal,
  gestionarCaja,
  gestionarCatalogosClinicos,

  /// Cambiar el catálogo: crear, editar y retirar tratamientos, diagnósticos,
  /// procedimientos y medicinas. Sólo administración; la RLS lo impone además
  /// en la base.
  editarCatalogosClinicos,

  /// Ver lo que cuesta un tratamiento. El doctor decide qué hacer, no qué
  /// cobrar; el precio es de quien factura.
  verPreciosTratamiento,

  /// Agendar una cita normal **en la propia agenda**. No incluye agendar para
  /// otro doctor, que es `gestionarAgendaCompleta`.
  agendarCitaPropia,

  /// Entrar a Cuentas por Cobrar.
  verCuentasPorCobrar,

  corregirRegistroAjeno,
  accederACompras,
}

extension CapacidadesDeRol on RolUsuario {
  bool tiene(Capacidad capacidad) {
    switch (capacidad) {
      case Capacidad.ejercerClinica:
      case Capacidad.firmarActuacionPropia:
      case Capacidad.verExpedientes:
      case Capacidad.gestionarCatalogosClinicos:
        return this == RolUsuario.admin || this == RolUsuario.doctor;

      // Privacidad por rol (SD-149): el doctor trabaja con el expediente
      // clínico, no con el teléfono ni con la ficha administrativa.
      case Capacidad.verDatosDeContactoPaciente:
      case Capacidad.gestionarAgendaCompleta:
      case Capacidad.gestionarCaja:
      // Quien factura necesita el precio; quien trata, no.
      case Capacidad.verPreciosTratamiento:
      case Capacidad.verCuentasPorCobrar:
        return this == RolUsuario.admin || this == RolUsuario.asistente;

      case Capacidad.registrarLlegada:
      case Capacidad.registrarEmergencia:
      // Los tres roles agendan en la agenda que les corresponde. Para el
      // doctor, la suya: el selector de doctor queda fijo en él.
      case Capacidad.agendarCitaPropia:
        return true;

      case Capacidad.administrarPersonal:
      case Capacidad.corregirRegistroAjeno:
      case Capacidad.accederACompras:
      case Capacidad.editarCatalogosClinicos:
        return this == RolUsuario.admin;
    }
  }
}

extension CapacidadesDeRoles on List<RolUsuario> {
  bool puede(Capacidad capacidad) => any((rol) => rol.tiene(capacidad));

  bool get puedeEjercerClinica => puede(Capacidad.ejercerClinica);
  bool get puedeFirmarActuacionPropia => puede(Capacidad.firmarActuacionPropia);
  bool get puedeVerDatosDeContactoPaciente =>
      puede(Capacidad.verDatosDeContactoPaciente);
  bool get puedeGestionarAgendaCompleta =>
      puede(Capacidad.gestionarAgendaCompleta);
  bool get puedeRegistrarLlegada => puede(Capacidad.registrarLlegada);
  bool get puedeRegistrarEmergencia => puede(Capacidad.registrarEmergencia);
  bool get puedeAdministrarPersonal => puede(Capacidad.administrarPersonal);
  bool get puedeGestionarCaja => puede(Capacidad.gestionarCaja);
  bool get puedeGestionarCatalogosClinicos =>
      puede(Capacidad.gestionarCatalogosClinicos);
  bool get puedeEditarCatalogosClinicos =>
      puede(Capacidad.editarCatalogosClinicos);
  bool get puedeVerPreciosTratamiento =>
      puede(Capacidad.verPreciosTratamiento);
  bool get puedeAgendarCitaPropia => puede(Capacidad.agendarCitaPropia);
  bool get puedeVerCuentasPorCobrar => puede(Capacidad.verCuentasPorCobrar);
  bool get puedeCorregirRegistroAjeno =>
      puede(Capacidad.corregirRegistroAjeno);

  bool get puedeVerExpedientes => puede(Capacidad.verExpedientes);
  bool get puedeAccederACompras => puede(Capacidad.accederACompras);

  /// Alertas del paciente y recetas son contenido clínico: las escribe quien
  /// ejerce, y las firma con su propio nombre.
  bool get puedeEditarAlertasYRecetas => puede(Capacidad.ejercerClinica);
}
