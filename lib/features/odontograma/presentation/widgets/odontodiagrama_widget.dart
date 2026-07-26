import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/leyenda_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

// La leyenda es la misma para las dos vistas y para la hoja impresa; se
// reexporta para no obligar a cambiar los imports que ya la usaban desde aquí.
export 'leyenda_odontograma.dart' show leyendaClinicaPredeterminada;

/// Reproducción del ODONTODIAGRAMA del formulario en papel de la clínica.
///
/// Dibuja las dos denticiones a la vez —permanente por fuera, temporal hacia la
/// línea media— con los cuatro cuadrantes rotulados, la tabla de tejidos
/// blandos y las claves. Solo recibe [EvaluacionOdontologica] y emite la
/// evaluación resultante: no conoce cubits, repositorios ni Supabase, de modo
/// que la misma vista sirve para evaluar, consultar el expediente e imprimir.
class OdontodiagramaWidget extends StatefulWidget {
  final EvaluacionOdontologica evaluacion;

  /// Lo anotado en consultas anteriores, dibujado en tinta tenue debajo de
  /// [evaluacion]. Es la misma capa histórica del odontograma de tratamientos:
  /// el doctor ve de un vistazo qué traía el paciente y qué añade hoy.
  final EvaluacionOdontologica historico;

  /// Permite anotar. Requiere [onChanged].
  final bool editable;

  /// Suprime los controles y fija la tinta sobre papel para captura o PDF.
  final bool modoImpresion;

  /// Claves disponibles, en el orden en que se muestran.
  final List<EntradaLeyendaOdontograma>? leyenda;

  final ValueChanged<EvaluacionOdontologica>? onChanged;

  /// Las piezas normalizadas de la consulta, indexadas por su código FDI.
  ///
  /// El dibujo se sigue proyectando desde [evaluacion]; esto es lo que el
  /// panel de detalle necesita para listar diagnósticos y tratamientos reales,
  /// con sus precios e identificadores. Sin ellas el diagrama funciona igual y
  /// no abre panel: es lo que hacen la impresión y el expediente.
  final Map<int, Diente> dientes;

  /// Actividades del plan de tratamiento que caen sobre cada pieza. Es lo que
  /// permite que la ficha distinga lo planificado de lo ya ejecutado.
  final Map<int, List<ItemPlanTratamiento>> itemsPlan;

  /// Anota una observación clínica sobre la pieza. `null` deja el campo en solo
  /// lectura, que es como lo ve el expediente.
  final void Function(Diente, String)? onNotasPiezaChanged;

  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool ausente)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)?
  onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const OdontodiagramaWidget({
    super.key,
    required this.evaluacion,
    this.historico = EvaluacionOdontologica.vacia,
    this.editable = false,
    this.modoImpresion = false,
    this.leyenda,
    this.onChanged,
    this.dientes = const {},
    this.itemsPlan = const {},
    this.onNotasPiezaChanged,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTratamientoTerminado,
    this.nombreTratamiento,
  });

  @override
  State<OdontodiagramaWidget> createState() => _OdontodiagramaWidgetState();
}

class _OdontodiagramaWidgetState extends State<OdontodiagramaWidget> {
  /// Lado mínimo de una pieza cuando se puede tocar. Por debajo de 44 px el
  /// dedo no acierta la cara del diente, y esta pantalla se usa en tablet.
  static const double _celdaTactil = 44;

  /// En solo lectura la pieza no es un objetivo, así que puede apretarse para
  /// que el diagrama entero quepa sin desplazamiento.
  static const double _celdaLectura = 30;

  static const double _anchoMaximoDiagrama = 940;
  static const double _lineaMedia = 1.4;

  /// Ancho del panel de detalle y su separación del papel, iguales a los de la
  /// arcada para que el mismo panel se lea igual en las dos vistas.
  static const double _anchoPanel = 360;
  static const double _separacionPanel = 20;
  static const double _paddingPapel = 12;

