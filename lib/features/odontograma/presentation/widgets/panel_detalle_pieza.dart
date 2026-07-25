import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/leyenda_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/trazo_punteado.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'tooth_geometry.dart';

// ─────────────────────────────────────────────
//  Functional tooth status colors — el *rol* es dato clínico; el tono se
//  ajusta al tema para que un diente tratado no desaparezca sobre fondo oscuro.
// ─────────────────────────────────────────────

const _kToothTeal = Color(0xFF0D9488);
const _kToothIndigo = Color(0xFF6366F1);
const _kToothAmber = Color(0xFFF59E0B);
const _kToothRed = Color(0xFFEF4444);
const _kToothEmpty = Color(0xFFCBD5E1);
// Gris azulado para la capa "histórico" (tratamientos de consultas previas):
// presente pero apagado, claramente distinto del teal de "esta consulta".
const _kToothSlate = Color(0xFF64748B);

// ─────────────────────────────────────────────
//  Tooth status
// ─────────────────────────────────────────────

enum ToothStatus { empty, treated, historico, mild, moderate, critical }

Color colorForStatus(ToothStatus s, {bool oscuro = false}) => oscuro
    ? switch (s) {
        ToothStatus.empty => const Color(0xFF52627A),
        ToothStatus.treated => const Color(0xFF2DD4BF),
        ToothStatus.historico => const Color(0xFF94A3B8),
        ToothStatus.mild => const Color(0xFF818CF8),
        ToothStatus.moderate => const Color(0xFFFBBF24),
        ToothStatus.critical => const Color(0xFFFC6B6B),
      }
    : switch (s) {
        ToothStatus.empty => _kToothEmpty,
        ToothStatus.treated => _kToothTeal,
        ToothStatus.historico => _kToothSlate,
        ToothStatus.mild => _kToothIndigo,
        ToothStatus.moderate => _kToothAmber,
        ToothStatus.critical => _kToothRed,
      };

/// Superficie sobre la que se dibuja la arcada. Los dientes se pintaban en
/// blanco fijo con filetes gris claro: sobre el papel oscuro del tema eso deja
/// una arcada deslumbrante y una línea media invisible.
@immutable
class PaletaArcada {
  /// Relleno de un diente sin hallazgos.
  final Color esmalte;

  /// Línea media y filetes de la cuadrícula de superficies.
  final Color regla;

  /// Contorno de un diente sin estado y relleno de uno ausente.
  final Color vacio;

  /// Halo bajo los puntos indicadores, para separarlos del contorno.
  final Color halo;

  final bool oscuro;

  const PaletaArcada({
    required this.esmalte,
    required this.regla,
    required this.vacio,
    required this.halo,
    required this.oscuro,
  });

  factory PaletaArcada.de(BuildContext context) {
    final ac = context.appColors;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return PaletaArcada(
      esmalte: oscuro ? const Color(0xFF1C2537) : Colors.white,
      regla: oscuro ? const Color(0xFF2A3752) : const Color(0xFFEEF2F7),
      // El contorno se dibuja al 59 % de alfa cuando la pieza no tiene estado;
      // por debajo de este tono la arcada desaparece sobre la tarjeta oscura.
      vacio: oscuro ? const Color(0xFF6C7E97) : _kToothEmpty,
      halo: oscuro ? ac.cardBg : Colors.white,
      oscuro: oscuro,
    );
  }

  Color status(ToothStatus s) => colorForStatus(s, oscuro: oscuro);

  @override
  bool operator ==(Object other) =>
      other is PaletaArcada &&
      other.esmalte == esmalte &&
      other.regla == regla &&
      other.vacio == vacio &&
      other.halo == halo &&
      other.oscuro == oscuro;

  @override
  int get hashCode => Object.hash(esmalte, regla, vacio, halo, oscuro);
}

