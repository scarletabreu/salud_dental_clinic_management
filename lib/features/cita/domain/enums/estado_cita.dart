import 'package:flutter/material.dart';

/// Ciclo de vida de una cita. Los nombres coinciden 1:1 con el enum
/// `estado_cita` de Postgres (en snake_case): ver `supabase/sd-81_estados_cita.sql`.
enum EstadoCita {
  programada,
  confirmada,
  enEspera,
  enConsulta,
  completada,
  cancelada,
  noAsistio;

  /// Valor tal cual se guarda en la columna `estado` de Postgres.
  String get dbValue {
    switch (this) {
      case EstadoCita.enEspera:
        return 'en_espera';
      case EstadoCita.enConsulta:
        return 'en_consulta';
      case EstadoCita.noAsistio:
        return 'no_asistio';
      default:
        return name;
    }
  }

  static EstadoCita fromDb(String? valor) {
    switch (valor) {
      case 'en_espera':
        return EstadoCita.enEspera;
      case 'en_consulta':
        return EstadoCita.enConsulta;
      case 'no_asistio':
        return EstadoCita.noAsistio;
      // Valores heredados (antes de la migración SD-81), por si quedan filas.
      case 'pendiente':
        return EstadoCita.programada;
      case 'atendida':
        return EstadoCita.completada;
      default:
        return EstadoCita.values.firstWhere(
          (e) => e.name == valor,
          orElse: () => EstadoCita.programada,
        );
    }
  }

  /// Estados a los que un rol concreto puede llevar esta cita **desde el
  /// desplegable**.
  ///
  /// Es la intersección del grafo de estados con la matriz de roles que fijó
  /// QA el 1 ago 2026 (defecto D12). Antes el desplegable ofrecía el grafo
  /// entero a cualquiera que gestionara la agenda, y la base tampoco lo
  /// recortaba; ahora `puede_cambiar_estado_cita` lo impone en SQL y esto es
  /// su reflejo en pantalla.
  ///
  /// `enConsulta` y `completada` nunca salen: los produce una RPC clínica al
  /// iniciar y cerrar la consulta, no una elección de menú.
  List<EstadoCita> transicionesParaRol({
    required bool esAdmin,
    required bool esDoctorDeLaCita,
    required bool esAsistenteAsignada,
  }) {
    const clinicos = [EstadoCita.enConsulta, EstadoCita.completada];
    final legales = transicionesPermitidas.where((e) => !clinicos.contains(e));

    if (esAdmin) return legales.toList();

    if (esAsistenteAsignada) {
      // Reprogramar no aparece porque no es un estado: es mover la fecha y
      // la hora de la cita, que sigue en el estado en que estaba.
      const administrativos = [
        EstadoCita.confirmada,
        EstadoCita.enEspera,
        EstadoCita.cancelada,
        EstadoCita.noAsistio,
      ];
      return legales.where(administrativos.contains).toList();
    }

    if (esDoctorDeLaCita) {
      // Lo clínico de su propia cita: dar por presente al paciente y cancelar.
      const propios = [EstadoCita.enEspera, EstadoCita.cancelada];
      return legales.where(propios.contains).toList();
    }

    return const [];
  }

  /// Estados a los que esta cita puede transicionar legalmente.
  /// Los estados terminales (completada, cancelada, noAsistio) devuelven `[]`.
  List<EstadoCita> get transicionesPermitidas {
    switch (this) {
      case EstadoCita.programada:
        return const [
          EstadoCita.confirmada,
          EstadoCita.cancelada,
          EstadoCita.noAsistio,
        ];
      case EstadoCita.confirmada:
        return const [
          EstadoCita.enEspera,
          EstadoCita.cancelada,
          EstadoCita.noAsistio,
        ];
      case EstadoCita.enEspera:
        return const [
          // Sin esta arista `enConsulta` queda inalcanzable y toda consulta
          // abierta desde una cita falla al intentar marcarla (regresión de
          // 8729c4d, cubierta por el test del grafo de SD-81).
          EstadoCita.enConsulta,
          EstadoCita.cancelada,
          EstadoCita.noAsistio,
        ];
      case EstadoCita.enConsulta:
        return const [EstadoCita.completada, EstadoCita.cancelada];
      case EstadoCita.completada:
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:
        return const [];
    }
  }

  bool puedeTransicionarA(EstadoCita destino) =>
      transicionesPermitidas.contains(destino);

  Color get color {
    switch (this) {
      case EstadoCita.programada:
        return const Color(0xFF6366F1);
      case EstadoCita.confirmada:
        return const Color(0xFF06B6D4);
      case EstadoCita.enEspera:
        return const Color(0xFFF59E0B);
      case EstadoCita.enConsulta:
        return const Color(0xFF3B82F6);
      case EstadoCita.completada:
        return const Color(0xFF10B981);
      case EstadoCita.cancelada:
        return const Color(0xFFEF4444);
      case EstadoCita.noAsistio:
        return const Color(0xFF6B7280);
    }
  }

  String get label {
    switch (this) {
      case EstadoCita.programada:
        return 'Programada';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.enEspera:
        return 'En Espera';
      case EstadoCita.enConsulta:
        return 'En Consulta';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.noAsistio:
        return 'No Asistió';
    }
  }
}