  /// Ancho por debajo del cual el papel dejaría de ser tocable con el dedo.
  static const double _anchoMinimoPapel =
      _celdaTactil * kColumnasPorHemicampo * 2 +
      _lineaMedia +
      _paddingPapel * 2;

  /// Pieza cuyo panel de detalle está abierto, si hay alguno.
  int? _fdiSeleccionado;
  final Map<TejidoBlando, TextEditingController> _tejidoControllers = {};

  List<EntradaLeyendaOdontograma> get _leyenda =>
      widget.leyenda ?? leyendaClinicaPredeterminada;

  /// El diagrama responde al toque: cada pieza abre su panel de detalle.
  ///
  /// Depende de [OdontodiagramaWidget.dientes] y no de `onChanged` porque lo
  /// que se anota hoy son diagnósticos y tratamientos sobre piezas reales; el
  /// JSON de la evaluación ya solo guarda tejidos blandos.
  bool get _editando =>
      widget.editable && !widget.modoImpresion && widget.dientes.isNotEmpty;

  /// Tocar una pieza abre su ficha también en solo lectura: ahí es donde ahora
  /// viven los antecedentes, así que el expediente tiene que poder abrirla. Sin
  /// piezas ni historial no hay ficha que abrir, y la hoja de impresión nunca
  /// responde al toque.
  bool get _tocable =>
      !widget.modoImpresion && (widget.dientes.isNotEmpty || _hayHistorico);

  /// Los tejidos blandos siguen siendo texto libre sobre la evaluación.
  bool get _anotandoTejidos =>
      widget.editable && !widget.modoImpresion && widget.onChanged != null;

  PaletaOdontodiagrama get _paleta =>
      PaletaOdontodiagrama.de(context, imprimir: widget.modoImpresion);

  bool get _hayHistorico =>
      !widget.historico.estaVacia ||
      widget.dientes.values.any((d) => d.tratamientosHistoricos.isNotEmpty);

