import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

class NuevaCitaDialog extends StatefulWidget {
  final PersonaRepository personaRepository;
  final DoctorRepository doctorRepository;

  const NuevaCitaDialog._({
    required this.personaRepository,
    required this.doctorRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required PersonaRepository personaRepository,
    required DoctorRepository doctorRepository,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CitaCubit>(),
        child: NuevaCitaDialog._(
          personaRepository: personaRepository,
          doctorRepository: doctorRepository,
        ),
      ),
    );
  }

  @override
  State<NuevaCitaDialog> createState() => _NuevaCitaDialogState();
}

enum _Step { buscarPersona, formularioCita }

/// Sub-estado del paso 1: ninguna acción / expandido formulario nueva persona
enum _Paso1Mode { idle, nuevaPersona }

class _NuevaCitaDialogState extends State<NuevaCitaDialog>
    with SingleTickerProviderStateMixin {
  // ── Paso actual ──────────────────────────────────────────────────────────
  _Step _step = _Step.buscarPersona;
  _Paso1Mode _paso1Mode = _Paso1Mode.idle;

  // ── Paso 1 – búsqueda ────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  List<Persona> _resultados = [];
  bool _buscando = false;
  Persona? _personaSeleccionada;

  // ── Paso 1 – nueva persona ───────────────────────────────────────────────
  final _formKeyPersona = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool get _esNuevaPersona => _paso1Mode == _Paso1Mode.nuevaPersona;

  // ── Paso 2 – cita ────────────────────────────────────────────────────────
  final _formKeyCita = GlobalKey<FormState>();
  List<Doctor> _doctores = [];
  bool _cargandoDoctores = false;
  Doctor? _doctorSeleccionado;
  DateTime? _fecha;
  TimeOfDay? _hora;
  final _motivoCtrl = TextEditingController();
  bool _esEmergencia = false;
  bool _guardando = false;

  // ── Animación ────────────────────────────────────────────────────────────
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchController.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de búsqueda ───────────────────────────────────────────────────

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

  // ── FIX: mostrar el formulario inline, NO avanzar de paso ────────────────
  void _mostrarFormNuevaPersona() {
    setState(() {
      _paso1Mode = _Paso1Mode.nuevaPersona;
      _personaSeleccionada = null;
    });
  }

  void _ocultarFormNuevaPersona() {
    setState(() => _paso1Mode = _Paso1Mode.idle);
  }

  // ── Avanzar al paso 2 ────────────────────────────────────────────────────
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
    });
  }

  // ── Avanzar desde nueva persona ──────────────────────────────────────────
  void _confirmarNuevaPersonaYAvanzar() {
    if (!(_formKeyPersona.currentState?.validate() ?? false)) return;
    _irAFormulario();
  }

  // ── Doctores ─────────────────────────────────────────────────────────────
  Future<void> _cargarDoctores() async {
    setState(() => _cargandoDoctores = true);
    try {
      final lista = await widget.doctorRepository.getDoctores();
      setState(() => _doctores = lista);
    } catch (_) {
    } finally {
      setState(() => _cargandoDoctores = false);
    }
  }

  // ── Guardar cita ─────────────────────────────────────────────────────────
  Future<void> _confirmar() async {
    if (!(_formKeyCita.currentState?.validate() ?? false)) return;
    if (_fecha == null || _hora == null) {
      _showError('Selecciona fecha y hora.');
      return;
    }

    final fechaHora = DateTime(
      _fecha!.year,
      _fecha!.month,
      _fecha!.day,
      _hora!.hour,
      _hora!.minute,
    );

    if (fechaHora.isBefore(DateTime.now())) {
      _showError('No puedes agendar una cita en el pasado.');
      return;
    }

    if (_doctorSeleccionado == null) {
      _showError('Selecciona un odontólogo.');
      return;
    }

    Persona? persona = _personaSeleccionada;

    if (_esNuevaPersona) {
      setState(() => _guardando = true);
      try {
        final nueva = _buildNuevaPersona();
        persona = await widget.personaRepository.createPersona(nueva);
      } catch (e) {
        setState(() => _guardando = false);
        _showError('Error al registrar persona: $e');
        return;
      }
    }

    if (persona == null) {
      _showError('No se pudo determinar la persona.');
      setState(() => _guardando = false);
      return;
    }

    final cita = Cita(
      doctor: _doctorSeleccionado!,
      persona: persona,
      date: fechaHora.toUtc(),
      esEmergencia: _esEmergencia,
      estado: EstadoCita.programada,
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

  Persona _buildNuevaPersona() {
    return Persona(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      birthDate: DateTime(2000),
      govID: _cedulaCtrl.text.trim(),
      contactos: _buildContactos(),
      estatus: EstatusPersona.activo,
    );
  }

  List<Contacto> _buildContactos() {
    return [
      ContactoModel(
        id: null,
        email: '',
        numeroTelefono: _telefonoCtrl.text.trim(),
        direccion: '',
      ),
    ];
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<CitaCubit, CitaCubitState>(
      listener: (ctx, state) {
        if (state is CitaCubitLoaded) {
          setState(() => _guardando = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Cita agendada correctamente.'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is CitaCubitError) {
          setState(() => _guardando = false);
          _showError(state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildStepIndicator(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
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
    final cs = Theme.of(context).colorScheme;

    final titulo = _step == _Step.buscarPersona
        ? 'Nueva Cita'
        : 'Detalles de la Cita';

    final subtitulo = _step == _Step.buscarPersona
        ? 'Busca un paciente existente o regístralo'
        : _esNuevaPersona
        ? 'Nuevo paciente — completa los datos'
        : '${_personaSeleccionada!.nombre} ${_personaSeleccionada!.apellido}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.35),
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitulo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_step == _Step.formularioCita)
            _HeaderIconButton(
              tooltip: 'Volver al paso anterior',
              icon: Icons.arrow_back_ios_new_rounded,
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

  // ── Step indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isStep2 = _step == _Step.formularioCita;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 2),
      child: Row(
        children: [
          _StepDot(number: 1, active: true, completed: isStep2, cs: cs),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isStep2 ? cs.primary : cs.outlineVariant,
              ),
            ),
          ),
          _StepDot(number: 2, active: isStep2, completed: false, cs: cs),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 1 — Buscar / Registrar Paciente
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPaso1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildBuscador(context),
        const SizedBox(height: 12),
        _buildResultados(context),
        const SizedBox(height: 8),
        _buildDividerONuevo(context),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: _esNuevaPersona
              ? _buildFormNuevaPersona(context)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBuscador(BuildContext context) {
    return TextFormField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Buscar paciente',
        hintText: 'Nombre, apellido o cédula...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
      ),
      onChanged: _buscar,
    );
  }

  Widget _buildResultados(BuildContext context) {
    if (_resultados.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            '${_resultados.length} resultado${_resultados.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDividerONuevo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: cs.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: cs.outlineVariant)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _esNuevaPersona
              ? OutlinedButton.icon(
                  onPressed: _ocultarFormNuevaPersona,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar registro'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : FilledButton.tonalIcon(
                  onPressed: _mostrarFormNuevaPersona,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Registrar nuevo paciente'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFormNuevaPersona(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Form(
          key: _formKeyPersona,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del formulario
              Row(
                children: [
                  Icon(Icons.person_outlined, size: 15, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Datos del nuevo paciente',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre + Apellido
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _nombreCtrl,
                      label: 'Nombre',
                      required: true,
                      capitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      controller: _apellidoCtrl,
                      label: 'Apellido',
                      required: true,
                      capitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cédula
              _FormField(
                controller: _cedulaCtrl,
                label: 'Cédula',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Ej. 00100000000',
              ),
              const SizedBox(height: 12),

              // Teléfono
              _FormField(
                controller: _telefonoCtrl,
                label: 'Teléfono',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: 'Ej. 8091234567',
              ),
              const SizedBox(height: 18),

              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirmarNuevaPersonaYAvanzar,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Continuar con este paciente'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
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

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 2 — Formulario de la Cita
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPaso2(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKeyCita,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── Paciente (resumen) ──────────────────────────────────────────
          _buildPacienteResumen(context),
          const SizedBox(height: 20),

          // ── Odontólogo ──────────────────────────────────────────────────
          _SectionLabel(icon: Icons.health_and_safety, label: 'Odontólogo'),
          const SizedBox(height: 8),
          _cargandoDoctores
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : DropdownButtonFormField<Doctor>(
                  initialValue: _doctorSeleccionado,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar odontólogo',
                    prefixIcon: const Icon(
                      Icons.person_search_outlined,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
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
          const SizedBox(height: 20),

          // ── Fecha y Hora ────────────────────────────────────────────────
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
          const SizedBox(height: 20),

          // ── Motivo ──────────────────────────────────────────────────────
          _SectionLabel(
            icon: Icons.notes_outlined,
            label: 'Motivo de consulta',
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivoCtrl,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Describe brevemente el motivo de la visita...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // ── Emergencia ──────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _esEmergencia
                  ? Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _esEmergencia
                    ? cs.error.withOpacity(0.5)
                    : cs.outlineVariant,
              ),
            ),
            child: SwitchListTile(
              title: Text(
                'Cita de emergencia',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _esEmergencia ? cs.error : null,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Se marcará con prioridad alta en la agenda.',
                style: TextStyle(fontSize: 12),
              ),
              value: _esEmergencia,
              onChanged: (v) => setState(() => _esEmergencia = v),
              activeThumbColor: cs.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              dense: true,
            ),
          ),
          const SizedBox(height: 28),

          // ── Botones de acción ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  label: const Text('Confirmar Cita'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    final cs = Theme.of(context).colorScheme;

    final nombre = _esNuevaPersona
        ? '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}'.trim()
        : '${_personaSeleccionada!.nombre} ${_personaSeleccionada!.apellido}';

    final cedula = _esNuevaPersona
        ? _cedulaCtrl.text.trim()
        : _personaSeleccionada?.govID ?? '';

    final telefono = _esNuevaPersona ? _telefonoCtrl.text.trim() : null;

    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Text(
              iniciales,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? 'Paciente nuevo' : nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (cedula.isNotEmpty)
                  Text(
                    'Cédula: $cedula',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (telefono != null && telefono.isNotEmpty)
                  Text(
                    'Tel: $telefono',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (_esNuevaPersona)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Nuevo',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

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
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool active;
  final bool completed;
  final ColorScheme cs;

  const _StepDot({
    required this.number,
    required this.active,
    required this.completed,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active || completed ? cs.primary : cs.outlineVariant;
    final fg = active || completed ? cs.onPrimary : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: completed
            ? Icon(Icons.check_rounded, size: 14, color: fg)
            : Text(
                number.toString(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

/// Campo de texto genérico con estilo consistente.
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        filled: true,
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
    final cs = Theme.of(context).colorScheme;
    final iniciales =
        '${persona.nombre.isNotEmpty ? persona.nombre[0] : ''}${persona.apellido.isNotEmpty ? persona.apellido[0] : ''}'
            .toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  iniciales,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${persona.nombre} ${persona.apellido}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (persona.govID.isNotEmpty)
                      Text(
                        'Cédula: ${persona.govID}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
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
    final cs = Theme.of(context).colorScheme;

    final borderColor = error
        ? cs.error
        : hasValue
        ? cs.primary
        : cs.outlineVariant;

    final iconColor = error
        ? cs.error
        : hasValue
        ? cs.primary
        : cs.onSurfaceVariant;

    final textColor = error
        ? cs.error
        : hasValue
        ? cs.primary
        : cs.onSurfaceVariant;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: iconColor),
      label: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
