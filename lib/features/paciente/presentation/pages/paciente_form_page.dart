import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/util/validators.dart';

// =============================================================================
// Input formatter: auto-inserta guiones → 000-0000000-0
// =============================================================================

class _CedulaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 10) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// =============================================================================
// Modelo de trabajo para editar un contacto en memoria
// =============================================================================

class _ContactoEntry {
  final String? originalId;
  final TextEditingController telefono;
  final TextEditingController email;
  final TextEditingController direccion;
  bool isExpanded;

  _ContactoEntry({
    this.originalId,
    String telefonoInitial = '',
    String emailInitial = '',
    String direccionInitial = '',
    this.isExpanded = true,
  })  : telefono = TextEditingController(text: telefonoInitial),
        email = TextEditingController(text: emailInitial),
        direccion = TextEditingController(text: direccionInitial);

  factory _ContactoEntry.fromContacto(Contacto c, {bool isExpanded = false}) =>
      _ContactoEntry(
        originalId: c.id,
        telefonoInitial: c.numeroTelefono,
        emailInitial: c.email,
        direccionInitial: c.direccion,
        isExpanded: isExpanded,
      );

  ContactoModel toModel() => ContactoModel(
        id: originalId,
        numeroTelefono: telefono.text.trim(),
        email: email.text.trim(),
        direccion: direccion.text.trim(),
      );

  void dispose() {
    telefono.dispose();
    email.dispose();
    direccion.dispose();
  }

  /// Etiqueta de resumen para la tarjeta colapsada.
  String get resumen {
    final tel = telefono.text.trim();
    final mail = email.text.trim();
    if (tel.isNotEmpty) return tel;
    if (mail.isNotEmpty) return mail;
    return 'Nuevo contacto';
  }
}

// =============================================================================
// Page
// =============================================================================

class PacienteFormPage extends StatefulWidget {
  final Paciente? paciente;

  const PacienteFormPage({super.key, this.paciente});

  @override
  State<PacienteFormPage> createState() => _PacienteFormPageState();
}