  @override
  void initState() {
    super.initState();
    for (final tejido in TejidoBlando.values) {
      _tejidoControllers[tejido] = TextEditingController(
        text: widget.evaluacion.tejidosBlandos[tejido] ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(covariant OdontodiagramaWidget old) {
    super.didUpdateWidget(old);
    // El texto entrante solo pisa al controlador cuando cambió fuera del campo;
    // así el cursor no salta mientras el doctor escribe.
    for (final tejido in TejidoBlando.values) {
      final entrante = widget.evaluacion.tejidosBlandos[tejido] ?? '';
      final controller = _tejidoControllers[tejido]!;
      if (controller.text != entrante) controller.text = entrante;
    }
  }

  @override
  void dispose() {
    for (final controller in _tejidoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emitir(EvaluacionOdontologica evaluacion) =>
      widget.onChanged?.call(evaluacion);

  /// Tocar una pieza abre su panel, nunca escribe sola.
  ///
  /// Antes el toque estampaba la clave activa sobre la cara pulsada. Elegir
  /// una cara de 44 px con el dedo y sin ver lo que la pieza ya tiene era la
  /// parte incómoda; ahora la cara se elige en el mapa grande del panel, que
  /// es el mismo que usa la arcada.
  void _tocarPieza(int fdi) {
    if (!_tocable) return;
    setState(() => _fdiSeleccionado = _fdiSeleccionado == fdi ? null : fdi);
  }

  /// Lo que tiñe cada cara de la pieza [fdi] en el papel.
  ///
  /// Solo entra lo de esta consulta, que es lo que la hoja representa y lo que
  /// promete su leyenda: los antecedentes se leen en la ficha —dejaron de
  /// estamparse en tinta tenue porque llenaban de marcas una boca muy tratada—
  /// y lo planificado todavía no está en la boca.
  Map<TipoSuperficie, MarcaClinicaPieza> _superficiesDe(int fdi) {
    final diente = widget.dientes[fdi];
    if (diente == null) return const {};

    final deHoy = [
      for (final marca in marcasDePieza(fdi: fdi, diente: diente))
        if (marca.procedencia == ProcedenciaMarca.evaluado ||
            marca.procedencia == ProcedenciaMarca.ejecutado)
          marca,
    ];
    if (deHoy.isEmpty) return const {};

    final porCara = <TipoSuperficie, MarcaClinicaPieza>{};
    for (final cara in TipoSuperficie.values) {
      final marca = marcaDeSuperficie(deHoy, cara);
      if (marca != null) porCara[cara] = marca;
    }
    return porCara;
  }

  /// Solo se muestra en la capa tenue lo que no está ya anotado en firme, para
  /// que una clave repetida no se dibuje dos veces sobre la misma pieza. La
  /// resta es por superficie: lo que el histórico anota en otra cara sigue
  /// viéndose.
  List<HallazgoDental> _historicoDe(int fdi) {
    if (!_hayHistorico) return const [];
    return hallazgosRestantes(
      widget.historico.de(fdi),
      widget.evaluacion.de(fdi),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final disponible = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _anchoMaximoDiagrama;
        final compacto = AppLayoutResolution.ofWidth(disponible).isCompact;
        final paleta = _paleta;

        final fdi = _fdiSeleccionado;
        // El panel se pone al lado solo si al papel le queda su ancho táctil
        // íntegro; si no, cae debajo antes que estrujar el diagrama.
        final alLado =
            fdi != null &&
            disponible >= _anchoMinimoPapel + _anchoPanel + _separacionPanel;
        final papel = _panelPapel(
          alLado ? disponible - _anchoPanel - _separacionPanel : disponible,
          paleta,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(context, paleta),
            const SizedBox(height: 12),
            if (alLado)
              _papelConPanelAlLado(fdi, papel)
            else ...[
              papel,
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: fdi == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _panelPieza(fdi),
                      ),
              ),
            ],
            const SizedBox(height: 14),
            _claves(context, compacto, paleta),
            const SizedBox(height: 18),
            _tejidosBlandos(context, compacto, paleta),
          ],
        );
      },
    );
  }

  Widget _encabezado(BuildContext context, PaletaOdontodiagrama paleta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ODONTODIAGRAMA',
          style: TextStyle(
            color: paleta.tituloSobreTarjeta(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _editando
              ? 'Toca un diente para abrir su ficha: ahí eliges la cara y le '
                    'asignas diagnósticos o tratamientos.'
              : _tocable
              ? 'Toca un diente para ver su ficha y sus antecedentes.'
              : 'Nomenclatura FDI · dentición permanente y temporal',
          style: TextStyle(
            color: paleta.apoyoSobreTarjeta(context),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// El papel y el panel de la pieza tocada, uno al lado del otro.
  ///
  /// El panel se coloca del lado de su propia pieza —como en la arcada— para
  /// que el doctor no cruce la vista de un extremo al otro del diagrama.
  Widget _papelConPanelAlLado(int fdi, Widget papel) {
    final panel = SizedBox(width: _anchoPanel, child: _panelPieza(fdi));
    const separacion = SizedBox(width: _separacionPanel);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: piezaEnMitadIzquierda(fdi)
          ? [panel, separacion, Expanded(child: papel)]
          : [Expanded(child: papel), separacion, panel],
    );
  }

  Widget _panelPieza(int fdi) => PanelDetallePieza(
    key: ValueKey('panel_pieza_$fdi'),
    fdi: fdi,
    diente: widget.dientes[fdi],
    hallazgosHistoricos: _historicoDe(fdi),
    itemsPlan: widget.itemsPlan[fdi] ?? const [],
    editMode: _editando,
    onClose: () => setState(() => _fdiSeleccionado = null),
    onNotasChanged: widget.onNotasPiezaChanged,
    onAddDiagnosis: widget.onAddDiagnosis,
    onAddTratamiento: widget.onAddTratamiento,
    onToggleAusente: widget.onToggleAusente,
    onQuitarTratamiento: widget.onQuitarTratamiento,
    onToggleTerminado: widget.onToggleTratamientoTerminado,
    nombreTratamiento: widget.nombreTratamiento,
  );

  Widget _panelPapel(double disponible, PaletaOdontodiagrama paleta) {
    const padding = _paddingPapel;
    // El diagrama nunca se comprime por debajo del objetivo táctil: si no cabe,
    // se desplaza en horizontal, como haría una hoja más ancha que el escritorio.
    final minimo =
        (_editando ? _celdaTactil : _celdaLectura) * kColumnasPorHemicampo * 2 +
        _lineaMedia;
    final util = disponible - padding * 2;
    final ancho = util.isFinite
        ? math.max(minimo, math.min(util, _anchoMaximoDiagrama))
        : math.max(minimo, _anchoMaximoDiagrama);

    return Container(
      decoration: BoxDecoration(
        color: paleta.papel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: paleta.regla),
      ),
      padding: const EdgeInsets.all(padding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: ancho, child: _diagrama(ancho, paleta)),
      ),
    );
  }

  Widget _diagrama(double ancho, PaletaOdontodiagrama paleta) {
    final celda = (ancho - _lineaMedia) / (kColumnasPorHemicampo * 2);
    final filas = kFilasOdontodiagrama;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rotulos(filas[0], paleta),
        const SizedBox(height: 4),
        _filaDoble(filas[0], celda, paleta),
        _filaDoble(filas[1], celda, paleta),
        Container(height: _lineaMedia, color: paleta.trazo),
        _filaDoble(filas[2], celda, paleta),
        _filaDoble(filas[3], celda, paleta),
        const SizedBox(height: 4),
        _rotulos(filas[3], paleta),
      ],
    );
  }

