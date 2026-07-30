import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

/// Ventana flotante con lo que hace falta saber de una cita sin abrirla (SD-146):
/// paciente, doctor, horario, duración, estado, emergencia y qué se piensa
/// tratar.
///
/// Se muestra al pasar el cursor por encima, pero el ratón no es la única vía:
/// [ResumenCitaAccesible] la abre también al recibir el foco del teclado, y
/// [mostrarResumenCita] la ofrece como diálogo para pantallas táctiles, donde no
/// existe el hover. El mismo contenido por los tres caminos.
class TarjetaResumenCita extends StatelessWidget {
  const TarjetaResumenCita({
    super.key,
    required this.cita,
    this.flotante = true,
  });

  final Cita cita;

  /// `true` cuando se pinta suspendida sobre la agenda (hover/foco): añade
  /// fondo, borde y sombra. En un diálogo eso duplicaría el marco.
  final bool flotante;

  static String _hhmm(DateTime fecha) =>
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';

  static String _duracion(int minutos) {
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    final enHoras = horas == 1 ? '1 h' : '$horas h';
    return resto == 0 ? enHoras : '$enHoras $resto min';
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final actividades = cita.resumenActividades;
    final motivo = cita.motivo?.trim() ?? '';

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cita.persona.fullName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ac.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}',
          style: TextStyle(fontSize: 12, color: ac.textMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Etiqueta(
              icono: Icons.access_time_rounded,
              texto:
                  '${_hhmm(cita.date)} – ${_hhmm(cita.fechaFin)}'
                  ' · ${_duracion(cita.duracionMinutos)}',
              color: ac.textSecondary,
            ),
            _Etiqueta(
              icono: Icons.circle,
              texto: cita.estado.label,
              color: cita.estado.color,
            ),
            if (cita.esEmergencia)
              _Etiqueta(
                icono: Icons.priority_high_rounded,
                texto: 'Emergencia',
                color: ac.red,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'SE PIENSA TRATAR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: ac.textMuted,
          ),
        ),
        const SizedBox(height: 5),
        if (actividades.isEmpty)
          Text(
            // Sin actividades del plan el motivo es lo único que hay; decirlo
            // vacío evita que el hueco se lea como un error de carga.
            motivo.isNotEmpty ? motivo : 'Sin actividades del plan vinculadas.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: motivo.isNotEmpty ? ac.textSecondary : ac.textMuted,
              fontStyle: motivo.isNotEmpty
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          )
        else
          for (final actividad in actividades)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ac.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      actividad,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: ac.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        // El motivo declarado y el plan son cosas distintas: cuando hay
        // actividades, el motivo sigue mostrándose aparte en vez de sustituirse.
        if (actividades.isNotEmpty && motivo.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'MOTIVO DECLARADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            motivo,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: ac.textSecondary,
            ),
          ),
        ],
      ],
    );

    if (!flotante) return contenido;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider),
        boxShadow: [ac.cardShadow],
      ),
      child: contenido,
    );
  }
}

/// Abre el resumen como diálogo. Es la vía táctil y la que se ofrece desde un
/// menú o un botón, donde no hay cursor que posar.
Future<void> mostrarResumenCita(BuildContext context, Cita cita) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialog(
      preferredWidth: 380,
      title: Row(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 18,
            color: dialogContext.appColors.primaryGreen,
          ),
          const SizedBox(width: 8),
          Text(
            'Resumen de la cita',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: dialogContext.appColors.textPrimary,
            ),
          ),
        ],
      ),
      content: TarjetaResumenCita(cita: cita, flotante: false),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

/// Envuelve un bloque de la agenda y le añade el resumen flotante.
///
/// El hover es la vía del ratón; el foco del teclado abre el mismo panel para
/// que tabular por la agenda no deje al usuario sin la información. En táctil no
/// ocurre ninguno de los dos, y por eso quien use este widget debe ofrecer
/// además una acción visible que llame a [mostrarResumenCita] — la anuncia
/// [Semantics] con la etiqueta de la cita.
class ResumenCitaAccesible extends StatefulWidget {
  const ResumenCitaAccesible({
    super.key,
    required this.cita,
    required this.child,
  });

  final Cita cita;
  final Widget child;

  @override
  State<ResumenCitaAccesible> createState() => _ResumenCitaAccesibleState();
}

class _ResumenCitaAccesibleState extends State<ResumenCitaAccesible> {
  final _controlador = OverlayPortalController();
  bool _hover = false;
  bool _foco = false;

  void _actualizar() {
    final visible = _hover || _foco;
    if (visible && !_controlador.isShowing) {
      _controlador.show();
    } else if (!visible && _controlador.isShowing) {
      _controlador.hide();
    }
  }

  Rect? _rectangloObjetivo() {
    final caja = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (caja == null || overlay == null || !caja.hasSize) return null;
    final origen = caja.localToGlobal(Offset.zero, ancestor: overlay);
    return origen & caja.size;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (valor) {
        _hover = valor;
        _actualizar();
      },
      onShowFocusHighlight: (valor) {
        _foco = valor;
        _actualizar();
      },
      child: OverlayPortal(
        controller: _controlador,
        overlayChildBuilder: (overlayContext) {
          final objetivo = _rectangloObjetivo();
          if (objetivo == null) return const SizedBox.shrink();
          return CustomSingleChildLayout(
            delegate: _PosicionResumen(objetivo: objetivo),
            // Un resumen no se opera: dejarlo transparente al puntero evita que
            // aparecer bajo el cursor cuente como salir del bloque y lo haga
            // parpadear.
            child: IgnorePointer(child: TarjetaResumenCita(cita: widget.cita)),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Coloca el panel bajo el bloque, o encima si no cabe, sin salirse de pantalla.
class _PosicionResumen extends SingleChildLayoutDelegate {
  _PosicionResumen({required this.objetivo});

  final Rect objetivo;

  /// Aire respecto al bloque y a los bordes de la pantalla.
  static const margen = 8.0;

  /// Ancho preferido del panel; se recorta si la pantalla no da para tanto.
  static const anchoMaximo = 320.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest).copyWith(
      maxWidth: math.max(
        0,
        math.min(anchoMaximo, constraints.maxWidth - margen * 2),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double y = objetivo.bottom + margen;
    if (y + childSize.height > size.height - margen) {
      final arriba = objetivo.top - margen - childSize.height;
      y = arriba >= margen
          ? arriba
          : math.max(margen, size.height - childSize.height - margen);
    }

    final maximoX = math.max(margen, size.width - childSize.width - margen);
    final x = objetivo.left.clamp(margen, maximoX);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PosicionResumen anterior) =>
      anterior.objetivo != objetivo;
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
