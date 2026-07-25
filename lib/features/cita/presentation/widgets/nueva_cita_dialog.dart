import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
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
      setState(() => _doctores = lista);
    } catch (_) {
    } finally {
      setState(() => _cargandoDoctores = false);
    }
  }

  Future<void> _confirmar() async {
    if (!(_formKeyCita.currentState?.validate() ?? false)) return;
    if (_fecha == null || _hora == null) {
      _showError('Selecciona fecha y hora para la cita.');
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
      try {
        final nueva = _buildNuevaPersona();
        persona = await widget.personaRepository.createPersona(nueva);
      } catch (e) {
        setState(() => _guardando = false);
        _showError('Error al registrar paciente: $e');
        return;
      }
    }

    if (persona == null) {
      _showError('No se pudo procesar la información del paciente.');
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
      birthDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      govID: _cedulaCtrl.text.trim(),
      contactos: _buildContactos(),
      estatus: EstatusPersona.activo,
    );
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
              color: ac.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 22,
              color: ac.primaryBlue,
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
                color: isStep2 ? ac.primaryBlue : ac.divider,
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
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: ac.primaryBlue),
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
                    backgroundColor: ac.primaryBlue,
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
                  Icon(Icons.badge_outlined, size: 16, color: ac.primaryBlue),
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
                              color: ac.primaryBlue,
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
                                          ? ac.primaryBlue
                                          : ac.textSecondary,
                                    ),
                                  ),
                                  selected: sel,
                                  onSelected: (_) =>
                                      setState(() => _genero = g),
                                  selectedColor: ac.primaryBlue.withValues(
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
              : DropdownButtonFormField<Doctor>(
                  initialValue: _doctorSeleccionado,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar odontólogo',
                    prefixIcon: Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: ac.primaryBlue,
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
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: _esEmergencia ? ac.red.withValues(alpha: 0.08) : ac.bgPage,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _esEmergencia ? ac.red : ac.divider),
            ),
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
                  label: Text(_guardando ? 'Guardando...' : 'Confirmar Cita'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.primaryBlue,
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
        color: ac.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ac.primaryBlue.withValues(alpha: 0.15),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'P',
              style: TextStyle(
                color: ac.primaryBlue,
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
    final bg = active || completed ? ac.primaryBlue : ac.divider;
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
            ? Icon(prefixIcon, size: 17, color: ac.primaryBlue)
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

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        border: Border.all(color: ac.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: ac.primaryBlue.withValues(alpha: 0.1),
          child: Text(
            iniciales,
            style: TextStyle(
              color: ac.primaryBlue,
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 15, color: ac.primaryBlue),
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
    final color = error ? ac.red : (hasValue ? ac.primaryBlue : ac.textMuted);

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
