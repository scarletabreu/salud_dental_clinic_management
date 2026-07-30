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
/// | Gestionar catálogos clínicos    | Sí    | Sí     | No        |
/// | Corregir registro ajeno         | Sí    | No     | No        |
/// | Acceder a compras               | Sí    | No     | No        |
///
/// Tener más permisos no equivale a poder firmar por otro: quién puede
/// atender *una cita concreta* se resuelve además comparando UUIDs, y eso
/// vive en `CapacidadesDeSesion` porque necesita saber quién ha iniciado
/// sesión.
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
        return this == RolUsuario.admin || this == RolUsuario.asistente;

      case Capacidad.registrarLlegada:
      case Capacidad.registrarEmergencia:
        return true;

      case Capacidad.administrarPersonal:
      case Capacidad.corregirRegistroAjeno:
      case Capacidad.accederACompras:
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
  bool get puedeCorregirRegistroAjeno =>
      puede(Capacidad.corregirRegistroAjeno);

  bool get puedeVerExpedientes => puede(Capacidad.verExpedientes);
  bool get puedeAccederACompras => puede(Capacidad.accederACompras);

  /// Alertas del paciente y recetas son contenido clínico: las escribe quien
  /// ejerce, y las firma con su propio nombre.
  bool get puedeEditarAlertasYRecetas => puede(Capacidad.ejercerClinica);
}
