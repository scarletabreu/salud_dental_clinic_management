import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

/// Por qué no se puede iniciar la consulta de una cita, si es que no se puede.
///
/// Es un tipo y no un `bool` porque las tres pantallas que ofrecían el botón lo
/// decidían cada una por su cuenta y con criterios distintos (defecto D14 de la
/// jornada de QA del 1 ago 2026): la lista exigía estado **y** ser el doctor
/// asignado, la vista de línea de tiempo sólo miraba el estado, y la tarjeta de
/// «siguiente paciente» no miraba ninguno de los dos. El admin con una cita
/// propia se quedaba mirando un botón que no aparecía en un sitio y que en otro
/// moría con `CL015`.
enum MotivoNoIniciable {
  /// El rol no ejerce clínica, o la cita es de otro doctor.
  noEsSuCita,

  /// El paciente todavía no está dado por presente.
  faltaRegistrarLlegada,

  /// La cita ya pasó por consulta, se canceló o no se presentó.
  estadoTerminal,

  /// Faltan datos de la propia cita (id, paciente o doctor).
  citaIncompleta,
}

extension MotivoNoIniciableX on MotivoNoIniciable {
  /// Qué decirle a quien está delante. Se muestra tal cual: un botón que no
  /// aparece y no explica nada es lo que hacía pensar que la app estaba rota.
  String get mensaje => switch (this) {
    MotivoNoIniciable.noEsSuCita =>
      'Esta cita está asignada a otro odontólogo. Sólo quien la atiende puede '
          'iniciar su consulta.',
    MotivoNoIniciable.faltaRegistrarLlegada =>
      'Registra primero la llegada del paciente: la consulta se inicia cuando '
          'ya está en la clínica.',
    MotivoNoIniciable.estadoTerminal =>
      'Esta cita ya no admite iniciar consulta por su estado actual.',
    MotivoNoIniciable.citaIncompleta =>
      'La cita no tiene todos los datos necesarios para abrir una consulta.',
  };
}

/// La única respuesta a «¿se puede iniciar la consulta de esta cita?».
///
/// Las tres vistas la consultan; la RPC `iniciar_consulta_de_cita` sigue siendo
/// quien decide de verdad, y su mensaje (`CL015`, `42501`) se muestra tal cual
/// si aun así rechaza.
class PuedeIniciarConsulta {
  final bool permitido;
  final MotivoNoIniciable? motivo;

  const PuedeIniciarConsulta._(this.permitido, this.motivo);

  static const _si = PuedeIniciarConsulta._(true, null);

  factory PuedeIniciarConsulta.evaluar(AuthState sesion, Cita cita) {
    if (cita.id == null || cita.persona.id == null || cita.doctor.id == null) {
      return const PuedeIniciarConsulta._(
        false,
        MotivoNoIniciable.citaIncompleta,
      );
    }
    if (!sesion.puedeAtenderCitaDe(cita.doctor.id)) {
      return const PuedeIniciarConsulta._(false, MotivoNoIniciable.noEsSuCita);
    }
    if (cita.estado == EstadoCita.enEspera) return _si;

    // `programada` y `confirmada` no son un callejón sin salida: falta el paso
    // de registrar la llegada, y eso el doctor de la cita sí puede hacerlo.
    if (cita.estado == EstadoCita.programada ||
        cita.estado == EstadoCita.confirmada) {
      return const PuedeIniciarConsulta._(
        false,
        MotivoNoIniciable.faltaRegistrarLlegada,
      );
    }
    return const PuedeIniciarConsulta._(
      false,
      MotivoNoIniciable.estadoTerminal,
    );
  }

  /// `true` cuando lo único que falta es dar por presente al paciente. Las
  /// pantallas lo usan para poner delante «Registrar llegada» en vez de
  /// esconder toda acción.
  bool get faltaLlegada => motivo == MotivoNoIniciable.faltaRegistrarLlegada;
}
