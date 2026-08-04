import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/selector_actividades_plan.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/recorte_foto_dialog.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

enum _Step { buscarPersona, formularioCita }

enum _Paso1Mode { idle, nuevaPersona }

class _CedulaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3) buffer.write('-');
      if (i == 10) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class NuevaCitaDialog extends StatefulWidget {
  final PersonaRepository personaRepository;
  final DoctorRepository doctorRepository;

  /// El paciente nuevo se registra por aquí y no por `personaRepository`: una
  /// persona sin fila en `pacientes` no aparece en el listado ni puede
  /// atenderse, y perdía el género y el tipo que este formulario ya pide.
  final IPacienteRepository pacienteRepository;

  /// Sirve las actividades del plan que la cita puede atender (SD-146). Llega
  /// por parámetro como los demás repositorios: el diálogo no busca nada en el
  /// service locator, y así la prueba puede sustituirlo.
  final CitaRepository citaRepository;

  /// Momento con el que abre el diálogo cuando se llega desde una casilla de la
  /// agenda. Sin esto, tocar las 9:00 del miércoles abría un formulario vacío y
  /// obligaba a volver a elegir el día y la hora que ya se habían señalado.
  final DateTime? fechaInicial;

  /// Atención de urgencia para alguien que ya está en la clínica (HFX-CLIN-004).
  ///
  /// Cambia lo que el formulario pide y lo que hace al confirmar: no hay fecha
  /// ni hora que elegir —es ahora—, y la cita nace marcada como emergencia y ya
  /// en espera. Hasta este ticket no existía ninguna vía para eso y la urgencia
  /// se resolvía inventando citas o editando filas en Supabase.
  final bool emergencia;

  /// Doctor con el que abre el desplegable. Quien ejerce se propone a sí mismo;
  /// un asistente llega sin nada preseleccionado y tiene que elegir responsable.
  final String? doctorPredeterminadoId;

  /// El selector de odontólogo queda fijo en [doctorPredeterminadoId].
  ///
  /// Es lo que permite que un doctor agende una cita normal sin poder
  /// agendársela a otro: la base ya se lo imponía desde HFX-CLIN-001
  /// (`citas_insert` exige `doctor_id = auth.uid()` para el doctor), pero la
  /// pantalla lo degradaba a urgencia en vez de dejarle usar su propia agenda
  /// (defecto D10 de la jornada de QA del 1 ago 2026).
  final bool doctorFijo;

  const NuevaCitaDialog._({
    required this.personaRepository,
    required this.doctorRepository,
    required this.pacienteRepository,
    required this.citaRepository,
    this.fechaInicial,
    this.emergencia = false,
    this.doctorPredeterminadoId,
    this.doctorFijo = false,
  });

  /// Devuelve el id de la cita de urgencia creada cuando [emergencia] es cierto,
  /// para poder entrar directamente a su consulta. `null` en los demás casos.
  static Future<String?> show(
    BuildContext context, {
    required PersonaRepository personaRepository,
    required DoctorRepository doctorRepository,
    required IPacienteRepository pacienteRepository,
    required CitaRepository citaRepository,
    DateTime? fechaInicial,
    bool emergencia = false,
    String? doctorPredeterminadoId,
    bool doctorFijo = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CitaCubit>(),
        child: NuevaCitaDialog._(
          personaRepository: personaRepository,
          doctorRepository: doctorRepository,
          pacienteRepository: pacienteRepository,
          citaRepository: citaRepository,
          fechaInicial: fechaInicial,
          emergencia: emergencia,
          doctorPredeterminadoId: doctorPredeterminadoId,
          doctorFijo: doctorFijo,
        ),
      ),
    );
  }

  @override
  State<NuevaCitaDialog> createState() => _NuevaCitaDialogState();
}

