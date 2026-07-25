import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/fdi_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
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
    this.editable = false,
    this.modoImpresion = false,
    this.leyenda,
    this.onChanged,
  });

  @override
  State<OdontodiagramaWidget> createState() => _OdontodiagramaWidgetState();
}

class _OdontodiagramaWidgetState extends State<OdontodiagramaWidget> {
  /// Color del papel. El diagrama no se adapta al tema: las claves están
  /// definidas en tinta roja y azul y deben leerse igual en pantalla, en modo
  /// oscuro y en el PDF impreso.
  static const Color _papel = Color(0xFFFDFDFC);
  static const Color _trazo = Color(0xFF334155);
  static const Color _reglaTabla = Color(0xFFB6BFCC);

  static const double _anchoMinimoDiagrama = 468;
  static const double _anchoMaximoDiagrama = 860;
  static const double _lineaMedia = 1.4;

  late EstadoClinicoDental _claveActiva;
  final Map<TejidoBlando, TextEditingController> _tejidoControllers = {};

  List<EntradaLeyendaOdontograma> get _leyenda =>
      widget.leyenda ?? leyendaClinicaPredeterminada;

  bool get _editando =>
      widget.editable && !widget.modoImpresion && widget.onChanged != null;

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

  void _tocarPieza(int fdi, TipoSuperficie? superficie) {
    if (!_editando) return;
    _emitir(
      widget.evaluacion.alternar(fdi, _claveActiva, superficie: superficie),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(context),
            if (_editando) ...[
              const SizedBox(height: 12),
              _paletaClaves(context),
            ],
            const SizedBox(height: 12),
            _panelPapel(disponible),
            const SizedBox(height: 14),
            _claves(context, compacto),
            const SizedBox(height: 18),
            _tejidosBlandos(context, compacto),
          ],
        );
      },
    );
  }

  Widget _encabezado(BuildContext context) {
    final ac = context.appColors;
    final titulo = widget.modoImpresion ? _trazo : ac.textPrimary;
    final apoyo = widget.modoImpresion ? _trazo : ac.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ODONTODIAGRAMA',
          style: TextStyle(
            color: titulo,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _editando
              ? 'Elige una clave y toca la cara del diente que quieras anotar. '
                    'Mantén pulsada una pieza para ver o quitar sus hallazgos.'
              : 'Nomenclatura FDI · dentición permanente y temporal',
          style: TextStyle(color: apoyo, fontSize: 11, height: 1.35),
        ),
      ],
    );
  }

  Widget _paletaClaves(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final entrada in _leyenda)
          ChoiceChip(
            key: ValueKey('clave_${entrada.estado.dbValue}'),
            selected: _claveActiva == entrada.estado,
            onSelected: (_) => setState(() => _claveActiva = entrada.estado),
            avatar: MarcaClinicaIcono(
              marca: entrada.marca,
              tinta: entrada.tinta,
              trazo: _trazo,
              lado: 15,
            ),
            label: Text(entrada.label),
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }

  Widget _panelPapel(double disponible) {
    const padding = 12.0;
    final util = disponible - padding * 2;
    final ancho = util.isFinite
        ? math.max(_anchoMinimoDiagrama, math.min(util, _anchoMaximoDiagrama))
        : _anchoMaximoDiagrama;

    return Container(
      decoration: BoxDecoration(
        color: _papel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _reglaTabla),
      ),
      padding: const EdgeInsets.all(padding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: ancho, child: _diagrama(ancho)),
      ),
    );
  }

  Widget _diagrama(double ancho) {
    final celda = (ancho - _lineaMedia) / (kColumnasPorHemicampo * 2);
    final filas = kFilasOdontodiagrama;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rotulos(filas[0]),
        const SizedBox(height: 4),
        _filaDoble(filas[0], celda),
        _filaDoble(filas[1], celda),
        Container(height: _lineaMedia, color: _trazo),
        _filaDoble(filas[2], celda),
        _filaDoble(filas[3], celda),
        const SizedBox(height: 4),
        _rotulos(filas[3]),
      ],
    );
  }

  Widget _rotulos(List<FilaOdontodiagrama> par) {
    Widget lado(FilaOdontodiagrama fila) => Expanded(
      child: Text(
        fila.rotulo ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _trazo,
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

  Widget _filaDoble(List<FilaOdontodiagrama> par, double celda) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hemifila(par[0], celda),
          Container(width: _lineaMedia, color: _trazo),
          _hemifila(par[1], celda),
        ],
      ),
    );
  }

  Widget _hemifila(FilaOdontodiagrama fila, double celda) {
    final huecos = kColumnasPorHemicampo - fila.piezas.length;
    final relleno = List.generate(
      huecos,
      (_) => SizedBox(width: celda),
      growable: false,
    );
    final piezas = [for (final fdi in fila.piezas) _celda(fdi, fila, celda)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: fila.hemicampoIzquierdo
          ? [...relleno, ...piezas]
          : [...piezas, ...relleno],
    );
  }

  Widget _celda(int fdi, FilaOdontodiagrama fila, double celda) {
    final lado = math.max(16.0, celda - 6);
    final numero = Text(
      '$fdi',
      style: TextStyle(
        color: _trazo,
        fontSize: math.min(10, math.max(7, celda * 0.24)),
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
      lado: lado,
      papel: _papel,
      trazo: _trazo,
      editable: _editando,
      onTap: (superficie) => _tocarPieza(fdi, superficie),
      onDetalle: () => _abrirDetallePieza(fdi, fila),
    );

    return SizedBox(
      width: celda,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fila.superior
              ? [numero, const SizedBox(height: 2), pieza]
              : [pieza, const SizedBox(height: 2), numero],
        ),
      ),
    );
  }

  Widget _claves(BuildContext context, bool compacto) {
    final ac = context.appColors;
    final texto = widget.modoImpresion ? _trazo : ac.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLAVES',
          style: TextStyle(
            color: widget.modoImpresion ? _trazo : ac.textPrimary,
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
                    tinta: entrada.tinta,
                    trazo: _trazo,
                    lado: 15,
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
      ],
    );
  }

  Widget _tejidosBlandos(BuildContext context, bool compacto) {
    final ac = context.appColors;
    final borde = Border.all(color: _reglaTabla);
    final anchoEtiqueta = compacto ? 104.0 : 128.0;

    return Container(
      decoration: BoxDecoration(
        color: _papel,
        borderRadius: BorderRadius.circular(10),
        border: borde,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _reglaTabla)),
            ),
            child: const Text(
              'Tejidos Blandos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _trazo,
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
              ac: ac,
            ),
        ],
      ),
    );
  }

  Widget _filaTejido(
    TejidoBlando tejido,
    double anchoEtiqueta, {
    required bool ultima,
    required AppColors ac,
  }) {
    final anotacion = widget.evaluacion.tejidosBlandos[tejido] ?? '';

    final valor = _editando
        ? TextField(
            key: ValueKey('tejido_${tejido.dbValue}'),
            controller: _tejidoControllers[tejido],
            onChanged: (texto) =>
                _emitir(widget.evaluacion.conTejido(tejido, texto)),
            style: const TextStyle(color: _trazo, fontSize: 12),
            cursorColor: _trazo,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Sin alteración',
              hintStyle: TextStyle(color: Color(0xFF9AA4B2), fontSize: 12),
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              anotacion.isEmpty ? '—' : anotacion,
              key: ValueKey('tejido_valor_${tejido.dbValue}'),
              style: TextStyle(
                color: anotacion.isEmpty ? const Color(0xFF9AA4B2) : _trazo,
                fontSize: 12,
              ),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: _reglaTabla)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: anchoEtiqueta,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                tejido.label,
                style: const TextStyle(
                  color: _trazo,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 26, color: _reglaTabla),
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
        leyenda: _leyenda,
      ),
    );
    if (resultado == null || !mounted) return;
    _emitir(widget.evaluacion.conHallazgos(fdi, resultado));
  }
}

