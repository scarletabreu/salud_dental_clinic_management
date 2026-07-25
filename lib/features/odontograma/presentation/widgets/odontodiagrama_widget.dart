import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Las seis claves del papel más el estado abierto que la clínica usa para lo
/// que no está impreso. La lista es un parámetro del widget, así que acordar
/// una clave nueva no obliga a tocar el dibujo.
final List<EntradaLeyendaOdontograma> leyendaClinicaPredeterminada =
    List.unmodifiable([
      ...leyendaFormularioFisico,
      EntradaLeyendaOdontograma.delFormulario(
        EstadoClinicoDental.otro,
        etiqueta: 'Otro (anotar)',
      ),
    ]);

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

  const OdontodiagramaWidget({
    super.key,
    required this.evaluacion,
    this.historico = EvaluacionOdontologica.vacia,
    this.editable = false,
    this.modoImpresion = false,
    this.leyenda,
    this.onChanged,
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

  /// Ficha en vez de clave: el toque abre la pieza en lugar de anotarla. En
  /// escritorio basta la pulsación larga, pero en tablet hace falta un modo
  /// visible.
  bool _modoFicha = false;
  late EstadoClinicoDental _claveActiva;
  final Map<TejidoBlando, TextEditingController> _tejidoControllers = {};

  List<EntradaLeyendaOdontograma> get _leyenda =>
      widget.leyenda ?? leyendaClinicaPredeterminada;

  bool get _editando =>
      widget.editable && !widget.modoImpresion && widget.onChanged != null;

  PaletaOdontodiagrama get _paleta =>
      PaletaOdontodiagrama.de(context, imprimir: widget.modoImpresion);

  bool get _hayHistorico => !widget.historico.estaVacia;

  @override
  void initState() {
    super.initState();
    _claveActiva = _leyenda.isEmpty
        ? EstadoClinicoDental.cariada
        : _leyenda.first.estado;
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

  void _tocarPieza(int fdi, FilaOdontodiagrama fila, TipoSuperficie? superficie) {
    if (!_editando) return;
    if (_modoFicha) {
      _abrirDetallePieza(fdi, fila);
      return;
    }
    _emitir(
      widget.evaluacion.alternar(fdi, _claveActiva, superficie: superficie),
    );
  }

  /// Solo se muestra en la capa tenue lo que no está ya anotado en firme, para
  /// que una clave repetida no se dibuje dos veces sobre la misma pieza.
  List<HallazgoDental> _historicoDe(int fdi) {
    if (!_hayHistorico) return const [];
    final vigentes = widget.evaluacion.de(fdi);
    return widget.historico
        .de(fdi)
        .where((h) => !vigentes.any((v) => v.estado == h.estado))
        .toList(growable: false);
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(context, paleta),
            if (_editando) ...[
              const SizedBox(height: 12),
              _paletaClaves(context, paleta),
            ],
            const SizedBox(height: 12),
            _panelPapel(disponible, paleta),
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
              ? 'Elige una clave y toca la cara del diente que quieras anotar. '
                    'Con «Ficha de pieza» el toque abre sus hallazgos.'
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

  Widget _paletaClaves(BuildContext context, PaletaOdontodiagrama paleta) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entrada in _leyenda)
          ChoiceChip(
            key: ValueKey('clave_${entrada.estado.dbValue}'),
            selected: !_modoFicha && _claveActiva == entrada.estado,
            onSelected: (_) => setState(() {
              _claveActiva = entrada.estado;
              _modoFicha = false;
            }),
            avatar: MarcaClinicaIcono(
              marca: entrada.marca,
              estado: entrada.estado,
              paleta: paleta,
              lado: 18,
            ),
            label: Text(entrada.label),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            // Sin densidad compacta: el chip conserva el objetivo táctil de
            // 48 px que Material da por defecto.
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ChoiceChip(
          key: const ValueKey('clave_ficha'),
          selected: _modoFicha,
          onSelected: (_) => setState(() => _modoFicha = !_modoFicha),
          avatar: Icon(
            Icons.assignment_outlined,
            size: 18,
            color: context.appColors.textSecondary,
          ),
          label: const Text('Ficha de pieza'),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ],
    );
  }

  Widget _panelPapel(double disponible, PaletaOdontodiagrama paleta) {
    const padding = 12.0;
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
      historicos: _historicoDe(fdi),
      lado: lado,
      paleta: paleta,
      editable: _editando,
      onTap: (superficie) => _tocarPieza(fdi, fila, superficie),
      onDetalle: () => _abrirDetallePieza(fdi, fila),
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
  ) {
    final texto = paleta.apoyoSobreTarjeta(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLAVES',
          style: TextStyle(
            color: paleta.tituloSobreTarjeta(context),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: compacto ? 12 : 18,
          runSpacing: 8,
          children: [
            for (final entrada in _leyenda)
              Row(
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
          ],
        ),
        if (_hayHistorico) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 13, color: paleta.textoVacio),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'El trazo tenue viene de consultas anteriores.',
                  style: TextStyle(
                    color: paleta.textoVacio,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

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

    final valor = _editando
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
                color: anotacion.isEmpty ? paleta.textoVacio : paleta.textoFuerte,
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

  Future<void> _abrirDetallePieza(int fdi, FilaOdontodiagrama fila) async {
    if (!_editando) return;
    final resultado = await showDialog<List<HallazgoDental>>(
      context: context,
      builder: (_) => _DetallePiezaDialog(
        fdi: fdi,
        fila: fila,
        hallazgos: widget.evaluacion.de(fdi),
        historicos: widget.historico.de(fdi),
        leyenda: _leyenda,
        paleta: _paleta,
      ),
    );
    if (resultado == null || !mounted) return;
    _emitir(widget.evaluacion.conHallazgos(fdi, resultado));
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

/// Una pieza del diagrama: dibuja el glifo y traduce el punto tocado a la cara
/// dental correspondiente.
class _PiezaDental extends StatefulWidget {
  final GlifoPieza glifo;
  final List<HallazgoDental> hallazgos;
  final List<HallazgoDental> historicos;
  final double lado;
  final PaletaOdontodiagrama paleta;
  final bool editable;
  final ValueChanged<TipoSuperficie?> onTap;
  final VoidCallback onDetalle;

  const _PiezaDental({
    super.key,
    required this.glifo,
    required this.hallazgos,
    required this.historicos,
    required this.lado,
    required this.paleta,
    required this.editable,
    required this.onTap,
    required this.onDetalle,
  });

  @override
  State<_PiezaDental> createState() => _PiezaDentalState();
}

class _PiezaDentalState extends State<_PiezaDental> {
  bool _hover = false;

  String _resumen(List<HallazgoDental> lista) => lista
      .map((h) {
        final caras = h.superficies.isEmpty
            ? 'pieza completa'
            : h.superficies.map((s) => s.name.toLowerCase()).join(', ');
        return '${h.estado.label} ($caras)';
      })
      .join('; ');

  String get _descripcion {
    final fdi = widget.glifo.fdi;
    final partes = [
      if (widget.hallazgos.isNotEmpty) _resumen(widget.hallazgos),
      if (widget.historicos.isNotEmpty)
        'Antes: ${_resumen(widget.historicos)}',
    ];
    if (partes.isEmpty) return 'Pieza $fdi, sin hallazgos';
    return 'Pieza $fdi: ${partes.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget pieza = CustomPaint(
      size: Size.square(widget.lado),
      painter: GlifoPiezaPainter(
        glifo: widget.glifo,
        hallazgos: widget.hallazgos,
        historicos: widget.historicos,
        paleta: widget.paleta,
        resalte: _hover ? widget.paleta.resalte : null,
      ),
    );

    if (widget.editable) {
      pieza = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (detalles) => widget.onTap(
            widget.glifo.superficieEn(detalles.localPosition, widget.lado),
          ),
          onLongPress: widget.onDetalle,
          onSecondaryTap: widget.onDetalle,
          child: pieza,
        ),
      );
    }

    return Semantics(
      button: widget.editable,
      label: _descripcion,
      child: Tooltip(
        message: _descripcion,
        waitDuration: const Duration(milliseconds: 600),
        child: pieza,
      ),
    );
  }
}

/// Ficha de una pieza: lista sus hallazgos, permite quitarlos y añadir uno
/// eligiendo caras concretas y una anotación libre. Los hallazgos de consultas
/// anteriores se listan aparte y no se pueden editar desde aquí.
class _DetallePiezaDialog extends StatefulWidget {
  final int fdi;
  final FilaOdontodiagrama fila;
  final List<HallazgoDental> hallazgos;
  final List<HallazgoDental> historicos;
  final List<EntradaLeyendaOdontograma> leyenda;
  final PaletaOdontodiagrama paleta;

  const _DetallePiezaDialog({
    required this.fdi,
    required this.fila,
    required this.hallazgos,
    required this.historicos,
    required this.leyenda,
    required this.paleta,
  });

  @override
  State<_DetallePiezaDialog> createState() => _DetallePiezaDialogState();
}

class _DetallePiezaDialogState extends State<_DetallePiezaDialog> {
  late List<HallazgoDental> _hallazgos;
  late EstadoClinicoDental _estado;
  final Set<TipoSuperficie> _superficies = {};
  final _detalleCtrl = TextEditingController();

  late final GlifoPieza _glifo = GlifoPieza(
    fdi: widget.fdi,
    temporal: widget.fila.temporal,
    superior: widget.fila.superior,
    mesialALaDerecha: widget.fila.hemicampoIzquierdo,
  );

  @override
  void initState() {
    super.initState();
    _hallazgos = [...widget.hallazgos];
    _estado = widget.leyenda.isEmpty
        ? EstadoClinicoDental.cariada
        : widget.leyenda.first.estado;
  }

  @override
  void dispose() {
    _detalleCtrl.dispose();
    super.dispose();
  }

  void _agregar() {
    final detalle = _detalleCtrl.text.trim();
    setState(() {
      _hallazgos = [
        ..._hallazgos.where((h) => h.estado != _estado),
        HallazgoDental(
          estado: _estado,
          superficies: _estado.esPorSuperficie ? {..._superficies} : const {},
          detalle: detalle.isEmpty ? null : detalle,
        ),
      ];
      _superficies.clear();
      _detalleCtrl.clear();
    });
  }

  String _caras(HallazgoDental hallazgo) => [
    if (hallazgo.superficies.isEmpty)
      'Pieza completa'
    else
      hallazgo.superficies.map((s) => s.name).join(' · '),
    if (hallazgo.detalle != null) hallazgo.detalle!,
  ].join(' — ');

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AppDialog(
      preferredWidth: 460,
      title: Text(
        'Pieza ${widget.fdi}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ac.textPrimary,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hallazgos.isEmpty)
            Text(
              'Esta pieza aún no tiene hallazgos.',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            )
          else
            for (final hallazgo in _hallazgos)
              ListTile(
                key: ValueKey('hallazgo_${hallazgo.estado.dbValue}'),
                contentPadding: EdgeInsets.zero,
                leading: MarcaClinicaIcono(
                  marca: hallazgo.estado.marca,
                  estado: hallazgo.estado,
                  paleta: widget.paleta,
                  lado: 20,
                ),
                title: Text(
                  hallazgo.estado.label,
                  style: TextStyle(fontSize: 13, color: ac.textPrimary),
                ),
                subtitle: Text(
                  _caras(hallazgo),
                  style: TextStyle(fontSize: 11, color: ac.textMuted),
                ),
                trailing: IconButton(
                  tooltip: 'Quitar',
                  icon: Icon(Icons.close_rounded, size: 20, color: ac.red),
                  onPressed: () => setState(
                    () => _hallazgos = _hallazgos
                        .where((h) => h != hallazgo)
                        .toList(),
                  ),
                ),
              ),
          if (widget.historicos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.history_rounded, size: 13, color: ac.textMuted),
                const SizedBox(width: 5),
                Text(
                  'DE CONSULTAS ANTERIORES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: ac.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final hallazgo in widget.historicos)
              Padding(
                key: ValueKey('historico_${hallazgo.estado.dbValue}'),
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${hallazgo.estado.label} — ${_caras(hallazgo)}',
                  style: TextStyle(fontSize: 11, color: ac.textDisabled),
                ),
              ),
          ],
          const Divider(height: 22),
          Text(
            'Añadir hallazgo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<EstadoClinicoDental>(
            initialValue: _estado,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            style: TextStyle(fontSize: 13, color: ac.textPrimary),
            items: [
              for (final entrada in widget.leyenda)
                DropdownMenuItem(
                  value: entrada.estado,
                  child: Text(entrada.label),
                ),
            ],
            onChanged: (valor) => setState(() {
              _estado = valor ?? _estado;
              if (!_estado.esPorSuperficie) _superficies.clear();
            }),
          ),
          if (_estado.esPorSuperficie) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final superficie in _glifo.superficies)
                  FilterChip(
                    key: ValueKey('cara_${superficie.dbValue}'),
                    selected: _superficies.contains(superficie),
                    onSelected: (marcada) => setState(
                      () => marcada
                          ? _superficies.add(superficie)
                          : _superficies.remove(superficie),
                    ),
                    label: Text(superficie.name),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sin caras marcadas, la clave cubre la pieza completa.',
              style: TextStyle(fontSize: 10, color: ac.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _detalleCtrl,
            style: TextStyle(fontSize: 13, color: ac.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Anotación (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _agregar,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Añadir'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hallazgos),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