ToothStatus statusForDiente(Diente? d) {
  if (d == null) return ToothStatus.empty;
  if (dienteEstaAusente(d)) return ToothStatus.empty;
  if (d.diagnosis.isNotEmpty) {
    var worst = SeveridadDiagnosis.leve;
    for (final diag in d.diagnosis) {
      if (diag.severidad == SeveridadDiagnosis.grave) {
        return ToothStatus.critical;
      }
      if (diag.severidad == SeveridadDiagnosis.moderada) {
        worst = SeveridadDiagnosis.moderada;
      }
    }
    return worst == SeveridadDiagnosis.moderada
        ? ToothStatus.moderate
        : ToothStatus.mild;
  }
  // Tratamientos cargados como entidades o solo vinculados por id en la BD.
  if (d.tratamientos.isNotEmpty || d.tratamientosAplicadosIds.isNotEmpty) {
    return ToothStatus.treated;
  }
  // Sin trabajo en esta consulta pero con antecedentes: capa histórica.
  if (d.tratamientosHistoricos.isNotEmpty) return ToothStatus.historico;
  if (d.superficies.any((s) => s.diagnosisId != null)) return ToothStatus.mild;
  return ToothStatus.empty;
}

/// Todo lo anotado sobre la pieza [d], listo para pintar y para listar.
///
/// Cada cara se colorea por lo que clínicamente tiene —una caries en rojo, una
/// restauración en azul—, no por un color de presentación elegido para que se
/// distinga del de al lado. El tono sale de la clave del catálogo y el trazo,
/// de la procedencia; ambas cosas están en [MarcaClinicaPieza].
///
/// Una pieza ausente no muestra caras: lo que hubiera en ellas ya no está en
/// la boca.
List<MarcaClinicaPieza> marcasDelDiente(
  Diente? d, {
  int? fdi,
  List<ItemPlanTratamiento> itemsPlan = const [],
  List<HallazgoDental> hallazgosHistoricos = const [],
  String Function(String tratamientoId)? nombreTratamiento,
}) {
  final codigo = fdi ?? d?.fdiCode;
  if (codigo == null) return const [];
  return marcasDePieza(
    fdi: codigo,
    diente: d,
    itemsPlan: itemsPlan,
    hallazgosHistoricos: hallazgosHistoricos,
    nombreTratamiento: nombreTratamiento,
  );
}

/// La marca que colorea la cara [cara] del diente [d], o `null` si no tiene
/// nada anotado.
MarcaClinicaPieza? marcaDeSuperficieDelDiente(
  Diente? d,
  TipoSuperficie cara, {
  List<ItemPlanTratamiento> itemsPlan = const [],
}) {
  if (d == null || dienteEstaAusente(d)) return null;
  return marcaDeSuperficie(marcasDelDiente(d, itemsPlan: itemsPlan), cara);
}

/// Indicador de los tratamientos aplicados en vivo sobre un diente:
/// ámbar si hay alguno en proceso, verde si todos están terminados.
enum TratamientoIndicador { ninguno, enProceso, finalizado }

TratamientoIndicador indicadorTratamiento(Diente? d) {
  if (d == null || dienteEstaAusente(d) || d.tratamientos.isEmpty) {
    return TratamientoIndicador.ninguno;
  }
  final hayEnProceso = d.tratamientos.any((t) => !t.estaTerminado);
  return hayEnProceso
      ? TratamientoIndicador.enProceso
      : TratamientoIndicador.finalizado;
}

/// Si la pieza se dibuja en la mitad izquierda de la boca vista de frente.
///
/// Decide de qué lado se coloca el panel: pegado a su pieza, nunca tapándola.
/// Vale igual para la arcada y para el odontodiagrama porque ambos ordenan los
/// cuadrantes de la misma manera.
bool piezaEnMitadIzquierda(int fdi) =>
    (fdi >= 11 && fdi <= 18) ||
    (fdi >= 41 && fdi <= 48) ||
    (fdi >= 51 && fdi <= 55) ||
    (fdi >= 81 && fdi <= 85);

// ─────────────────────────────────────────────
//  Panel de detalle de una pieza
// ─────────────────────────────────────────────

