import 'package:salud_dental_clinic_management/features/auth/domain/capacidades_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';

/// Capacidades resueltas contra la sesión abierta.
///
/// Las de `CapacidadesDeRoles` sólo miran el rol. Las de aquí necesitan además
/// saber *quién* está conectado, porque el contrato clínico distingue dos cosas
/// que antes se confundían: un administrador ve toda la agenda, pero eso no le
/// permite firmar la consulta de otro doctor. Poder mirar no es poder firmar.
extension CapacidadesDeSesion on AuthState {
  bool get puedeEjercerClinica => roles.puedeEjercerClinica;
  bool get puedeVerExpedientes => roles.puedeVerExpedientes;
  bool get puedeVerDatosDeContactoPaciente =>
      roles.puedeVerDatosDeContactoPaciente;
  bool get puedeGestionarAgendaCompleta => roles.puedeGestionarAgendaCompleta;
  bool get puedeRegistrarLlegada => roles.puedeRegistrarLlegada;
  bool get puedeRegistrarEmergencia => roles.puedeRegistrarEmergencia;
  bool get puedeAdministrarPersonal => roles.puedeAdministrarPersonal;
  bool get puedeGestionarCaja => roles.puedeGestionarCaja;
  bool get puedeGestionarCatalogosClinicos =>
      roles.puedeGestionarCatalogosClinicos;
  bool get puedeCorregirRegistroAjeno => roles.puedeCorregirRegistroAjeno;

  /// Atender una cita exige ser clínico **y** ser el doctor asignado.
  ///
  /// El admin entra por la primera condición —tiene fila en `doctores` desde
  /// HFX-CLIN-000— pero sigue sujeto a la segunda: sólo firma lo suyo.
  bool puedeAtenderCitaDe(String? doctorAsignadoId) {
    if (!puedeEjercerClinica) return false;
    final actorId = usuario?.id;
    if (actorId == null || doctorAsignadoId == null) return false;
    return actorId == doctorAsignadoId;
  }

  /// Qué agenda ve el actor: la completa, o sólo la suya.
  ///
  /// Devuelve `null` cuando no hay restricción por doctor (agenda completa),
  /// que es lo que esperan los cubits de citas y consultas.
  String? get doctorIdParaFiltrarAgenda {
    if (puedeGestionarAgendaCompleta) return null;
    return puedeEjercerClinica ? usuario?.id : null;
  }
}
