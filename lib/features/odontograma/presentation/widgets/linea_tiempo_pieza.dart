import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/texto_marca_clinica.dart';

/// La historia completa de una pieza, visita por visita.
///
/// El odontograma de una consulta cuenta cómo estaba la boca ese día y la Vista
/// General del expediente se queda con la peor anotación de cada pieza; ninguna
/// de las dos puede decir qué pasó antes. Esta línea de tiempo se arma de los
/// ejes clínicos, que guardan una fila por hecho, así que consolidar la
/// situación actual del paciente nunca borra un evento anterior (SD-144).
///
/// Cada evento dice de qué eje sale —evaluado, planificado o ejecutado—, en qué
/// estado quedó —activo, finalizado o anulado— y, cuando lleva dinero, cuánto.
class LineaTiempoPieza extends StatelessWidget {
  final HistorialPieza historial;

  /// Resuelve el nombre del doctor de cada anotación. Sin él la línea omite la
  /// autoría en lugar de mostrar un identificador que no dice nada.
  final String Function(String doctorId)? nombreDoctor;

  const LineaTiempoPieza({
    super.key,
    required this.historial,
    this.nombreDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    if (historial.estaVacio) {
      return Text(
        'Esta pieza no tiene historial registrado.',
        style: TextStyle(fontSize: 12, color: ac.textDisabled),
      );
    }

    final paleta = PaletaOdontodiagrama.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final visita in historial.visitas)
          _TramoVisita(
            visita: visita,
            paleta: paleta,
            nombreDoctor: nombreDoctor,
            // La última no dibuja la guía hacia abajo: ahí termina la historia.
            esUltima: visita == historial.visitas.last,
          ),
      ],
    );
  }
}

/// Encabezado de una visita más sus eventos, unidos por la guía vertical que
/// convierte la lista en una línea de tiempo.
class _TramoVisita extends StatelessWidget {
  final VisitaPieza visita;
  final PaletaOdontodiagrama paleta;
  final String Function(String doctorId)? nombreDoctor;
  final bool esUltima;

  const _TramoVisita({
    required this.visita,
    required this.paleta,
    required this.esUltima,
    this.nombreDoctor,
  });

  /// «12 Jun 2026 · Evaluación · Dr. Pérez». Se omite lo que no se sabe.
  String get _encabezado {
    final consulta = visita.consulta;
    final doctorId = consulta?.doctorId;
    final nombre = doctorId == null ? null : nombreDoctor?.call(doctorId);
    return [
      fechaLargaDeMarca(visita.fecha),
      if (consulta != null) consulta.tipoAtencion.etiqueta,
      if (nombre != null && nombre.trim().isNotEmpty) nombre,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final motivo = visita.consulta?.motivo?.trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuiaVisita(color: ac.divider, punto: ac.teal, continua: !esUltima),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltima ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      _encabezado,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                  ),
                  if (motivo != null && motivo.isNotEmpty)
                    Text(
                      motivo,
                      style: TextStyle(fontSize: 10.5, color: ac.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (visita.consulta == null)
                    Text(
                      'Sin consulta asociada',
                      style: TextStyle(fontSize: 10.5, color: ac.textDisabled),
                    ),
                  const SizedBox(height: 8),
                  for (final evento in visita.eventos)
                    _EventoPieza(
                      evento: evento,
                      paleta: paleta,
                      nombreDoctor: nombreDoctor,
                      // El doctor de la visita ya está en el encabezado: solo se
                      // repite en el evento cuando lo anotó otra persona.
                      doctorDeLaVisita: visita.consulta?.doctorId,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El punto de la visita y la línea que baja hacia la siguiente.
class _GuiaVisita extends StatelessWidget {
  final Color color;
  final Color punto;
  final bool continua;

  const _GuiaVisita({
    required this.color,
    required this.punto,
    required this.continua,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 10,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
          ),
        ),
        if (continua)
          Expanded(
            child: Container(
              width: 1.5,
              margin: const EdgeInsets.only(top: 3),
              color: color,
            ),
          ),
      ],
    ),
  );
}

/// Un hecho sobre la pieza: qué fue, sobre qué cara, en qué estado quedó y
/// cuánto costó si llevó dinero.
class _EventoPieza extends StatelessWidget {
  final MarcaClinicaPieza evento;
  final PaletaOdontodiagrama paleta;
  final String Function(String doctorId)? nombreDoctor;
  final String? doctorDeLaVisita;

  const _EventoPieza({
    required this.evento,
    required this.paleta,
    this.nombreDoctor,
    this.doctorDeLaVisita,
  });

  /// El nombre del doctor solo cuando aporta algo: si es el mismo que atendió
  /// la visita, ya se leyó en el encabezado.
  String? get _autor {
    final doctorId = evento.doctorId;
    if (doctorId == null || doctorId == doctorDeLaVisita) return null;
    final nombre = nombreDoctor?.call(doctorId);
    return (nombre != null && nombre.trim().isNotEmpty) ? nombre : null;
  }

  /// Lo que se cobró, o lo que se estimó si aún es un plan. Rotular el estimado
  /// es obligatorio: el plan no factura y confundirlo con un cargo descuadra la
  /// lectura económica del expediente.
  String? get _precio {
    final precio = evento.precio;
    if (precio == null) return null;
    return evento.procedencia == ProcedenciaMarca.planificado
        ? 'Est. ${formatMoneda(precio)}'
        : formatMoneda(precio);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final tinta = paleta.tintaClinica(evento.tintaClinica);
    final atenuado = !evento.vigente;
    final precio = _precio;
    final autor = _autor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: descripcionAccesible(evento, nombreDoctor: nombreDoctor),
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _MuestraEje(procedencia: evento.procedencia, tinta: tinta),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conSuperficie(evento.titulo, evento.superficie),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: atenuado ? ac.textMuted : ac.textSecondary,
                      // Lo anulado se tacha: sigue en el expediente, pero ya no
                      // cuenta como lo que le pasa a la pieza.
                      decoration: evento.anulada
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: ac.textMuted,
                    ),
                  ),
                  Text(
                    [evento.procedencia.etiqueta, ?autor].join(' · '),
                    style: TextStyle(fontSize: 10, color: ac.textDisabled),
                  ),
                  if (evento.notas case final notas?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        notas,
                        style: TextStyle(
                          fontSize: 11,
                          color: ac.textMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ChipEstadoEvento(
                  texto: evento.estado,
                  color: evento.anulada ? ac.red : tinta,
                ),
                if (precio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      precio,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: atenuado ? ac.textDisabled : ac.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El eje del que sale el evento, dicho con la misma forma que la leyenda del
/// odontograma: relleno para lo ejecutado, punteado para lo planificado.
class _MuestraEje extends StatelessWidget {
  final ProcedenciaMarca procedencia;
  final Color tinta;

  const _MuestraEje({required this.procedencia, required this.tinta});

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: procedencia == ProcedenciaMarca.planificado
          ? Colors.transparent
          : tinta,
      border: Border.all(color: tinta, width: 1.4),
      shape: BoxShape.circle,
    ),
  );
}

class _ChipEstadoEvento extends StatelessWidget {
  final String texto;
  final Color color;

  const _ChipEstadoEvento({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
