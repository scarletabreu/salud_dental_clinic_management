import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/bloc/cita_bloc.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Punto de entrada:
//
//   await NuevaCitaDialog.show(
//     context,
//     personaRepository: ...,
//     doctorRepository: ...,
//   );
// ─────────────────────────────────────────────────────────────────────────────

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
        value: context.read<CitaBloc>(),
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

class _NuevaCitaDialogState extends State<NuevaCitaDialog> {
  _Step _step = _Step.buscarPersona;

  // ── Búsqueda de persona ───────────────────────────────────────────────────
  final _searchController = TextEditingController();
  List<Persona> _resultados = [];
  bool _buscando = false;
  Persona? _personaSeleccionada;

  // ── Nueva persona ─────────────────────────────────────────────────────────
  final _formKeyPersona = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _esNuevaPersona = false;

  // ── Formulario de cita ────────────────────────────────────────────────────
  final _formKeyCita = GlobalKey<FormState>();
  List<Doctor> _doctores = [];
  bool _cargandoDoctores = false;
  Doctor? _doctorSeleccionado;
  DateTime? _fecha;
  TimeOfDay? _hora;
  final _motivoCtrl = TextEditingController();
  bool _esEmergencia = false;
  bool _guardando = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  // ─── Búsqueda ─────────────────────────────────────────────────────────────
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
      _esNuevaPersona = false;
    });
    _irAFormulario();
  }

  void _usarNuevaPersona() {
    setState(() {
      _personaSeleccionada = null;
      _esNuevaPersona = true;
    });
    _irAFormulario();
  }

  void _irAFormulario() {
    setState(() => _step = _Step.formularioCita);
    _cargarDoctores();
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

  // ─── Confirmación ─────────────────────────────────────────────────────────
  Future<void> _confirmar() async {
    if (_esNuevaPersona && !(_formKeyPersona.currentState?.validate() ?? false)) return;
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
        await widget.personaRepository.createPersona(nueva);
        // Recupera la persona recién creada para obtener su ID de Supabase.
        final resultados = await widget.personaRepository.searchPersonas(
          '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}',
        );
        persona = resultados.isNotEmpty ? resultados.first : nueva;
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
      estado: EstadoCita.pendiente,
    );

    if (!mounted) return;
    setState(() => _guardando = true);
    context.read<CitaBloc>().add(CreateCitaEvent(cita));
  }

  /// Construye una [Persona] mínima con los datos del formulario.
  /// [contactos] es una lista; se crea un único contacto principal
  /// con el teléfono capturado.
  Persona _buildNuevaPersona() {
    return Persona(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      birthDate: DateTime(2000), // placeholder — agrega campo si lo necesitas
      govID: '',
      contactos: _buildContactos(),
      estatus: EstatusPersona.activo,
    );
  }

  /// Devuelve la lista de contactos para la nueva persona.
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
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<CitaBloc, CitaState>(
      listener: (ctx, state) {
        if (state is CitaCreated) {
          setState(() => _guardando = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cita agendada correctamente.')),
          );
        } else if (state is CitaError) {
          setState(() => _guardando = false);
          _showError(state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _step == _Step.buscarPersona
                      ? _buildBuscarPersona(context)
                      : _buildFormularioCita(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildDialogHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titulo = _step == _Step.buscarPersona
        ? 'Nueva Cita — Paso 1 de 2'
        : 'Nueva Cita — Paso 2 de 2';
    final subtitulo = _step == _Step.buscarPersona
        ? 'Busca al paciente o regístralo si es nuevo.'
        : _esNuevaPersona
            ? 'Nuevo paciente · Completa los datos de la cita.'
            : '${_personaSeleccionada!.nombre} ${_personaSeleccionada!.apellido} · Datos de la cita.';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event_outlined, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitulo,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (_step == _Step.formularioCita)
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: _guardando
                  ? null
                  : () => setState(() {
                        _step = _Step.buscarPersona;
                        _doctorSeleccionado = null;
                        _fecha = null;
                        _hora = null;
                      }),
            ),
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close),
            onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─── Paso 1: Búsqueda de persona ──────────────────────────────────────────
  Widget _buildBuscarPersona(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Buscar paciente',
            hintText: 'Nombre o apellido...',
            prefixIcon: const Icon(Icons.search, size: 20),
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
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _resultados = []);
                        },
                      )
                    : null,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: _buscar,
        ),
        const SizedBox(height: 12),

        if (_resultados.isNotEmpty) ...[
          Text('Resultados',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resultados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final p = _resultados[i];
              return _PersonaTile(persona: p, onTap: () => _seleccionarPersona(p));
            },
          ),
          const SizedBox(height: 16),
        ],

        OutlinedButton.icon(
          onPressed: _usarNuevaPersona,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('No está registrado — Registrar nuevo'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),

        if (_esNuevaPersona) ...[
          const SizedBox(height: 20),
          _buildNuevaPersonaForm(context),
        ],
      ],
    );
  }

  Widget _buildNuevaPersonaForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withAlpha(80)),
      ),
      child: Form(
        key: _formKeyPersona,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text('Datos del nuevo paciente',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: cs.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _apellidoCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Apellido *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _irAFormulario,
                child: const Text('Continuar con este paciente →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Paso 2: Formulario de cita ───────────────────────────────────────────
  Widget _buildFormularioCita(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKeyCita,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          _SectionLabel(
              icon: Icons.medical_services_outlined, label: 'Odontólogo'),
          const SizedBox(height: 8),
          _cargandoDoctores
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Doctor>(
                  value: _doctorSeleccionado,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar odontólogo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _doctores
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('${d.nombre} ${d.apellido}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _doctorSeleccionado = v),
                  validator: (v) =>
                      v == null ? 'Selecciona un odontólogo' : null,
                ),

          const SizedBox(height: 20),

          _SectionLabel(
              icon: Icons.schedule_outlined, label: 'Fecha y Hora *'),
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
                ),
              ),
            ],
          ),
          if (_guardando && (_fecha == null || _hora == null))
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text('Selecciona fecha y hora.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.error)),
            ),

          const SizedBox(height: 20),

          _SectionLabel(
              icon: Icons.notes_outlined, label: 'Motivo de la consulta'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivoCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Describe brevemente el motivo de la visita...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: _esEmergencia
                  ? cs.errorContainer.withAlpha(80)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _esEmergencia
                    ? cs.error.withAlpha(120)
                    : cs.outlineVariant,
              ),
            ),
            child: SwitchListTile(
              title: const Text('Cita de emergencia'),
              subtitle: const Text('Prioridad alta en la agenda.'),
              value: _esEmergencia,
              onChanged: (v) => setState(() => _esEmergencia = v),
              activeColor: cs.error,
              dense: true,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _guardando ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirmar Cita'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Pickers ──────────────────────────────────────────────────────────────
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

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Text(iniciales,
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${persona.nombre} ${persona.apellido}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (persona.govID.isNotEmpty)
                    Text('Cédula: ${persona.govID}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
          ],
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
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon,
          size: 16, color: hasValue ? cs.primary : cs.onSurfaceVariant),
      label: Text(
        label,
        style: TextStyle(
          color: hasValue ? cs.primary : cs.onSurfaceVariant,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: hasValue ? cs.primary : cs.outlineVariant),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}