class _NuevaCitaDialogState extends State<NuevaCitaDialog>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.buscarPersona;
  _Paso1Mode _paso1Mode = _Paso1Mode.idle;

  // ── Paso 1 – Búsqueda ───────────────────────────────────────────────────
  final _searchController = TextEditingController();
  List<Persona> _resultados = [];
  bool _buscando = false;
  Persona? _personaSeleccionada;

  // ── Paso 1 – Nueva Persona / Paciente Completo ──────────────────────────
  final _formKeyPersona = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _trabajoCtrl = TextEditingController();

  DateTime? _fechaNacimiento;
  Genero _genero = Genero.masculino;
  TipoPaciente _tipoPaciente = TipoPaciente.integrado;

  /// Foto ya recortada y comprimida. Se guarda en memoria hasta que el
  /// paciente exista en la base: Storage necesita su id para la ruta.
  Uint8List? _fotoPendiente;
  bool _procesandoFoto = false;

  bool get _esNuevaPersona => _paso1Mode == _Paso1Mode.nuevaPersona;

  // ── Paso 2 – Cita ────────────────────────────────────────────────────────
  final _formKeyCita = GlobalKey<FormState>();
  List<Doctor> _doctores = [];
  bool _cargandoDoctores = false;
  Doctor? _doctorSeleccionado;
  DateTime? _fecha;
  TimeOfDay? _hora;
  final _motivoCtrl = TextEditingController();
  bool _esEmergencia = false;
  bool _guardando = false;

  /// Actividades del plan que esta cita va a atender (SD-146). Solo se pueden
  /// elegir cuando el paciente ya existe: un registro nuevo no tiene plan.
  List<ActividadPlanificada> _actividades = const [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    if (widget.fechaInicial case final inicial?) {
      _fecha = DateTime(inicial.year, inicial.month, inicial.day);
      _hora = TimeOfDay(hour: inicial.hour, minute: inicial.minute);
    }
    _esEmergencia = widget.emergencia;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchController.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _trabajoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    try {
      final r = await widget.personaRepository.searchPersonas(q.trim());
      setState(() => _resultados = r);
    } catch (_) {
      setState(() => _resultados = []);
    } finally {
      setState(() => _buscando = false);
    }
  }

  void _seleccionarPersona(Persona p) {
    setState(() {
      _personaSeleccionada = p;
      _paso1Mode = _Paso1Mode.idle;
    });
    _irAFormulario();
  }

  void _mostrarFormNuevaPersona() {
    setState(() {
      _paso1Mode = _Paso1Mode.nuevaPersona;
      _personaSeleccionada = null;
    });
  }

  void _ocultarFormNuevaPersona() {
    setState(() => _paso1Mode = _Paso1Mode.idle);
  }

  void _irAFormulario() {
    _fadeCtrl.forward(from: 0);
    setState(() => _step = _Step.formularioCita);
    _cargarDoctores();
  }

  void _volverAPaso1() {
    _fadeCtrl.forward(from: 0);
    setState(() {
      _step = _Step.buscarPersona;
      _doctorSeleccionado = null;
      _fecha = null;
      _hora = null;
      // Las actividades son del paciente que se estaba agendando: volver atrás
      // puede cambiarlo, y arrastrarlas vincularía el plan de otra persona.
      _actividades = const [];
    });
  }

  void _confirmarNuevaPersonaYAvanzar() {
    if (!(_formKeyPersona.currentState?.validate() ?? false)) return;
    if (_fechaNacimiento == null) {
      _showError('Selecciona la fecha de nacimiento del paciente.');
      return;
    }
    _irAFormulario();
  }

  Future<void> _cargarDoctores() async {
    setState(() => _cargandoDoctores = true);
    try {
      final lista = await widget.doctorRepository.getDoctores();
      setState(() {
        _doctores = lista;
        _doctorSeleccionado ??= lista
            .where((d) => d.id == widget.doctorPredeterminadoId)
            .firstOrNull;
      });
    } catch (_) {
    } finally {
      setState(() => _cargandoDoctores = false);
    }
  }

  Future<void> _confirmar() async {
    if (!(_formKeyCita.currentState?.validate() ?? false)) return;
    // La urgencia es ahora: no se elige fecha ni hora, y por eso tampoco se
    // comprueban. Pedirle a alguien que ya está sangrando que reserve un hueco
    // futuro era exactamente el rodeo que obligaba a tocar la base a mano.
    if (!widget.emergencia && (_fecha == null || _hora == null)) {
      _showError('Selecciona fecha y hora para la cita.');
      return;
    }

    final fechaHora = widget.emergencia
        ? DateTime.now()
        : DateTime(
            _fecha!.year,
            _fecha!.month,
            _fecha!.day,
            _hora!.hour,
            _hora!.minute,
          );

    if (!widget.emergencia && fechaHora.isBefore(DateTime.now())) {
      _showError('No puedes agendar una cita en una fecha/hora pasada.');
      return;
    }

    if (_doctorSeleccionado == null) {
      _showError('Selecciona un odontólogo.');
      return;
    }

    Persona? persona = _personaSeleccionada;

    if (_esNuevaPersona) {
      setState(() => _guardando = true);
      final resultado = await widget.pacienteRepository.addPaciente(
        _buildNuevoPaciente(),
      );
      if (!mounted) return;

      final creado = resultado.fold((failure) {
        setState(() => _guardando = false);
        _showError('Error al registrar paciente: ${failure.message}');
        return null;
      }, (id) => id);
      if (creado == null) return;

      persona = _buildNuevaPersona(id: creado);
      // La foto es opcional: si falla se avisa, pero la cita igual se agenda
      // porque el paciente ya quedó registrado.
      await _subirFotoPendiente(creado);
      if (!mounted) return;
    }

    if (persona == null) {
      _showError('No se pudo procesar la información del paciente.');
      setState(() => _guardando = false);
      return;
    }

    final motivo = _motivoCtrl.text.trim();

    if (widget.emergencia) {
      setState(() => _guardando = true);
      final citaId = await context.read<CitaCubit>().registrarEmergencia(
        pacienteId: persona.id!,
        doctorId: _doctorSeleccionado!.id!,
        motivo: motivo.isEmpty ? null : motivo,
      );
      if (!mounted) return;
      if (citaId == null) {
        setState(() => _guardando = false);
        _showError(
          'No se pudo registrar la urgencia. Revisa la conexión e inténtalo de '
          'nuevo: el paciente no quedó agendado.',
        );
        return;
      }
      Navigator.of(context).pop(citaId);
      return;
    }

    final cita = Cita(
      doctor: _doctorSeleccionado!,
      persona: persona,
      date: fechaHora.toUtc(),
      esEmergencia: _esEmergencia,
      estado: EstadoCita.programada,
      motivo: motivo.isEmpty ? null : motivo,
      actividades: _actividades,
    );

    if (!mounted) return;
    setState(() => _guardando = true);
    try {
      await context.read<CitaCubit>().createCita(cita);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _showError('Error al agendar la cita: $e');
    }
  }

  Persona _buildNuevaPersona({String? id}) {
    return Persona(
      id: id,
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      birthDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      govID: _cedulaCtrl.text.trim(),
      contactos: _buildContactos(),
      estatus: EstatusPersona.activo,
    );
  }

  Paciente _buildNuevoPaciente() {
    return Paciente(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      birthDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      govID: _cedulaCtrl.text.trim(),
      contactos: _buildContactos(),
      estatus: EstatusPersona.activo,
      genero: _genero,
      tipoPaciente: _tipoPaciente,
      trabajo: _trabajoCtrl.text.trim(),
      referencia: '',
      record: RecordModel.empty(),
      citas: const [],
    );
  }

  /// Sube la foto elegida en el paso 1, ya recortada y comprimida.
  Future<void> _subirFotoPendiente(String pacienteId) async {
    if (_fotoPendiente == null) return;
    try {
      await sl<PacienteFotoStorage>().guardar(
        pacienteId: pacienteId,
        bytes: _fotoPendiente!,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(
        'El paciente se registró, pero no se pudo guardar la fotografía: '
        '$error',
      );
    }
  }

  List<Contacto> _buildContactos() {
    return [
      ContactoModel(
        id: null,
        email: _emailCtrl.text.trim(),
        numeroTelefono: _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
      ),
    ];
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.appColors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// La cámara solo existe en móvil y en navegador; en escritorio el plugin
  /// resuelve la galería con un selector de archivos.
  bool get _soportaCamara =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _elegirFoto() async {
    ImageSource? source = ImageSource.gallery;
    if (_soportaCamara) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar fotografía'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null || !mounted) return;

    setState(() => _procesandoFoto = true);
    try {
      final storage = sl<PacienteFotoStorage>();
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (selected == null) return;
      final decodificada = storage.decodificar(await selected.readAsBytes());
      if (!mounted) return;
      final optimizada = await RecorteFotoDialog.mostrar(
        context,
        imagen: decodificada,
        storage: storage,
      );
      if (optimizada == null || !mounted) return;
      setState(() => _fotoPendiente = optimizada);
    } on FormatoFotoInvalido catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('No se pudo preparar la fotografía: $error');
    } finally {
      if (mounted) setState(() => _procesandoFoto = false);
    }
  }

  Future<void> _pickFechaNacimiento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de Nacimiento',
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocListener<CitaCubit, CitaCubitState>(
      listener: (ctx, state) {
        if (state is CitaCubitLoaded &&
            _guardando &&
            !state.isSubmitting &&
            state.errorMessage == null) {
          setState(() => _guardando = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Cita agendada correctamente.'),
                ],
              ),
              backgroundColor: ac.teal,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is CitaCubitLoaded &&
            _guardando &&
            state.errorMessage != null) {
          setState(() => _guardando = false);
          _showError(state.errorMessage!);
        } else if (state is CitaCubitError && _guardando) {
          setState(() => _guardando = false);
          _showError(state.message);
        }
      },
      child: Dialog(
        backgroundColor: ac.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 740),
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildStepIndicator(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: _step == _Step.buscarPersona
                        ? _buildPaso1(context)
                        : _buildPaso2(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final ac = context.appColors;

    final titulo = _step == _Step.buscarPersona
        ? 'Agendar Nueva Cita'
        : 'Detalles de la Cita';

    final subtitulo = _step == _Step.buscarPersona
        ? 'Busca un paciente o completa sus datos de ingreso'
        : _esNuevaPersona
        ? 'Paciente nuevo: ${_nombreCtrl.text} ${_apellidoCtrl.text}'
        : '${_personaSeleccionada!.nombre} ${_personaSeleccionada!.apellido}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: ac.bgPage,
        border: Border(bottom: BorderSide(color: ac.divider, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ac.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 22,
              color: ac.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 12, color: ac.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_step == _Step.formularioCita)
            _HeaderIconButton(
              tooltip: 'Volver',
              icon: Icons.arrow_back_rounded,
              onPressed: _guardando ? null : _volverAPaso1,
            ),
          _HeaderIconButton(
            tooltip: 'Cerrar',
            icon: Icons.close_rounded,
            onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final ac = context.appColors;
    final isStep2 = _step == _Step.formularioCita;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          _StepDot(number: 1, active: true, completed: isStep2, ac: ac),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isStep2 ? ac.primaryGreen : ac.divider,
              ),
            ),
          ),
          _StepDot(number: 2, active: isStep2, completed: false, ac: ac),
        ],
      ),
    );
  }

  // ── Paso 1: Búsqueda y Registro Completo de Paciente ─────────────────────

  Widget _buildPaso1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildBuscador(context),
        const SizedBox(height: 10),
        _buildResultados(context),
        const SizedBox(height: 8),
        _buildDividerONuevo(context),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          child: _esNuevaPersona
              ? _buildFormNuevaPersona(context)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBuscador(BuildContext context) {
    final ac = context.appColors;
    return TextFormField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Buscar paciente existente',
        hintText: 'Nombre, apellido o cédula...',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: ac.primaryGreen,
        ),
        suffixIcon: _buscando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _resultados = []);
                },
              )
            : null,
        filled: true,
        fillColor: ac.bgPage,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: _buscar,
    );
  }

  Widget _buildResultados(BuildContext context) {
    final ac = context.appColors;
    if (_resultados.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_resultados.length} paciente(s) encontrado(s)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ac.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _resultados.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final p = _resultados[i];
            return _PersonaTile(
              persona: p,
              onTap: () => _seleccionarPersona(p),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDividerONuevo(BuildContext context) {
    final ac = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: ac.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ó',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ac.textMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: ac.divider)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _esNuevaPersona
              ? OutlinedButton.icon(
                  onPressed: _ocultarFormNuevaPersona,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar registro nuevo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: _mostrarFormNuevaPersona,
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Registrar Nuevo Paciente'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFotoPerfil(BuildContext context) {
    final ac = context.appColors;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ac.primaryGreen.withValues(alpha: 0.10),
            border: Border.all(color: ac.divider),
            image: _fotoPendiente != null
                ? DecorationImage(
                    image: MemoryImage(_fotoPendiente!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _fotoPendiente != null
              ? null
              : Icon(
                  Icons.person_outline_rounded,
                  size: 26,
                  color: ac.primaryGreen,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fotografía de identificación',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ac.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Opcional. Se guarda al confirmar la cita.',
                style: TextStyle(fontSize: 11, color: ac.textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (_procesandoFoto)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _procesandoFoto ? null : _elegirFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 15),
                    label: Text(
                      _fotoPendiente != null ? 'Cambiar foto' : 'Agregar foto',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ac.primaryGreen,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_fotoPendiente != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _procesandoFoto
                          ? null
                          : () => setState(() => _fotoPendiente = null),
                      style: TextButton.styleFrom(
                        foregroundColor: ac.red,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Quitar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormNuevaPersona(BuildContext context) {
    final ac = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ac.bgPage,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ac.divider),
        ),
        child: Form(
          key: _formKeyPersona,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 16, color: ac.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'DATOS DE REGISTRO DEL PACIENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: ac.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildFotoPerfil(context),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _nombreCtrl,
                      label: 'Nombre *',
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatorio'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      controller: _apellidoCtrl,
                      label: 'Apellido *',
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatorio'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _cedulaCtrl,
                      label: 'Cédula *',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_CedulaInputFormatter()],
                      hint: '000-0000000-0',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (v.replaceAll('-', '').length != 11)
                          return 'Inválida';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickFechaNacimiento,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ac.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ac.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: ac.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _fechaNacimiento != null
                                    ? _formatDate(_fechaNacimiento!)
                                    : 'F. Nacimiento *',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _fechaNacimiento != null
                                      ? ac.textPrimary
                                      : ac.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _telefonoCtrl,
                      label: 'Teléfono *',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: '809-000-0000',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatorio'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      controller: _emailCtrl,
                      label: 'Correo',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'ejemplo@correo.com',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _FormField(
                controller: _direccionCtrl,
                label: 'Dirección',
                prefixIcon: Icons.location_on_outlined,
                hint: 'Ciudad, calle, número...',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GÉNERO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ac.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: Genero.values
                              .where((g) => g != Genero.noPrefiereDecir)
                              .map((g) {
                                final sel = _genero == g;
                                return ChoiceChip(
                                  label: Text(
                                    g.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? ac.primaryGreen
                                          : ac.textSecondary,
                                    ),
                                  ),
                                  selected: sel,
                                  onSelected: (_) =>
                                      setState(() => _genero = g),
                                  selectedColor: ac.primaryGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  backgroundColor: ac.cardBg,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIPO PACIENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ac.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: TipoPaciente.values.map((t) {
                            final sel = _tipoPaciente == t;
                            final color = t == TipoPaciente.emergencia
                                ? ac.red
                                : ac.teal;
                            return ChoiceChip(
                              label: Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sel ? color : ac.textSecondary,
                                ),
                              ),
                              selected: sel,
                              onSelected: (_) =>
                                  setState(() => _tipoPaciente = t),
                              selectedColor: color.withValues(alpha: 0.12),
                              backgroundColor: ac.cardBg,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirmarNuevaPersonaYAvanzar,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Continuar a Agendar Cita'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Paso 2: Datos de Cita y Confirmación ─────────────────────────────────

  Widget _buildPaso2(BuildContext context) {
    final ac = context.appColors;

    return Form(
      key: _formKeyCita,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildPacienteResumen(context),
          const SizedBox(height: 16),

          _SectionLabel(
            icon: Icons.person_search_outlined,
            label: 'Odontólogo Asignado',
          ),
          const SizedBox(height: 8),
          _cargandoDoctores
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.doctorFijo && _doctorSeleccionado != null
              // Sin desplegable: no hay nada que elegir, y un desplegable de un
              // solo elemento invita a buscar el que falta.
              ? InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: ac.primaryGreen,
                    ),
                    filled: true,
                    fillColor: ac.bgPage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Dr. ${_doctorSeleccionado!.nombre} '
                    '${_doctorSeleccionado!.apellido}',
                  ),
                )
              : DropdownButtonFormField<Doctor>(
                  initialValue: _doctorSeleccionado,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar odontólogo',
                    prefixIcon: Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: ac.primaryGreen,
                    ),
                    filled: true,
                    fillColor: ac.bgPage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _doctores
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text('Dr. ${d.nombre} ${d.apellido}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _doctorSeleccionado = v),
                  validator: (v) =>
                      v == null ? 'Selecciona un odontólogo' : null,
                ),
          const SizedBox(height: 16),

          if (!widget.emergencia) ...[
            _SectionLabel(icon: Icons.schedule_outlined, label: 'Fecha y Hora'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today_outlined,
                    label: _fecha == null
                        ? 'Seleccionar fecha'
                        : _formatDate(_fecha!),
                    hasValue: _fecha != null,
                    onTap: _pickFecha,
                    error: _guardando && _fecha == null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.access_time_outlined,
                    label: _hora == null
                        ? 'Seleccionar hora'
                        : _hora!.format(context),
                    hasValue: _hora != null,
                    onTap: _pickHora,
                    error: _guardando && _hora == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _SectionLabel(
            icon: Icons.notes_outlined,
            label: 'Motivo de Consulta',
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivoCtrl,
            maxLines: 2,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ej. Evaluación por dolor en molar superior...',
              filled: true,
              fillColor: ac.bgPage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!widget.emergencia) ...[
            _SectionLabel(
              icon: Icons.checklist_rounded,
              label: 'Actividades del plan de tratamiento',
            ),
            const SizedBox(height: 8),
            SelectorActividadesPlan(
              pacienteId: _esNuevaPersona ? null : _personaSeleccionada?.id,
              repository: widget.citaRepository,
              seleccionadas: _actividades,
              habilitado: !_guardando,
              onChanged: (lista) => setState(() => _actividades = lista),
            ),
            const SizedBox(height: 10),
          ],

          if (widget.emergencia)
            _AvisoUrgencia()
          else
            Material(
            color: _esEmergencia ? ac.red.withValues(alpha: 0.08) : ac.bgPage,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _esEmergencia ? ac.red : ac.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: Text(
                'Cita de emergencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _esEmergencia ? ac.red : ac.textPrimary,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                'Prioridad alta en la agenda de la clínica',
                style: TextStyle(fontSize: 11, color: ac.textMuted),
              ),
              value: _esEmergencia,
              onChanged: (v) => setState(() => _esEmergencia = v),
              activeColor: ac.red,
              dense: true,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _confirmar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : widget.emergencia
                        ? 'Registrar urgencia'
                        : 'Confirmar Cita',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.emergencia
                        ? ac.red
                        : ac.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteResumen(BuildContext context) {
    final ac = context.appColors;

    final nombre = _esNuevaPersona
        ? '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}'.trim()
        : '${_personaSeleccionada!.nombre} ${_personaSeleccionada!.apellido}';

    final cedula = _esNuevaPersona
        ? _cedulaCtrl.text.trim()
        : _personaSeleccionada?.govID ?? '';
    final telefono = _esNuevaPersona ? _telefonoCtrl.text.trim() : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ac.primaryGreen.withValues(alpha: 0.15),
            foregroundImage: _fotoPendiente != null
                ? MemoryImage(_fotoPendiente!)
                : null,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'P',
              style: TextStyle(
                color: ac.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? 'Paciente Seleccionado' : nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                  ),
                ),
                if (cedula.isNotEmpty)
                  Text(
                    'Cédula: $cedula',
                    style: TextStyle(fontSize: 11.5, color: ac.textSecondary),
                  ),
                if (telefono != null && telefono.isNotEmpty)
                  Text(
                    'Tel: $telefono',
                    style: TextStyle(fontSize: 11.5, color: ac.textSecondary),
                  ),
              ],
            ),
          ),
          if (_esNuevaPersona)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ac.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NUEVO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ac.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _hora = picked);
  }
}

// ── Componentes Auxiliares Visuales ────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool active;
  final bool completed;
  final AppColors ac;

  const _StepDot({
    required this.number,
    required this.active,
    required this.completed,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active || completed ? ac.primaryGreen : ac.divider;
    final fg = active || completed ? Colors.white : ac.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : Text(
                number.toString(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 17, color: ac.primaryGreen)
            : null,
        filled: true,
        fillColor: ac.cardBg,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator,
    );
  }
}

class _PersonaTile extends StatelessWidget {
  final Persona persona;
  final VoidCallback onTap;

  const _PersonaTile({required this.persona, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final iniciales =
        '${persona.nombre.isNotEmpty ? persona.nombre[0] : ''}${persona.apellido.isNotEmpty ? persona.apellido[0] : ''}'
            .toUpperCase();

    // El color de fondo lo pone el Material y no el Container: pintarlo por
    // encima tapa el destello del toque —Flutter lo afirma en depuración— y
    // deja la fila sin decir que se pulsó.
    return Material(
      color: ac.cardBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: ac.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: ac.primaryGreen.withValues(alpha: 0.1),
          child: Text(
            iniciales,
            style: TextStyle(
              color: ac.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${persona.nombre} ${persona.apellido}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: persona.govID.isNotEmpty
            ? Text(
                'Cédula: ${persona.govID}',
                style: TextStyle(fontSize: 11, color: ac.textMuted),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: ac.textMuted,
          size: 18,
        ),
      ),
    );
  }
}

/// Dice en el propio formulario qué va a pasar al confirmar una urgencia: se
/// crea ahora, marcada, y con el paciente ya dado por presente.
class _AvisoUrgencia extends StatelessWidget {
  const _AvisoUrgencia();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, size: 18, color: ac.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención de urgencia',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ac.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Se registra con la hora actual, queda marcada como emergencia '
                  'y el paciente entra en espera: no ocupa un hueco de la agenda.',
                  style: TextStyle(fontSize: 11, color: ac.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 15, color: ac.primaryGreen),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ac.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final bool error;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = error ? ac.red : (hasValue ? ac.primaryGreen : ac.textMuted);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        side: BorderSide(color: error ? ac.red : ac.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
