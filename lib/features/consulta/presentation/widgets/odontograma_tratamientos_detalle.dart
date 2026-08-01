import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_expediente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/pages/expediente_page.dart';

class OdontogramaTratamientosDetalle extends StatelessWidget {
  final Consulta consulta;
  final String nombrePaciente;

  const OdontogramaTratamientosDetalle({
    super.key,
    required this.consulta,
    required this.nombrePaciente,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final odontograma = consulta.odontograma;

    if (odontograma == null || odontograma.dientes.isEmpty) {
      return Text(
        'Esta consulta no tiene odontograma registrado.',
        style: TextStyle(color: ac.textMuted, fontSize: 13),
      );
    }

    final dientesConTratamientos =
        odontograma.dientes
            .where((d) => d.tratamientosAplicadosIds.isNotEmpty)
            .toList()
          ..sort((a, b) => a.fdiCode.compareTo(b.fdiCode));

    final historial = _historialImprimible(context);

    return BlocBuilder<ConsultaDetalleCubit, ConsultaDetalleState>(
      builder: (context, state) {
        final listo = state is ConsultaDetalleListo ? state : null;
        return VistasOdontograma(
          odontograma: odontograma,
          historialPiezas: listo?.historialPiezas,
          formularioPersonalizado: OdontodiagramaExpediente(
            // `evaluacion` sólo guarda los tejidos blandos —así lo define
            // `evaluacionToJson`—, de modo que pasarla dejaba el odontodiagrama
            // de esta vista sin un solo hallazgo, y su «Imprimir
            // Odontodiagrama» en blanco (defecto D6c). Lo que describe la boca
            // es la proyección de los tres ejes.
            evaluacion: odontograma.evaluacionProyectada,
            // La proyección solo conserva las siete claves del papel; las
            // piezas traen además lo que el catálogo no supo clasificar, que
            // es la mayor parte de lo que se ejecuta.
            dientes: {
              for (final diente in odontograma.dientes) diente.fdiCode: diente,
            },
            // Lo de arcada o cuadrante no cuelga de ninguna pieza: si la hoja
            // no lo nombrara, una consulta de sola limpieza se imprimiría en
            // blanco y parecería que no se registró nada. Sale del cubit y no
            // de `consulta`, porque la del listado nunca trae los generales.
            generales: listo?.generales ?? const [],
            nombrePaciente: nombrePaciente,
            fecha: consulta.fecha,
            // Imprimir desde aquí sacaba siempre la hoja de esta consulta y
            // nada más: el historial entero solo se alcanzaba saliendo al
            // expediente del paciente. Ahora se elige en el propio botón.
            onImprimirHistorial: historial.accion,
            avisoHistorial: historial.aviso,
          ),
          pie: dientesConTratamientos.isEmpty
              ? Text(
                  'No se registraron tratamientos en esta consulta.',
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
                )
              : listo == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final diente in dientesConTratamientos)
                      _filaDiente(context, diente, listo),
                  ],
                ),
        );
      },
    );
  }

  /// Si desde esta consulta se puede llevar al papel el expediente entero.
  ///
  /// Devuelve las dos caras de la misma pregunta: la acción cuando se puede, y
  /// el motivo cuando todavía no. Sin motivo **ni** acción la opción no se
  /// ofrece: quien no puede ver expedientes no debe verla ni siquiera apagada.
  ({VoidCallback? accion, String? aviso}) _historialImprimible(
    BuildContext context,
  ) {
    const nada = (accion: null, aviso: null);

    // Ambos cubits son de la pantalla que monta este widget, no suyos: fuera de
    // ella —o en un test que solo dibuja el odontograma— simplemente no hay
    // historial que ofrecer.
    final bool puedeVerExpedientes;
    final PacienteState estado;
    try {
      puedeVerExpedientes = context.select(
        (AuthCubit cubit) => cubit.state.puedeVerExpedientes,
      );
      estado = context.watch<PacienteCubit>().state;
    } catch (_) {
      return nada;
    }
    if (!puedeVerExpedientes) return nada;

    if (estado is! PacienteDetailLoaded) {
      return (
        accion: null,
        aviso: 'Todavía se está cargando el expediente del paciente.',
      );
    }
    // Un historial que no cargó se ve igual que un paciente sin consultas: si
    // se imprimiera, el expediente afirmaría en papel que no hay nada.
    if (estado.historialNoDisponible) {
      return (
        accion: null,
        aviso: 'El historial del paciente no se pudo cargar.',
      );
    }

    final paciente = estado.paciente;
    final historialPiezas = estado.historialPiezas;
    final consultasConOdontograma = paciente.record.consultas
        .where((c) => c.odontograma != null)
        .toList();

    return (
      accion: () => ExpedientePage.navegar(
        context,
        paciente: paciente,
        // La primera del historial es la más reciente: es la boca de hoy.
        odontogramaActual: consultasConOdontograma.isNotEmpty
            ? consultasConOdontograma.first.odontograma
            : null,
        consultasConOdontograma: consultasConOdontograma,
        historialPiezas: historialPiezas,
      ),
      aviso: null,
    );
  }

  Widget _filaDiente(
    BuildContext context,
    Diente diente,
    ConsultaDetalleListo state,
  ) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: ac.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${diente.fdiCode}',
              style: TextStyle(
                color: ac.teal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in diente.tratamientosAplicadosIds)
                  _filaTratamiento(context, id, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTratamiento(
    BuildContext context,
    String id,
    ConsultaDetalleListo state,
  ) {
    final ac = context.appColors;
    final detalle = state.detalleDe(id);
    final nombre = detalle?.nombre ?? 'Tratamiento';
    final superficie = detalle?.tratamiento.superficie?.name;
    final precio = detalle?.precio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.healing_rounded, size: 15, color: ac.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (superficie != null)
                  Text(
                    'Superficie $superficie',
                    style: TextStyle(color: ac.textMuted, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            precio != null ? formatMoneda(precio) : '—',
            style: TextStyle(
              color: precio != null ? ac.textSecondary : ac.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
