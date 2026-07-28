import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/entities/alerta_operativa.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/entidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/severidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/tipo_alerta.dart';

const _rolesOperativos = [RolUsuario.admin, RolUsuario.asistente];

const _rolesClinicos = [
  RolUsuario.admin,
  RolUsuario.doctor,
  RolUsuario.asistente,
];

const _horaLimiteAperturaCaja = 8;

const _ventanaMinutosProxima = 60;

class AlertaOperativaGenerator {
  const AlertaOperativaGenerator();

  List<AlertaOperativa> generar({
    required List<Cita> citasDeHoy,
    List<Consumible> consumibles = const [],
    List<Equipo> equipos = const [],
    CajaDiaria? cajaActual,
    required DateTime ahora,
  }) {
    final alertas = <AlertaOperativa>[
      ..._alertasDeCitas(citasDeHoy, ahora),
      ..._alertasDeInventario(consumibles, ahora),
      ..._alertasDeEquipos(equipos, ahora),
      ..._alertasDeCaja(cajaActual, ahora),
    ];

    alertas.sort((a, b) {
      final porSeveridad = a.severidad.prioridad.compareTo(
        b.severidad.prioridad,
      );
      if (porSeveridad != 0) return porSeveridad;
      return a.timestamp.compareTo(b.timestamp);
    });

    return alertas;
  }

  List<AlertaOperativa> _alertasDeEquipos(
    List<Equipo> equipos,
    DateTime ahora,
  ) {
    return equipos
        .where((equipo) => equipo.id != null)
        .where((equipo) => equipo.mantenimientoVencidoEn(ahora))
        .map((equipo) {
          final dias = equipo.diasParaMantenimiento(ahora).abs();
          return AlertaOperativa(
            id: 'mantenimiento_vencido_${equipo.id}',
            tipo: TipoAlerta.mantenimientoVencido,
            severidad: SeveridadAlerta.alta,
            titulo: '${equipo.nombre}: mantenimiento vencido',
            descripcion: dias == 0
                ? 'El mantenimiento corresponde hoy'
                : 'Vencido hace $dias día${dias == 1 ? '' : 's'}',
            entidadTipo: EntidadAlerta.equipo,
            entidadId: equipo.id,
            rolesAutorizados: _rolesOperativos,
            timestamp: equipo.proximoMantenimiento,
          );
        })
        .toList();
  }

  List<AlertaOperativa> _alertasDeCitas(List<Cita> citas, DateTime ahora) {
    final alertas = <AlertaOperativa>[];

    for (final cita in citas) {
      if (cita.id == null) continue;
      final nombrePersona = '${cita.persona.nombre} ${cita.persona.apellido}';
      final nombreDoctor = '${cita.doctor.nombre} ${cita.doctor.apellido}';

      if (cita.estado == EstadoCita.enEspera) {
        final minutosEsperando = ahora.difference(cita.date).inMinutes;
        alertas.add(
          AlertaOperativa(
            id: 'cita_espera_${cita.id}',
            tipo: TipoAlerta.citaEnEspera,
            severidad: minutosEsperando >= 20
                ? SeveridadAlerta.critica
                : minutosEsperando >= 10
                ? SeveridadAlerta.alta
                : SeveridadAlerta.media,
            titulo: '$nombrePersona en espera',
            descripcion: minutosEsperando > 0
                ? 'Esperando hace $minutosEsperando min · $nombreDoctor'
                : 'Recién registrado · $nombreDoctor',
            entidadTipo: EntidadAlerta.cita,
            entidadId: cita.id,
            rolesAutorizados: _rolesClinicos,
            esClinicamenteSensible: true,
            timestamp: cita.date,
          ),
        );
        continue;
      }

      if (cita.estado == EstadoCita.programada) {
        final minutosParaLaCita = cita.date.difference(ahora).inMinutes;
        final esProxima =
            minutosParaLaCita >= 0 &&
            minutosParaLaCita <= _ventanaMinutosProxima;
        if (esProxima) {
          alertas.add(
            AlertaOperativa(
              id: 'cita_proxima_${cita.id}',
              tipo: TipoAlerta.citaProxima,
              severidad: minutosParaLaCita <= 15
                  ? SeveridadAlerta.alta
                  : SeveridadAlerta.media,
              titulo: '$nombrePersona en $minutosParaLaCita min',
              descripcion:
                  'Cita con $nombreDoctor a las ${_formatHora(cita.date)}',
              entidadTipo: EntidadAlerta.cita,
              entidadId: cita.id,
              rolesAutorizados: _rolesClinicos,
              esClinicamenteSensible: true,
              timestamp: cita.date,
            ),
          );
        }
      }
    }

    return alertas;
  }

  List<AlertaOperativa> _alertasDeInventario(
    List<Consumible> consumibles,
    DateTime ahora,
  ) {
    final alertas = <AlertaOperativa>[];

    for (final consumible in consumibles) {
      if (consumible.id == null) continue;

      if (consumible.estaAgotado) {
        alertas.add(
          AlertaOperativa(
            id: 'inventario_agotado_${consumible.id}',
            tipo: TipoAlerta.inventarioAgotado,
            severidad: SeveridadAlerta.critica,
            titulo: '${consumible.nombre} agotado',
            descripcion:
                'Existencia en 0 · mínimo requerido ${consumible.stockMinimo}',
            entidadTipo: EntidadAlerta.consumible,
            entidadId: consumible.id,
            rolesAutorizados: _rolesOperativos,
            timestamp: ahora,
          ),
        );
      } else if (consumible.estaBajoStock) {
        alertas.add(
          AlertaOperativa(
            id: 'inventario_bajo_${consumible.id}',
            tipo: TipoAlerta.inventarioBajo,
            severidad: SeveridadAlerta.alta,
            titulo: '${consumible.nombre} con stock bajo',
            descripcion:
                '${consumible.stockActual} unidades · mínimo ${consumible.stockMinimo}',
            entidadTipo: EntidadAlerta.consumible,
            entidadId: consumible.id,
            rolesAutorizados: _rolesOperativos,
            timestamp: ahora,
          ),
        );
      }
    }

    return alertas;
  }

  List<AlertaOperativa> _alertasDeCaja(CajaDiaria? cajaActual, DateTime ahora) {
    final horaLimite = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      _horaLimiteAperturaCaja,
    );

    if (cajaActual == null && ahora.isAfter(horaLimite)) {
      return [
        AlertaOperativa(
          id: 'caja_no_aperturada_${_soloFecha(ahora)}',
          tipo: TipoAlerta.cajaNoAperturada,
          severidad: SeveridadAlerta.alta,
          titulo: 'Caja del día sin abrir',
          descripcion: 'No se ha registrado apertura de caja para hoy',
          entidadTipo: EntidadAlerta.cajaDiaria,
          rolesAutorizados: _rolesOperativos,
          timestamp: horaLimite,
        ),
      ];
    }

    return const [];
  }

  String _formatHora(DateTime date) {
    final hora = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minuto = date.minute.toString().padLeft(2, '0');
    final periodo = date.hour >= 12 ? 'PM' : 'AM';
    return '$hora:$minuto $periodo';
  }

  String _soloFecha(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