  Widget _rotulos(List<FilaOdontodiagrama> par, PaletaOdontodiagrama paleta) {
    Widget lado(FilaOdontodiagrama fila) => Expanded(
      child: Text(
        fila.rotulo ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: paleta.trazo,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
    return Row(
      children: [
        lado(par[0]),
        const SizedBox(width: _lineaMedia),
        lado(par[1]),
      ],
    );
  }

  Widget _filaDoble(
    List<FilaOdontodiagrama> par,
    double celda,
    PaletaOdontodiagrama paleta,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hemifila(par[0], celda, paleta),
          Container(width: _lineaMedia, color: paleta.trazo),
          _hemifila(par[1], celda, paleta),
        ],
      ),
    );
  }

  Widget _hemifila(
    FilaOdontodiagrama fila,
    double celda,
    PaletaOdontodiagrama paleta,
  ) {
    final huecos = kColumnasPorHemicampo - fila.piezas.length;
    final relleno = List.generate(
      huecos,
      (_) => SizedBox(width: celda),
      growable: false,
    );
    final piezas = [
      for (final fdi in fila.piezas) _celda(fdi, fila, celda, paleta),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: fila.hemicampoIzquierdo
          ? [...relleno, ...piezas]
          : [...piezas, ...relleno],
    );
  }

  Widget _celda(
    int fdi,
    FilaOdontodiagrama fila,
    double celda,
    PaletaOdontodiagrama paleta,
  ) {
    final lado = math.max(16.0, celda - 4);
    final numero = Text(
      '$fdi',
      style: TextStyle(
        color: paleta.trazo,
        fontSize: math.min(11, math.max(7, celda * 0.24)),
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
    final pieza = _PiezaDental(
      key: ValueKey('pieza_$fdi'),
      glifo: GlifoPieza(
        fdi: fdi,
        temporal: fila.temporal,
        superior: fila.superior,
        mesialALaDerecha: fila.hemicampoIzquierdo,
      ),
      hallazgos: widget.evaluacion.de(fdi),
      superficies: _superficiesDe(fdi),
      historicos: _historicoDe(fdi),
      lado: lado,
      paleta: paleta,
      tocable: _tocable,
      seleccionada: _fdiSeleccionado == fdi,
      onTap: () => _tocarPieza(fdi),
    );

    return SizedBox(
      width: celda,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fila.superior
              ? [numero, const SizedBox(height: 2), pieza]
              : [pieza, const SizedBox(height: 2), numero],
        ),
      ),
    );
  }

  Widget _claves(
    BuildContext context,
    bool compacto,
    PaletaOdontodiagrama paleta,
  ) => LeyendaOdontograma(
    paleta: paleta,
    claves: _leyenda,
    compacto: compacto,
    // El papel solo lleva la tinta de hoy; lo anterior y lo planificado se leen
    // en la ficha de la pieza, así que la leyenda no promete lo que no dibuja.
    procedencias: const [ProcedenciaMarca.evaluado, ProcedenciaMarca.ejecutado],
    pie: _hayHistorico
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 13, color: paleta.textoVacio),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Este paciente tiene antecedentes: toca una pieza para verlos.',
                  style: TextStyle(
                    color: paleta.textoVacio,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          )
        : null,
  );

  Widget _tejidosBlandos(
    BuildContext context,
    bool compacto,
    PaletaOdontodiagrama paleta,
  ) {
    final anchoEtiqueta = compacto ? 104.0 : 128.0;

    return Container(
      decoration: BoxDecoration(
        color: paleta.papel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: paleta.regla),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: paleta.regla)),
            ),
            child: Text(
              'Tejidos Blandos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: paleta.textoFuerte,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (var i = 0; i < TejidoBlando.values.length; i++)
            _filaTejido(
              TejidoBlando.values[i],
              anchoEtiqueta,
              ultima: i == TejidoBlando.values.length - 1,
              paleta: paleta,
            ),
        ],
      ),
    );
  }

  Widget _filaTejido(
    TejidoBlando tejido,
    double anchoEtiqueta, {
    required bool ultima,
    required PaletaOdontodiagrama paleta,
  }) {
    final anotacion = widget.evaluacion.tejidosBlandos[tejido] ?? '';
    final previo = widget.historico.tejidosBlandos[tejido];

    final valor = _anotandoTejidos
        ? TextField(
            key: ValueKey('tejido_${tejido.dbValue}'),
            controller: _tejidoControllers[tejido],
            onChanged: (texto) =>
                _emitir(widget.evaluacion.conTejido(tejido, texto)),
            style: TextStyle(color: paleta.textoFuerte, fontSize: 13),
            cursorColor: paleta.trazo,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: previo ?? 'Sin alteración',
              hintStyle: TextStyle(
                color: paleta.textoVacio,
                fontSize: 13,
                fontStyle: previo == null ? FontStyle.normal : FontStyle.italic,
              ),
              // 12 px arriba y abajo dejan la fila en el objetivo táctil de
              // 44 px sin que la tabla parezca un formulario suelto.
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              anotacion.isNotEmpty ? anotacion : (previo ?? '—'),
              key: ValueKey('tejido_valor_${tejido.dbValue}'),
              style: TextStyle(
                color: anotacion.isEmpty
                    ? paleta.textoVacio
                    : paleta.textoFuerte,
                fontSize: 13,
                fontStyle: anotacion.isEmpty && previo != null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        border: ultima ? null : Border(bottom: BorderSide(color: paleta.regla)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: anchoEtiqueta,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                tejido.label,
                style: TextStyle(
                  color: paleta.textoFuerte,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 30, color: paleta.regla),
          const SizedBox(width: 10),
          Expanded(child: valor),
        ],
      ),
    );
  }
}