/// Ficha flotante de una pieza: su mapa de caras, lo que tiene anotado y los
/// botones para añadir un diagnóstico o un tratamiento.
///
/// Es el único editor por pieza de la aplicación. La arcada y el
/// odontodiagrama lo montan igual —al lado de la pieza tocada— para que el
/// doctor no tenga que aprender dos interacciones para la misma boca.
class PanelDetallePieza extends StatefulWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;

  /// Claves anotadas sobre esta pieza en consultas anteriores. El diagrama ya
  /// no las dibuja en tinta tenue —llenaba el papel de marcas en una boca muy
  /// tratada—, así que este panel es donde se consultan.
  final List<HallazgoDental> hallazgosHistoricos;

  /// Actividades del plan que caen sobre esta pieza. Se listan aparte de lo
  /// ejecutado porque planificar y hacer son actos distintos (SD-135).
  final List<ItemPlanTratamiento> itemsPlan;

  final VoidCallback onClose;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;

  /// Anota una observación clínica sobre la pieza. `null` deja el campo en solo
  /// lectura.
  final void Function(Diente, String)? onNotasChanged;

  final String Function(String tratamientoId)? nombreTratamiento;

  /// Resuelve el nombre del doctor de una anotación. Sin él, la ficha omite la
  /// autoría en vez de mostrar un identificador que no dice nada.
  final String Function(String doctorId)? nombreDoctor;

  const PanelDetallePieza({
    super.key,
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.onClose,
    this.hallazgosHistoricos = const [],
    this.itemsPlan = const [],
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTerminado,
    this.onNotasChanged,
    this.nombreTratamiento,
    this.nombreDoctor,
  });

  @override
  State<PanelDetallePieza> createState() => _PanelDetallePiezaState();
}

class _PanelDetallePiezaState extends State<PanelDetallePieza> {
  TipoSuperficie? _selectedSurface;
  late final TextEditingController _notas;
  final _focoNotas = FocusNode();

  @override
  void initState() {
    super.initState();
    _notas = TextEditingController(text: widget.diente?.observaciones ?? '');
  }

  @override
  void didUpdateWidget(covariant PanelDetallePieza old) {
    super.didUpdateWidget(old);
    // Mientras el campo tiene el foco, lo que llega de fuera es el eco de esta
    // misma escritura —ya recortada por el cubit— y reasignarlo mandaría el
    // cursor al principio en cuanto se escribe un espacio.
    if (_focoNotas.hasFocus) return;
    final entrante = widget.diente?.observaciones ?? '';
    if (_notas.text != entrante) _notas.text = entrante;
  }

  @override
  void dispose() {
    _focoNotas.dispose();
    _notas.dispose();
    super.dispose();
  }

