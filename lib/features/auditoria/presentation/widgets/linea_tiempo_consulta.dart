import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/cubit/linea_tiempo_cubit.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/cubit/linea_tiempo_state.dart';

/// Historia de una consulta: qué se hizo, quién lo hizo y cuándo.
///
/// La lee de `linea_tiempo_consulta`, que ya incluye lo ocurrido en la agenda
/// antes de que la consulta existiera. Cada evento se anuncia como una sola
/// frase para el lector de pantalla —acción, actor y fecha— porque leerlo en
/// tres fragmentos sueltos no cuenta nada.
class LineaTiempoConsulta extends StatelessWidget {
  const LineaTiempoConsulta({super.key, required this.consultaId});

  final String consultaId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LineaTiempoCubit(sl())..cargar(consultaId),
      child: LineaTiempoConsultaVista(consultaId: consultaId),
    );
  }
}

/// La vista sin el cubit: espera encontrar un [LineaTiempoCubit] arriba. Es lo
/// que permite montarla en pruebas sin arrancar el service locator.
class LineaTiempoConsultaVista extends StatelessWidget {
  const LineaTiempoConsultaVista({super.key, required this.consultaId});

  final String consultaId;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocBuilder<LineaTiempoCubit, LineaTiempoState>(
      builder: (context, state) => switch (state) {
        LineaTiempoInicial() || LineaTiempoCargando() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        LineaTiempoError(:final mensaje) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: ac.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(fontSize: 13, color: ac.red, height: 1.4),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<LineaTiempoCubit>().cargar(consultaId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        LineaTiempoCargada(:final eventos) when eventos.isEmpty => Text(
          'Esta consulta todavía no tiene eventos registrados.',
          style: TextStyle(fontSize: 13, color: ac.textMuted),
        ),
        LineaTiempoCargada(:final eventos) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < eventos.length; i++)
              _FilaEvento(
                evento: eventos[i],
                esUltimo: i == eventos.length - 1,
              ),
          ],
        ),
      },
    );
  }
}

class _FilaEvento extends StatelessWidget {
  const _FilaEvento({required this.evento, required this.esUltimo});

  final EventoAuditoria evento;
  final bool esUltimo;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (color, icono) = _aspecto(ac, evento.categoria);
    final hora = _hora(evento.ocurridoEn);
    final fecha = fechaCortaEs(evento.ocurridoEn);

    return Semantics(
      container: true,
      label: [
        evento.descripcion,
        evento.autor,
        '$fecha a las $hora',
        if ((evento.motivo ?? '').trim().isNotEmpty) 'Motivo: ${evento.motivo}',
      ].join('. '),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  // El icono acompaña al color: el riesgo y la categoría no
                  // pueden depender sólo del tono (HFX-CLIN-005).
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icono, size: 14, color: color),
                  ),
                  if (!esUltimo)
                    Expanded(
                      child: Container(width: 1.5, color: ac.divider),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.descripcion,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ac.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          Text(
                            evento.autor,
                            style: TextStyle(
                              fontSize: 12,
                              color: ac.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$fecha · $hora',
                            style: TextStyle(fontSize: 12, color: ac.textMuted),
                          ),
                        ],
                      ),
                      if ((evento.motivo ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Motivo: ${evento.motivo!.trim()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ac.textSecondary,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _aspecto(AppColors ac, CategoriaEvento categoria) =>
      switch (categoria) {
        CategoriaEvento.agenda => (ac.teal, Icons.event_available_rounded),
        CategoriaEvento.clinico => (ac.indigo, Icons.healing_rounded),
        CategoriaEvento.plan => (ac.primaryGreen, Icons.fact_check_rounded),
        CategoriaEvento.receta => (ac.purple, Icons.receipt_long_rounded),
        CategoriaEvento.alerta => (ac.amber, Icons.warning_amber_rounded),
        CategoriaEvento.correccion => (ac.red, Icons.edit_note_rounded),
      };

  String _hora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