/// El odontodiagrama sobre papel y sin controles, para el expediente, el
/// histórico y la captura a PDF. Fija el papel blanco y las tintas impresas
/// para que la hoja capturada salga igual por la impresora, sin importar el
/// tema con el que se estuviera viendo la aplicación.
class OdontodiagramaPapel extends StatelessWidget {
  final EvaluacionOdontologica evaluacion;
  final EvaluacionOdontologica historico;
  final EdgeInsetsGeometry padding;

  const OdontodiagramaPapel({
    super.key,
    required this.evaluacion,
    this.historico = EvaluacionOdontologica.vacia,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
    color: PaletaOdontodiagrama.impresion.papel,
    padding: padding,
    child: OdontodiagramaWidget(
      evaluacion: evaluacion,
      historico: historico,
      modoImpresion: true,
    ),
  );
}

/// Una pieza del diagrama: dibuja el glifo y abre su panel al tocarla.
class _PiezaDental extends StatefulWidget {
  final GlifoPieza glifo;
  final List<HallazgoDental> hallazgos;

  /// Lo que tiñe cada cara. Alimenta el dibujo y la descripción accesible: un
  /// tratamiento por cara se ve en el papel y se dice en voz alta.
  final Map<TipoSuperficie, MarcaClinicaPieza> superficies;

