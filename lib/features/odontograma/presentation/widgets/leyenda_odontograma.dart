import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/trazo_punteado.dart';

/// Las seis claves del papel más el estado abierto que la clínica usa para lo
/// que no está impreso. La lista es un parámetro de la leyenda, así que acordar
/// una clave nueva no obliga a tocar ningún dibujo.
final List<EntradaLeyendaOdontograma> leyendaClinicaPredeterminada =
    List.unmodifiable([
      ...leyendaFormularioFisico,
      EntradaLeyendaOdontograma.delFormulario(
        EstadoClinicoDental.otro,
        etiqueta: 'Otro (anotar)',
      ),
    ]);

/// Qué significan los colores y los trazos del odontograma.
///
/// Es una sola leyenda para las dos vistas y para la hoja impresa. Antes cada
/// vista traía la suya —el formulario listaba las claves del papel y la arcada
/// una escala de severidad— y las dos coloreaban la misma boca con criterios
/// distintos, así que la leyenda no explicaba lo que el doctor tenía delante.
///
/// Lee dos ejes independientes y los presenta como tales:
/// - **Claves**: qué es la marca. Decide el color.
/// - **Procedencia**: de cuándo viene. Decide el trazo.
class LeyendaOdontograma extends StatelessWidget {
  final PaletaOdontodiagrama paleta;

  /// Claves disponibles, en el orden en que se muestran.
  final List<EntradaLeyendaOdontograma>? claves;

  /// Procedencias a explicar. Se limita a las que la vista puede mostrar para
  /// no prometer estados que ahí nunca aparecen.
  final List<ProcedenciaMarca> procedencias;

  /// Nota al pie, para avisos que dependen de la vista (por ejemplo, que el
  /// paciente tiene antecedentes que se leen tocando la pieza).
  final Widget? pie;

  /// Aprieta la separación entre entradas. Lo decide quien dibuja, porque el
  /// diagrama conoce su ancho útil y no siempre coincide con el de la ventana.
  final bool? compacto;

  const LeyendaOdontograma({
    super.key,
    required this.paleta,
    this.claves,
    this.procedencias = ProcedenciaMarca.values,
    this.pie,
    this.compacto,
  });

  List<EntradaLeyendaOdontograma> get _claves =>
      claves ?? leyendaClinicaPredeterminada;

  @override
  Widget build(BuildContext context) {
    final compacto = this.compacto ?? context.appLayout.isCompact;
    final texto = paleta.apoyoSobreTarjeta(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo('CLAVES', paleta: paleta),
        const SizedBox(height: 8),
        Wrap(
          spacing: compacto ? 12 : 18,
          runSpacing: 8,
          children: [
            for (final entrada in _claves)
              Semantics(
                label: '${entrada.label}, clave del odontograma',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarcaClinicaIcono(
                      marca: entrada.marca,
                      estado: entrada.estado,
                      paleta: paleta,
                      lado: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entrada.label,
                      style: TextStyle(color: texto, fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (procedencias.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Titulo('PROCEDENCIA', paleta: paleta),
          const SizedBox(height: 2),
          Text(
            'El color dice qué es; el trazo, de cuándo viene.',
            style: TextStyle(color: texto, fontSize: 10.5, height: 1.3),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: compacto ? 12 : 18,
            runSpacing: 8,
            children: [
              for (final procedencia in procedencias)
                Semantics(
                  label: '${procedencia.etiqueta}: ${procedencia.descripcion}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MuestraProcedencia(
                        procedencia: procedencia,
                        paleta: paleta,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        procedencia.etiqueta,
                        style: TextStyle(color: texto, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (pie != null) ...[const SizedBox(height: 10), pie!],
      ],
    );
  }
}

/// Cuadro de muestra de una procedencia: la misma cara del mapa de superficies,
/// dibujada con el estilo que le corresponde y en tinta neutra, para que lo que
/// se compare sea el trazo y no el color.
class MuestraProcedencia extends StatelessWidget {
  final ProcedenciaMarca procedencia;
  final PaletaOdontodiagrama paleta;
  final double lado;

  const MuestraProcedencia({
    super.key,
    required this.procedencia,
    required this.paleta,
    this.lado = 16,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(lado),
    painter: _MuestraProcedenciaPainter(
      // Tinta neutra a propósito: lo que esta muestra compara es el trazo.
      estilo: paleta.estiloDe(TintaClinica.negra, procedencia),
      papel: paleta.papel,
    ),
  );
}

class _MuestraProcedenciaPainter extends CustomPainter {
  final EstiloMarcaClinica estilo;
  final Color papel;

  const _MuestraProcedenciaPainter({required this.estilo, required this.papel});

  @override
  void paint(Canvas canvas, Size size) {
    final marco = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    canvas.drawRect(marco, Paint()..color = papel);
    if (estilo.alfaRelleno > 0) {
      canvas.drawRect(marco, Paint()..color = estilo.relleno);
    }

    final trazo = Paint()
      ..color = estilo.trazo
      ..style = PaintingStyle.stroke
      ..strokeWidth = estilo.grosorTrazo;

    if (estilo.punteado) {
      dibujarRectanguloPunteado(canvas, marco, trazo);
    } else {
      canvas.drawRect(marco, trazo);
    }
  }

  @override
  bool shouldRepaint(_MuestraProcedenciaPainter old) =>
      old.estilo != estilo || old.papel != papel;
}

class _Titulo extends StatelessWidget {
  final String texto;
  final PaletaOdontodiagrama paleta;

  const _Titulo(this.texto, {required this.paleta});

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texto,
      style: TextStyle(
        color: paleta.tituloSobreTarjeta(context),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    ),
  );
}