class _PacienteFormPageState extends State<PacienteFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _cedulaController;
  late final TextEditingController _trabajoController;
  late final TextEditingController _referenciaController;

  late final List<_ContactoEntry> _contactos;

  DateTime? _fechaNacimiento;
  Genero _genero = Genero.masculino;
  TipoPaciente _tipoPaciente = TipoPaciente.integrado;

  bool get _isEditing => widget.paciente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.paciente;

    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _apellidoController = TextEditingController(text: p?.apellido ?? '');
    _cedulaController = TextEditingController(text: p?.govID ?? '');
    _trabajoController = TextEditingController(text: p?.trabajo ?? '');
    _referenciaController = TextEditingController(text: p?.referencia ?? '');
    _fechaNacimiento = p?.birthDate;

    if (p != null) {
      _genero = p.genero;
      _tipoPaciente = p.tipoPaciente;
      _contactos = p.contactos.isEmpty
          ? [_ContactoEntry(isExpanded: true)]
          : p.contactos
              .asMap()
              .entries
              .map((e) => _ContactoEntry.fromContacto(
                    e.value,
                    isExpanded: e.key == 0,
                  ))
              .toList();
    } else {
      _contactos = [_ContactoEntry(isExpanded: true)];
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _trabajoController.dispose();
    _referenciaController.dispose();
    for (final c in _contactos) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Contactos helpers
  // ---------------------------------------------------------------------------

  void _addContacto() {
    setState(() {
      for (final c in _contactos) {
        c.isExpanded = false;
      }
      _contactos.add(_ContactoEntry(isExpanded: true));
    });
  }

  void _removeContacto(int index) {
    setState(() {
      _contactos[index].dispose();
      _contactos.removeAt(index);
      if (_contactos.isNotEmpty && _contactos.every((c) => !c.isExpanded)) {
        _contactos.first.isExpanded = true;
      }
    });
  }

  void _toggleContacto(int index) {
    setState(() {
      final isNowExpanded = !_contactos[index].isExpanded;
      for (final c in _contactos) {
        c.isExpanded = false;
      }
      _contactos[index].isExpanded = isNowExpanded;
    });
  }

  // ---------------------------------------------------------------------------
  // Guardar
  // ---------------------------------------------------------------------------

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_contactos.isEmpty ||
        _contactos.every((c) => c.telefono.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar al menos un contacto con teléfono.'),
        ),
      );
      return;
    }

    final contactosFinal = _contactos.map((c) => c.toModel()).toList();

    final paciente = Paciente(
      id: widget.paciente?.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      birthDate: _fechaNacimiento!,
      govID: _cedulaController.text.trim(),
      contactos: contactosFinal,
      estatus: widget.paciente?.estatus ?? EstatusPersona.activo,
      genero: _genero,
      tipoPaciente: _tipoPaciente,
      trabajo: _trabajoController.text.trim(),
      referencia: _referenciaController.text.trim(),
      record: widget.paciente?.record ?? RecordModel.empty(),
      citas: widget.paciente?.citas ?? const [],
    );

    final cubit = context.read<PacienteCubit>();
    if (_isEditing) {
      cubit.updatePaciente(paciente);
    } else {
      cubit.addPaciente(paciente);
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
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<PacienteCubit, PacienteState>(
      listener: (context, state) {
        if (state is PacienteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is PacienteOperationSuccess) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final isSaving = state is PacienteLoading;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(context, isSaving: isSaving),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildFormBody(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isSaving}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Pacientes',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.primary),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 16, color: colorScheme.onSurfaceVariant),
              Text(
                _isEditing ? 'Editar Paciente' : 'Nuevo Paciente',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Editar Paciente'
                          : 'Registro de Paciente',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isEditing
                          ? 'Modifica los datos del paciente.'
                          : 'Complete los datos para registrar un nuevo paciente.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isSaving ? null : _save,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                    _isEditing ? 'Guardar Cambios' : 'Guardar Paciente'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildDatosPersonalesPanel(context),
                    const SizedBox(height: 16),
                    _buildContactosPanel(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _buildInfoAdicionalPanel(context),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildDatosPersonalesPanel(context),
            const SizedBox(height: 16),
            _buildContactosPanel(context),
            const SizedBox(height: 16),
            _buildInfoAdicionalPanel(context),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Panel: Datos Personales
  // ---------------------------------------------------------------------------

  Widget _buildDatosPersonalesPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      icon: Icons.person_outline,
      iconColor: colorScheme.primary,
      iconBackground: colorScheme.primaryContainer,
      title: 'Datos Personales',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon:
                        const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon:
                        const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El apellido es obligatorio'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cedulaController,
            keyboardType: TextInputType.number,
            inputFormatters: [_CedulaInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Cédula *',
              hintText: '000-0000000-0',
              prefixIcon:
                  const Icon(Icons.credit_card_outlined, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            validator: cedulaValidator,
          ),
          const SizedBox(height: 16),
          FormField<DateTime>(
            initialValue: _fechaNacimiento,
            validator: (_) => _fechaNacimiento == null
                ? 'La fecha de nacimiento es obligatoria'
                : null,
            builder: (field) {
              return InkWell(
                onTap: _pickFechaNacimiento,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: field.hasError
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.error)
                          : const BorderSide(),
                    ),
                    errorText: field.errorText,
                  ),
                  child: Text(
                    _fechaNacimiento != null
                        ? _formatDate(_fechaNacimiento!)
                        : 'Seleccionar fecha',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _fechaNacimiento != null
                                  ? null
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Genero>(
            value: _genero,
            decoration: InputDecoration(
              labelText: 'Género',
              prefixIcon: const Icon(Icons.wc_outlined, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            items: Genero.values
                .map((g) =>
                    DropdownMenuItem(value: g, child: Text(g.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _genero = v);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Panel: Contactos (dinámico, expandible)
  // ---------------------------------------------------------------------------

  Widget _buildContactosPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      icon: Icons.contact_phone_outlined,
      iconColor: colorScheme.secondary,
      iconBackground: colorScheme.secondaryContainer,
      title: 'Información de Contacto',
      action: TextButton.icon(
        onPressed: _addContacto,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar'),
      ),
      child: Column(
        children: [
          if (_contactos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sin contactos. Presiona "Agregar" para añadir uno.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ...List.generate(
            _contactos.length,
            (index) => _buildContactoCard(context, index),
          ),
        ],
      ),
    );
  }

  Widget _buildContactoCard(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = _contactos[index];
    final isFirst = index == 0;

    return Padding(
      padding:
          EdgeInsets.only(bottom: index < _contactos.length - 1 ? 12 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: entry.isExpanded
                ? colorScheme.secondary
                : colorScheme.outlineVariant,
            width: entry.isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header de la tarjeta
            InkWell(
              onTap: () => _toggleContacto(index),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                topRight: const Radius.circular(10),
                bottomLeft: Radius.circular(entry.isExpanded ? 0 : 10),
                bottomRight: Radius.circular(entry.isExpanded ? 0 : 10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isFirst ? 'Contacto principal' : entry.resumen,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_contactos.length > 1)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colorScheme.error.withOpacity(0.8),
                        ),
                        tooltip: 'Eliminar contacto',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeContacto(index),
                      ),
                    Icon(
                      entry.isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Cuerpo expandible
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: entry.isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    const Divider(height: 16),
                    TextFormField(
                      controller: entry.telefono,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText:
                            isFirst ? 'Teléfono *' : 'Teléfono',
                        prefixIcon: const Icon(
                            Icons.phone_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: isFirst
                          ? (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'El teléfono principal es obligatorio'
                                  : null
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: entry.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                          return 'Formato de correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: entry.direccion,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: const Icon(
                            Icons.home_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Panel: Info Adicional
  // ---------------------------------------------------------------------------

  Widget _buildInfoAdicionalPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      icon: Icons.info_outline,
      iconColor: colorScheme.tertiary,
      iconBackground: colorScheme.tertiaryContainer,
      title: 'Información Adicional',
      child: Column(
        children: [
          DropdownButtonFormField<TipoPaciente>(
            value: _tipoPaciente,
            decoration: InputDecoration(
              labelText: 'Tipo de Paciente',
              prefixIcon:
                  const Icon(Icons.category_outlined, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            items: TipoPaciente.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _tipoPaciente = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _trabajoController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Trabajo / Ocupación',
              prefixIcon: const Icon(Icons.work_outline, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenciaController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Referencia',
              prefixIcon:
                  const Icon(Icons.share_outlined, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _Panel: contenedor reutilizable con soporte de acción en el header
// =============================================================================

class _Panel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Widget child;
  final Widget? action;

  const _Panel({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