/// El odontodiagrama sobre papel y sin controles, para el expediente, el
/// histórico y la captura a PDF. Fija el fondo blanco para que la tinta roja y
/// azul se lea igual en modo claro, en modo oscuro y en la impresión.
class OdontodiagramaPapel extends StatelessWidget {
  final EvaluacionOdontologica evaluacion;
  final EdgeInsetsGeometry padding;

  const OdontodiagramaPapel({
    super.key,
    required this.evaluacion,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: padding,
    child: OdontodiagramaWidget(evaluacion: evaluacion, modoImpresion: true),
  );
}

/// Una pieza del diagrama: dibuja el glifo y traduce el punto tocado a la cara
/// dental correspondiente.
class _PiezaDental extends StatefulWidget {
  final GlifoPieza glifo;
  final List<HallazgoDental> hallazgos;
  final double lado;
  final Color papel;
  final Color trazo;
  final bool editable;
  final ValueChanged<TipoSuperficie?> onTap;
  final VoidCallback onDetalle;

  const _PiezaDental({
    super.key,
    required this.glifo,
    required this.hallazgos,
    required this.lado,
    required this.papel,
    required this.trazo,
    required this.editable,
    required this.onTap,
    required this.onDetalle,
  });

  @override
  State<_PiezaDental> createState() => _PiezaDentalState();
}

class _PiezaDentalState extends State<_PiezaDental> {
  bool _hover = false;

