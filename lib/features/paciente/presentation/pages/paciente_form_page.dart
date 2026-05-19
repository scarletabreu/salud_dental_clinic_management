import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart'; // Importación de tu entidad real
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';

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
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;      // Controlador añadido para Contacto
  late final TextEditingController _direccionController;  // Controlador añadido para Contacto
  late final TextEditingController _trabajoController;
  late final TextEditingController _referenciaController;

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
    
    // Inicialización de datos de Contacto
    _telefonoController = TextEditingController(text: p?.contacto.numeroTelefono ?? '');
    _emailController = TextEditingController(text: p?.contacto.email ?? '');
    _direccionController = TextEditingController(text: p?.contacto.direccion ?? '');
    
    _trabajoController = TextEditingController(text: p?.trabajo ?? '');
    _referenciaController = TextEditingController(text: p?.referencia ?? '');
    _fechaNacimiento = p?.birthDate;
    if (p != null) {
      _genero = p.genero;
      _tipoPaciente = p.tipoPaciente;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _trabajoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Lógica de Guardado
  // -------------------------------------------------------------------------
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Se construye o muta el objeto Contacto usando los requerimientos de tu clase
    final contactoFinal = widget.paciente?.contacto.copyWith(
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          direccion: _direccionController.text.trim(),
        ) ??
        Contacto(
          id: null,
          numeroTelefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          direccion: _direccionController.text.trim(),
        );

    final paciente = Paciente(
      id: widget.paciente?.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      birthDate: _fechaNacimiento!,
      govID: _cedulaController.text.trim(),
      contacto: contactoFinal,
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
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
              Text(
                _isEditing ? 'Editar Paciente' : 'Nuevo Paciente',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
                      _isEditing ? 'Editar Paciente' : 'Registro de Paciente',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isEditing
                          ? 'Modifica los datos del paciente.'
                          : 'Complete los datos para registrar un nuevo paciente.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                label: Text(_isEditing ? 'Guardar Cambios' : 'Guardar Paciente'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    _buildContactoPanel(context),
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
            _buildContactoPanel(context),
            const SizedBox(height: 16),
            _buildInfoAdicionalPanel(context),
          ],
        );
      },
    );
  }

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
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'El apellido es obligatorio' : null,
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
              prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'La cédula es obligatoria';
              if (v.replaceAll(RegExp(r'\D'), '').length != 11) {
                return 'La cédula debe tener exactamente 11 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          FormField<DateTime>(
            initialValue: _fechaNacimiento,
            validator: (_) => _fechaNacimiento == null ? 'La fecha de nacimiento es obligatoria' : null,
            builder: (field) {
              return InkWell(
                onTap: _pickFechaNacimiento,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: field.hasError
                          ? BorderSide(color: Theme.of(context).colorScheme.error)
                          : const BorderSide(),
                    ),
                    errorText: field.errorText,
                  ),
                  child: Text(
                    _fechaNacimiento != null ? _formatDate(_fechaNacimiento!) : 'Seleccionar fecha',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _fechaNacimiento != null ? null : colorScheme.onSurfaceVariant,
                        ),
                ),
              ));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Genero>(
            value: _genero,
            decoration: InputDecoration(
              labelText: 'Género',
              prefixIcon: const Icon(Icons.wc_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: Genero.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _genero = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactoPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      icon: Icons.contact_phone_outlined,
      iconColor: colorScheme.secondary,
      iconBackground: colorScheme.secondaryContainer,
      title: 'Información de Contacto',
      child: Column(
        children: [
          TextFormField(
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono *',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'El teléfono es obligatorio' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _direccionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Dirección Residencia',
              prefixIcon: const Icon(Icons.home_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

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
              prefixIcon: const Icon(Icons.category_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: TipoPaciente.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenciaController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Referencia',
              prefixIcon: const Icon(Icons.share_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Widget child;

  const _Panel({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.child,
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
                decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}