  List<MarcaClinicaPieza> get _marcas => marcasDelDiente(
    widget.diente,
    fdi: widget.fdi,
    itemsPlan: widget.itemsPlan,
    hallazgosHistoricos: widget.hallazgosHistoricos,
    nombreTratamiento: widget.nombreTratamiento,
  );

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final paleta = PaletaArcada.de(context);
    final name = kFdiNames[widget.fdi] ?? 'Diente ${widget.fdi}';
    final d = widget.diente;
    final isAbsent = d != null && dienteEstaAusente(d);
    final marcas = _marcas;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: paleta
                      .status(statusForDiente(d))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '${widget.fdi}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: paleta.status(statusForDiente(d)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (widget.editMode && d != null)
                GestureDetector(
                  onTap: () => widget.onToggleAusente?.call(d, !isAbsent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAbsent
                          ? ac.teal.withValues(alpha: 0.12)
                          : ac.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isAbsent ? 'Restaurar' : 'Ausente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAbsent ? ac.teal : ac.red,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ac.chipBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: ac.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 16),

          Center(
            child: _MapaSuperficies(
              key: const ValueKey('mapa_superficies'),
              fdi: widget.fdi,
              marcas: isAbsent ? const [] : marcas,
              editMode: widget.editMode,
              selectedSurface: _selectedSurface,
              onSurfaceSelected: (s) => setState(() {
                _selectedSurface = (_selectedSurface == s) ? null : s;
              }),
            ),
          ),
          const SizedBox(height: 16),

          _MarcasPieza(
            diente: d,
            marcas: marcas,
            editMode: widget.editMode,
            selectedSurface: _selectedSurface,
            nombreDoctor: widget.nombreDoctor,
            onAddDiagnosis: widget.onAddDiagnosis,
            onAddTratamiento: widget.onAddTratamiento,
            onQuitarTratamiento: widget.onQuitarTratamiento,
            onToggleTerminado: widget.onToggleTerminado,
          ),

          if (d != null) ...[
            const SizedBox(height: 14),
            _NotasPieza(
              controller: _notas,
              foco: _focoNotas,
              onChanged: widget.onNotasChanged == null
                  ? null
                  : (texto) => widget.onNotasChanged!(d, texto),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Notas clínicas de la pieza
// ─────────────────────────────────────────────

/// Observación pegada al diente, no a la visita.
///
/// Antes lo único editable eran las notas generales de la consulta: una
/// anotación sobre el 36 se perdía dentro del párrafo de la sesión y, al abrir
/// la pieza meses después, no había manera de recuperarla. Esto se guarda en
/// `dientes.observaciones` y viaja con la pieza.
class _NotasPieza extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode foco;
  final ValueChanged<String>? onChanged;

  const _NotasPieza({
    required this.controller,
    required this.foco,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final soloLectura = onChanged == null;
    if (soloLectura && controller.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: ac.divider),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'NOTAS DE LA PIEZA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ac.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (soloLectura)
          Text(
            controller.text,
            style: TextStyle(
              fontSize: 12,
              color: ac.textSecondary,
              height: 1.4,
            ),
          )
        else
          TextField(
            key: const ValueKey('notas_pieza'),
            controller: controller,
            focusNode: foco,
            onChanged: onChanged,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(fontSize: 12, color: ac.textPrimary, height: 1.4),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Observación clínica de este diente…',
              hintStyle: TextStyle(fontSize: 12, color: ac.textMuted),
              filled: true,
              fillColor: ac.chipBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.indigo, width: 1.4),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Surface map
// ─────────────────────────────────────────────

class _MapaSuperficies extends StatelessWidget {
  final int fdi;
  final List<MarcaClinicaPieza> marcas;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final ValueChanged<TipoSuperficie> onSurfaceSelected;

  const _MapaSuperficies({
    super.key,
    required this.fdi,
    required this.marcas,
    required this.editMode,
    required this.selectedSurface,
    required this.onSurfaceSelected,
  });

  static const double _size = 152;
  static const double _a = 0.32;
  static const double _b = 0.68;

  TipoSuperficie get _centerSurface =>
      isAnteriorTooth(fdi) ? TipoSuperficie.incisal : TipoSuperficie.oclusal;
  TipoSuperficie get _bottomSurface =>
      isUpperTooth(fdi) ? TipoSuperficie.palatina : TipoSuperficie.lingual;

  TipoSuperficie? _regionAt(Offset p) {
    final x = p.dx / _size;
    final y = p.dy / _size;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    if (x >= _a && x <= _b && y >= _a && y <= _b) return _centerSurface;
    if (y < x && y < 1 - x) return TipoSuperficie.vestibular;
    if (y > x && y > 1 - x) return _bottomSurface;
    if (x < y && x < 1 - y) return TipoSuperficie.mesial;
    return TipoSuperficie.distal;
  }

  /// Nombre de cada cara y lo que tiene, para quien navega con lector de
  /// pantalla y no puede ver el color.
  String _descripcion(Map<TipoSuperficie, MarcaClinicaPieza?> porCara) {
    final anotadas = [
      for (final entry in porCara.entries)
        if (entry.value case final marca?)
          '${entry.key.name}: ${marca.titulo}, ${marca.procedencia.etiqueta.toLowerCase()}',
    ];
    if (anotadas.isEmpty) return 'Caras del diente $fdi, ninguna anotada';
    return 'Caras del diente $fdi. ${anotadas.join('. ')}';
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = context.appColors.textDisabled;
    final paletaClinica = PaletaOdontodiagrama.de(context);
    final porCara = {
      for (final cara in TipoSuperficie.values)
        cara: marcaDeSuperficie(marcas, cara),
    };

    Widget map = CustomPaint(
      size: const Size(_size, _size),
      painter: _MapaSuperficiesPainter(
        marcaPorCara: porCara,
        centerSurface: _centerSurface,
        bottomSurface: _bottomSurface,
        selected: selectedSurface,
        a: _a,
        b: _b,
        labelColor: labelColor,
        paleta: PaletaArcada.de(context),
        paletaClinica: paletaClinica,
      ),
    );

    map = Semantics(label: _descripcion(porCara), child: map);

    if (editMode) {
      map = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapUp: (d) {
            final s = _regionAt(d.localPosition);
            if (s != null) onSurfaceSelected(s);
          },
          child: map,
        ),
      );
    }

    return SizedBox(width: _size, height: _size, child: map);
  }
}

class _MapaSuperficiesPainter extends CustomPainter {
  /// Lo que tiñe cada cara. `null` en una cara sin nada anotado.
  final Map<TipoSuperficie, MarcaClinicaPieza?> marcaPorCara;

  final TipoSuperficie centerSurface;
  final TipoSuperficie bottomSurface;
  final TipoSuperficie? selected;
  final double a;
  final double b;
  final Color labelColor;
  final PaletaArcada paleta;

  /// De aquí sale el color de cada cara: la tinta de su clave clínica.
  final PaletaOdontodiagrama paletaClinica;

  const _MapaSuperficiesPainter({
    required this.marcaPorCara,
    required this.centerSurface,
    required this.bottomSurface,
    required this.selected,
    required this.a,
    required this.b,
    required this.labelColor,
    required this.paleta,
    required this.paletaClinica,
  });

  Color get _sinDatos => paleta.esmalte;
  Color get _seleccion => paleta.status(ToothStatus.treated);

  EstiloMarcaClinica? _estilo(TipoSuperficie cara) {
    final marca = marcaPorCara[cara];
    if (marca == null) return null;
    return paletaClinica.estiloDe(marca.claveEfectiva, marca.procedencia);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tl = Offset.zero;
    final tr = Offset(w, 0);
    final bl = Offset(0, h);
    final br = Offset(w, h);
    final itl = Offset(a * w, a * h);
    final itr = Offset(b * w, a * h);
    final ibl = Offset(a * w, b * h);
    final ibr = Offset(b * w, b * h);

    final regions = <TipoSuperficie, List<Offset>>{
      TipoSuperficie.vestibular: [tl, tr, itr, itl],
      bottomSurface: [bl, br, ibr, ibl],
      TipoSuperficie.mesial: [tl, itl, ibl, bl],
      TipoSuperficie.distal: [tr, itr, ibr, br],
      centerSurface: [itl, itr, ibr, ibl],
    };

    final labels = <TipoSuperficie, (String, Offset)>{
      TipoSuperficie.vestibular: ('V', Offset(w * 0.5, h * 0.16)),
      bottomSurface: (
        bottomSurface == TipoSuperficie.palatina ? 'P' : 'L',
        Offset(w * 0.5, h * 0.84),
      ),
      TipoSuperficie.mesial: ('M', Offset(w * 0.16, h * 0.5)),
      TipoSuperficie.distal: ('D', Offset(w * 0.84, h * 0.5)),
      centerSurface: (
        centerSurface == TipoSuperficie.incisal ? 'I' : 'O',
        Offset(w * 0.5, h * 0.5),
      ),
    };

    regions.forEach((t, poly) {
      final path = Path()..addPolygon(poly, true);
      final isSel = selected == t;
      final estilo = _estilo(t);

      // El fondo del esmalte va siempre debajo: sobre él, el relleno de la
      // marca ya lleva su propia opacidad, así que una cara planificada —que no
      // se rellena— queda perfilada sobre papel y no sobre un hueco.
      canvas.drawPath(path, Paint()..color = _sinDatos);
      if (estilo != null && estilo.alfaRelleno > 0) {
        canvas.drawPath(path, Paint()..color = estilo.relleno);
      }
      if (isSel) {
        canvas.drawPath(path, Paint()..color = _seleccion.withAlpha(30));
      }

      final trazo = Paint()
        ..color = isSel ? _seleccion : (estilo?.trazo ?? paleta.regla)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? 2.0 : (estilo?.grosorTrazo ?? 1.2)
        ..strokeJoin = StrokeJoin.round;

      // El punteado es lo que distingue una cara planificada de una tratada sin
      // depender del color, que es justo lo que se pierde al imprimir en gris.
      if (estilo != null && estilo.punteado && !isSel) {
        dibujarPoligonoPunteado(canvas, poly, trazo);
      } else {
        canvas.drawPath(path, trazo);
      }
    });

    labels.forEach((t, lbl) {
      final isSel = selected == t;
      final estilo = _estilo(t);
      final tp = TextPainter(
        text: TextSpan(
          text: lbl.$1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel ? _seleccion : (estilo?.color ?? labelColor),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, lbl.$2.translate(-tp.width / 2, -tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_MapaSuperficiesPainter old) =>
      !mapEquals(old.marcaPorCara, marcaPorCara) ||
      old.selected != selected ||
      old.centerSurface != centerSurface ||
      old.bottomSurface != bottomSurface ||
      old.labelColor != labelColor ||
      old.paleta != paleta ||
      old.paletaClinica != paletaClinica;
}

// ─────────────────────────────────────────────
//  Marcas de la pieza, agrupadas por procedencia
// ─────────────────────────────────────────────

/// Todo lo anotado sobre la pieza, en un solo formato y agrupado por su
/// procedencia.
///
/// Antes esto eran tres listas con tres aspectos distintos —diagnósticos,
/// tratamientos, histórico— y ninguna decía de qué consulta ni de qué doctor
/// venía cada línea; el plan de tratamiento ni siquiera aparecía. Cada fila
/// lleva ahora tipo, cara, estado, fecha, consulta, doctor y notas, que es lo
/// que hace falta para leer una pieza sin salir de su ficha.
class _MarcasPieza extends StatelessWidget {
  final Diente? diente;
  final List<MarcaClinicaPieza> marcas;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final String Function(String doctorId)? nombreDoctor;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;

  const _MarcasPieza({
    required this.diente,
    required this.marcas,
    required this.editMode,
    required this.selectedSurface,
    this.nombreDoctor,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onQuitarTratamiento,
    this.onToggleTerminado,
  });

  /// El orden en que se cuenta la historia de la pieza: qué se halló, qué se
  /// decidió, qué se hizo y qué traía de antes.
  static const _orden = [
    ProcedenciaMarca.evaluado,
    ProcedenciaMarca.planificado,
    ProcedenciaMarca.ejecutado,
    ProcedenciaMarca.historico,
  ];

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final d = diente;
    final puedeEditar = editMode && d != null;

    if (marcas.isEmpty && !puedeEditar) {
      return Text(
        'Sin datos registrados',
        style: TextStyle(fontSize: 12, color: ac.textDisabled),
      );
    }

    final paletaClinica = PaletaOdontodiagrama.de(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final procedencia in _orden)
          if (marcas.where((m) => m.procedencia == procedencia).toList()
              case final grupo when grupo.isNotEmpty) ...[
            _EncabezadoProcedencia(
              procedencia: procedencia,
              paleta: paletaClinica,
              conteo: grupo.length,
            ),
            const SizedBox(height: 6),
            for (final marca in grupo)
              _FilaMarca(
                marca: marca,
                paleta: paletaClinica,
                nombreDoctor: nombreDoctor,
                onToggleTerminado:
                    _editaEjecucion(marca) && onToggleTerminado != null
                    ? () => onToggleTerminado!(
                        d!,
                        marca.indiceOrigen!,
                        marca.estado != 'Terminado',
                      )
                    : null,
                onQuitar: _editaEjecucion(marca) && onQuitarTratamiento != null
                    ? () => onQuitarTratamiento!(d!, marca.indiceOrigen!)
                    : null,
              ),
            const SizedBox(height: 10),
          ],
        if (puedeEditar) ...[
          const SizedBox(height: 4),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BotonAnadir(
                etiqueta: 'Diagnóstico',
                color: ac.indigo,
                onPressed: onAddDiagnosis == null
                    ? null
                    : () => onAddDiagnosis!(d, selectedSurface),
              ),
              _BotonAnadir(
                etiqueta: 'Tratamiento',
                color: ac.teal,
                onPressed: onAddTratamiento == null
                    ? null
                    : () => onAddTratamiento!(d, selectedSurface),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Solo lo ejecutado en esta consulta se edita desde la ficha: un antecedente
  /// pertenece a otra consulta y una actividad del plan se decide en el plan.
  bool _editaEjecucion(MarcaClinicaPieza marca) =>
      editMode &&
      diente != null &&
      marca.procedencia == ProcedenciaMarca.ejecutado &&
      marca.indiceOrigen != null;
}

class _EncabezadoProcedencia extends StatelessWidget {
  final ProcedenciaMarca procedencia;
  final PaletaOdontodiagrama paleta;
  final int conteo;

  const _EncabezadoProcedencia({
    required this.procedencia,
    required this.paleta,
    required this.conteo,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Semantics(
      header: true,
      label: '${procedencia.etiqueta}: ${procedencia.descripcion}. $conteo',
      excludeSemantics: true,
      child: Row(
        children: [
          MuestraProcedencia(
            procedencia: procedencia,
            paleta: paleta,
            lado: 13,
          ),
          const SizedBox(width: 6),
          Text(
            procedencia.etiqueta.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              procedencia.descripcion,
              style: TextStyle(fontSize: 10, color: ac.textDisabled),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una anotación: qué es, sobre qué cara, en qué estado, y de dónde viene.
class _FilaMarca extends StatelessWidget {
  final MarcaClinicaPieza marca;
  final PaletaOdontodiagrama paleta;
  final String Function(String doctorId)? nombreDoctor;
  final VoidCallback? onToggleTerminado;
  final VoidCallback? onQuitar;

  const _FilaMarca({
    required this.marca,
    required this.paleta,
    this.nombreDoctor,
    this.onToggleTerminado,
    this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final tinta = paleta.tintaDe(marca.claveEfectiva);
    final procedencia = procedenciaAtenuada(marca, ac);
    final origen = _origen(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: descripcionAccesible(marca, nombreDoctor: nombreDoctor),
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: marca.vigente ? tinta : tinta.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conSuperficie(marca.titulo, marca.superficie),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: procedencia,
                    ),
                  ),
                  if (origen.isNotEmpty)
                    Text(
                      origen,
                      style: TextStyle(fontSize: 10, color: ac.textDisabled),
                    ),
                  if (marca.notas case final notas?)
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
            _ChipEstado(
              texto: marca.estado,
              color: tinta,
              onTap: onToggleTerminado,
            ),
            if (onQuitar != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onQuitar,
                child: Tooltip(
                  message: 'Quitar',
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: ac.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// «12/6/2026 · Dr. Pérez · Consulta ab12cd34». Se omite lo que no se sabe en
  /// vez de rellenarlo con un identificador que no dice nada.
  String _origen(BuildContext context) {
    final partes = <String>[
      if (marca.fecha case final fecha?) fechaCortaDeMarca(fecha),
      if (marca.doctorId case final doctorId?)
        if (nombreDoctor?.call(doctorId) case final nombre?
            when nombre.trim().isNotEmpty)
          nombre,
      if (marca.consultaId case final consultaId?
          when marca.procedencia == ProcedenciaMarca.historico)
        'Consulta ${referenciaCorta(consultaId)}',
    ];
    return partes.join(' · ');
  }
}

/// Los antecedentes y lo que ya no se hará se leen más apagados: siguen ahí,
/// pero no describen el estado de hoy.
Color procedenciaAtenuada(MarcaClinicaPieza marca, AppColors ac) =>
    !marca.vigente || marca.procedencia == ProcedenciaMarca.historico
    ? ac.textMuted
    : ac.textSecondary;

class _ChipEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final VoidCallback? onTap;

  const _ChipEstado({required this.texto, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}

class _BotonAnadir extends StatelessWidget {
  final String etiqueta;
  final Color color;
  final VoidCallback? onPressed;

  const _BotonAnadir({
    required this.etiqueta,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add_rounded, size: 14),
    label: Text(etiqueta),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.40)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

/// «Resina compuesta · Oclusal», o solo el nombre si la marca es de la pieza
/// entera. La cara es dato clínico: sin ella, dos resinas en el mismo diente se
/// leen como una repetición.
String conSuperficie(String nombre, TipoSuperficie? superficie) =>
    superficie == null ? nombre : '$nombre · ${superficie.name}';

/// Los ocho primeros caracteres de un uuid: lo justo para reconocer la consulta
/// sin llenar la ficha de identificadores.
String referenciaCorta(String id) => id.length > 8 ? id.substring(0, 8) : id;

String fechaCortaDeMarca(DateTime fecha) =>
    '${fecha.day}/${fecha.month}/${fecha.year}';

/// La fila entera dicha en voz alta, para quien no ve el color ni el trazo.
String descripcionAccesible(
  MarcaClinicaPieza marca, {
  String Function(String doctorId)? nombreDoctor,
}) {
  final cara = marca.superficie == null
      ? 'pieza completa'
      : 'cara ${marca.superficie!.name.toLowerCase()}';
  final partes = <String>[
    '${marca.titulo}, $cara',
    marca.procedencia.etiqueta.toLowerCase(),
    marca.estado.toLowerCase(),
    if (marca.fecha case final fecha?) fechaCortaDeMarca(fecha),
    if (marca.doctorId case final doctorId?)
      if (nombreDoctor?.call(doctorId) case final nombre?
          when nombre.trim().isNotEmpty)
        nombre,
    ?marca.notas,
  ];
  return partes.join('. ');
}