  String get _descripcion {
    final fdi = widget.glifo.fdi;
    if (widget.hallazgos.isEmpty) return 'Pieza $fdi, sin hallazgos';
    final partes = widget.hallazgos.map((h) {
      final caras = h.superficies.isEmpty
          ? 'pieza completa'
          : h.superficies.map((s) => s.name.toLowerCase()).join(', ');
      return '${h.estado.label} ($caras)';
    });
    return 'Pieza $fdi: ${partes.join('; ')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget pieza = CustomPaint(
      size: Size.square(widget.lado),
      painter: GlifoPiezaPainter(
        glifo: widget.glifo,
        hallazgos: widget.hallazgos,
        trazo: widget.trazo,
        papel: widget.papel,
        resalte: _hover
            ? context.appColors.primaryBlue.withValues(alpha: 0.12)
            : null,
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
/// eligiendo caras concretas y una anotación libre.
class _DetallePiezaDialog extends StatefulWidget {
  final int fdi;
  final FilaOdontodiagrama fila;
  final List<HallazgoDental> hallazgos;
  final List<EntradaLeyendaOdontograma> leyenda;

  const _DetallePiezaDialog({
    required this.fdi,
    required this.fila,
    required this.hallazgos,
    required this.leyenda,
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

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AppDialog(
      preferredWidth: 440,
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
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: MarcaClinicaIcono(
                  marca: hallazgo.estado.marca,
                  tinta: hallazgo.estado.tinta,
                  trazo: ac.textSecondary,
                  lado: 18,
                ),
                title: Text(
                  hallazgo.estado.label,
                  style: TextStyle(fontSize: 13, color: ac.textPrimary),
                ),
                subtitle: Text(
                  [
                    if (hallazgo.superficies.isEmpty)
                      'Pieza completa'
                    else
                      hallazgo.superficies.map((s) => s.name).join(' · '),
                    if (hallazgo.detalle != null) hallazgo.detalle!,
                  ].join(' — '),
                  style: TextStyle(fontSize: 11, color: ac.textMuted),
                ),
                trailing: IconButton(
                  tooltip: 'Quitar',
                  icon: Icon(Icons.close_rounded, size: 17, color: ac.red),
                  onPressed: () => setState(
                    () => _hallazgos = _hallazgos
                        .where((h) => h != hallazgo)
                        .toList(),
                  ),
                ),
              ),
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
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
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
              spacing: 6,
              runSpacing: 6,
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
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
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
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _agregar,
              icon: const Icon(Icons.add_rounded, size: 16),
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
