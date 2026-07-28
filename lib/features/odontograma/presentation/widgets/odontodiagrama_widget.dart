import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/leyenda_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

export 'leyenda_odontograma.dart' show leyendaClinicaPredeterminada;

class OdontodiagramaWidget extends StatefulWidget {
  final EvaluacionOdontologica evaluacion;

  final EvaluacionOdontologica historico;

  final bool editable;

  final bool modoImpresion;

  final List<EntradaLeyendaOdontograma>? leyenda;

  final ValueChanged<EvaluacionOdontologica>? onChanged;

  final Map<int, Diente> dientes;

  final Map<int, List<ItemPlanTratamiento>> itemsPlan;
  final HistorialPiezas? historialPiezas;

  final void Function(Diente, String)? onNotasPiezaChanged;

  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool ausente)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)?
  onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  final String Function(String doctorId)? nombreDoctor;

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
    this.historialPiezas,
    this.onNotasPiezaChanged,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTratamientoTerminado,
    this.nombreTratamiento,
    this.nombreDoctor,
  });

  @override
  State<OdontodiagramaWidget> createState() => _OdontodiagramaWidgetState();
}

class _OdontodiagramaWidgetState extends State<OdontodiagramaWidget> {
  static const double _celdaTactil = 44;
  static const double _celdaLectura = 30;

  static const double _anchoMaximoDiagrama = 940;
  static const double _lineaMedia = 1.4;
  static const double _anchoPanel = 360;
  static const double _separacionPanel = 20;
  static const double _paddingPapel = 12;

  static const double _anchoMinimoPapel =
      _celdaTactil * kColumnasPorHemicampo * 2 +
      _lineaMedia +
      _paddingPapel * 2;

  int? _fdiSeleccionado;
  final Map<TejidoBlando, TextEditingController> _tejidoControllers = {};

  List<EntradaLeyendaOdontograma> get _leyenda =>
      widget.leyenda ?? leyendaClinicaPredeterminada;

  bool get _editando =>
      widget.editable && !widget.modoImpresion && widget.dientes.isNotEmpty;
  bool get _tocable =>
      !widget.modoImpresion && (widget.dientes.isNotEmpty || _hayHistorico);

  bool get _anotandoTejidos =>
      widget.editable && !widget.modoImpresion && widget.onChanged != null;

  PaletaOdontodiagrama get _paleta =>
      PaletaOdontodiagrama.de(context, imprimir: widget.modoImpresion);

  bool get _hayHistorico =>
      !widget.historico.estaVacia ||
      widget.dientes.values.any((d) => d.tratamientosHistoricos.isNotEmpty) ||
      !(widget.historialPiezas?.estaVacio ?? true);

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

  void _tocarPieza(int fdi) {
    if (!_tocable) return;
    setState(() => _fdiSeleccionado = _fdiSeleccionado == fdi ? null : fdi);
  }

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
    historial: widget.historialPiezas?[fdi],
    editMode: _editando,
    onClose: () => setState(() => _fdiSeleccionado = null),
    onNotasChanged: widget.onNotasPiezaChanged,
    onAddDiagnosis: widget.onAddDiagnosis,
    onAddTratamiento: widget.onAddTratamiento,
    onToggleAusente: widget.onToggleAusente,
    onQuitarTratamiento: widget.onQuitarTratamiento,
    onToggleTerminado: widget.onToggleTratamientoTerminado,
    nombreTratamiento: widget.nombreTratamiento,
    nombreDoctor: widget.nombreDoctor ?? widget.historialPiezas?.nombreDoctor,
  );

  Widget _panelPapel(double disponible, PaletaOdontodiagrama paleta) {
    const padding = _paddingPapel;
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

class _PiezaDental extends StatefulWidget {
  final GlifoPieza glifo;
  final List<HallazgoDental> hallazgos;
  final Map<TipoSuperficie, MarcaClinicaPieza> superficies;
  final List<HallazgoDental> historicos;
  final double lado;
  final PaletaOdontodiagrama paleta;
  final bool tocable;
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
      if (widget.hallazgos.any((h) => h.esPiezaCompleta))
        _resumen(widget.hallazgos.where((h) => h.esPiezaCompleta)),
      if (widget.historicos.isNotEmpty) 'Antes: ${_resumen(widget.historicos)}',
    ];
    if (partes.isEmpty) return 'Pieza $fdi, sin hallazgos';
    return 'Pieza $fdi: ${partes.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
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