  /// Antecedentes de la pieza. No se dibujan —el papel solo lleva la tinta de
  /// hoy—; alimentan la descripción accesible y el tooltip, y el detalle
  /// completo vive en la ficha que abre el toque.
  final List<HallazgoDental> historicos;
  final double lado;
  final PaletaOdontodiagrama paleta;

  /// Si el toque abre la ficha de la pieza. Falso solo en la hoja de impresión.
  final bool tocable;

  /// La pieza cuyo panel está abierto se mantiene resaltada, para no perderla
  /// de vista mientras se trabaja en el panel.
  final bool seleccionada;
  final VoidCallback onTap;

  const _PiezaDental({
    super.key,
    required this.glifo,
    required this.hallazgos,
    required this.superficies,
    required this.historicos,
    required this.lado,
    required this.paleta,
    required this.tocable,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  State<_PiezaDental> createState() => _PiezaDentalState();
}

class _PiezaDentalState extends State<_PiezaDental> {
  bool _hover = false;

  String _resumen(Iterable<HallazgoDental> lista) => lista
      .map((h) {
        final caras = h.superficies.isEmpty
            ? 'pieza completa'
            : h.superficies.map((s) => s.name.toLowerCase()).join(', ');
        return '${h.estado.label} ($caras)';
      })
      .join('; ');

  /// Lo anotado por cara, en el orden fijo del enum para que la lectura no
  /// cambie de una pieza a otra.
  String get _resumenSuperficies => [
    for (final cara in TipoSuperficie.values)
      if (widget.superficies[cara] case final marca?)
        '${marca.titulo} (${cara.name.toLowerCase()})',
  ].join('; ');

  String get _descripcion {
    final fdi = widget.glifo.fdi;
    final porCara = _resumenSuperficies;
    final partes = [
      if (porCara.isNotEmpty) porCara,
      // Las claves de pieza completa no salen del mapa de caras: se dicen
      // aparte para no perderlas de la descripción.
      if (widget.hallazgos.any((h) => h.esPiezaCompleta))
        _resumen(widget.hallazgos.where((h) => h.esPiezaCompleta)),
      if (widget.historicos.isNotEmpty) 'Antes: ${_resumen(widget.historicos)}',
    ];
    if (partes.isEmpty) return 'Pieza $fdi, sin hallazgos';
    return 'Pieza $fdi: ${partes.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    // Cada pieza es su propia capa de dibujo.
    //
    // El diagrama tiene entre 32 y 52 piezas y todas comparten padre. Sin esta
    // frontera, pasar el ratón por un molar invalida la capa entera y obliga a
    // repintar la boca completa —52 `CustomPaint` con sus contornos, tinciones
    // y símbolos— para cambiar el resalte de un solo diente. Con la frontera,
    // el repintado se queda en la pieza que cambió.
    Widget pieza = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.lado),
        painter: GlifoPiezaPainter(
          glifo: widget.glifo,
          hallazgos: widget.hallazgos,
          superficies: widget.superficies,
          paleta: widget.paleta,
          resalte: _hover || widget.seleccionada ? widget.paleta.resalte : null,
        ),
      ),
    );

    if (widget.tocable) {
      pieza = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: pieza,
        ),
      );
    }

    return Semantics(
      button: widget.tocable,
      label: _descripcion,
      child: Tooltip(
        message: _descripcion,
        waitDuration: const Duration(milliseconds: 600),
        child: pieza,
      ),
    );
  }
}
