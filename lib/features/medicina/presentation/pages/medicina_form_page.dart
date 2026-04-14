import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/condicion_medica.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/add_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/update_medicina.dart';

class MedicinaFormPage extends StatefulWidget {
  final IMedicinaRepository repository;
  final Medicina? medicina;

  const MedicinaFormPage({
    super.key,
    required this.repository,
    this.medicina,
  });

  @override
  State<MedicinaFormPage> createState() => _MedicinaFormPageState();
}

class _MedicinaFormPageState extends State<MedicinaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final AddMedicina _addMedicina;
  late final UpdateMedicina _updateMedicina;

  final Set<EfectoSecundario> _efectosSeleccionados = {};
  final List<Contraindicacion> _contraindicaciones = [];
  bool _saving = false;

  bool get _isEditing => widget.medicina != null;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.medicina?.nombre ?? '');
    _addMedicina = AddMedicina(widget.repository);
    _updateMedicina = UpdateMedicina(widget.repository);
    if (widget.medicina != null) {
      _efectosSeleccionados.addAll(widget.medicina!.efectosSecundarios);
      _contraindicaciones.addAll(widget.medicina!.contraindicaciones);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final medicina = Medicina(
      id: widget.medicina?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreController.text.trim(),
      contraindicaciones: _contraindicaciones,
      efectosSecundarios: _efectosSeleccionados.toList(),
    );

    final result = _isEditing
        ? await _updateMedicina(medicina)
        : await _addMedicina(medicina);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(context),
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
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Inventario',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 16, color: colorScheme.onSurfaceVariant),
              Text(
                _isEditing ? 'Editar Medicina' : 'Nueva Medicina',
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
                      _isEditing
                          ? 'Editar Medicamento'
                          : 'Registro de Medicamento',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _isEditing
                          ? 'Modifica los datos del fármaco.'
                          : 'Complete los detalles para agregar un nuevo fármaco.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isEditing ? 'Guardar Cambios' : 'Guardar Medicina'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    _buildInfoPanel(context),
                    const SizedBox(height: 16),
                    _buildContraindicacionesPanel(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _buildEfectosPanel(context),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildInfoPanel(context),
            const SizedBox(height: 16),
            _buildContraindicacionesPanel(context),
            const SizedBox(height: 16),
            _buildEfectosPanel(context),
          ],
        );
      },
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
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
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.info_outline,
                    size: 16, color: colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Información General',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nombreController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nombre de Medicina *',
              hintText: 'Ej. Ibuprofeno 400mg',
              helperText: 'Este nombre aparecerá en las recetas médicas.',
              prefixIcon:
                  const Icon(Icons.medication_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El nombre no puede estar vacío';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContraindicacionesPanel(BuildContext context) {
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
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.block_rounded,
                    size: 16, color: colorScheme.error),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contraindicaciones',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (_contraindicaciones.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_contraindicaciones.length}',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _showContraindicacionDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Condiciones o situaciones en las que no se debe usar este medicamento.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (_contraindicaciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._contraindicaciones.asMap().entries.map((entry) {
              final index = entry.key;
              final c = entry.value;
              final isAbsoluta =
                  c.tipoContraindicacion == TipoContraindicacion.absoluta;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withAlpha(60)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAbsoluta
                            ? colorScheme.error
                            : colorScheme.error.withAlpha(153),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.tipoContraindicacion.name,
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.descripcion,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                          ),
                          if (c.efectosAdversos.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: c.efectosAdversos
                                  .map(
                                    (e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.error.withAlpha(26),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: colorScheme.error
                                                .withAlpha(77)),
                                      ),
                                      child: Text(
                                        e.name,
                                        style: TextStyle(
                                          color:
                                              colorScheme.onErrorContainer,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () =>
                          _showContraindicacionDialog(context, index: index),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                      color: colorScheme.onSurfaceVariant,
                    ),
                    IconButton(
                      onPressed: () => _deleteContraindicacion(index),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Eliminar',
                      color: colorScheme.error,
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Ninguna registrada',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _deleteContraindicacion(int index) {
    setState(() => _contraindicaciones.removeAt(index));
  }

  Future<void> _showContraindicacionDialog(BuildContext context,
      {int? index}) async {
    final existing = index != null ? _contraindicaciones[index] : null;
    final result = await showDialog<Contraindicacion>(
      context: context,
      builder: (_) => _ContraindicacionDialog(existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _contraindicaciones[index] = result;
      } else {
        _contraindicaciones.add(result);
      }
    });
  }

  Widget _buildEfectosPanel(BuildContext context) {
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
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.warning_amber_outlined,
                    size: 16, color: colorScheme.secondary),
              ),
              const SizedBox(width: 8),
              Text(
                'Efectos Secundarios',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona los efectos secundarios más comunes reportados.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EfectoSecundario.values.map((efecto) {
              final selected = _efectosSeleccionados.contains(efecto);
              return FilterChip(
                label: Text(
                  efecto.nombre,
                  style: const TextStyle(fontSize: 13),
                ),
                selected: selected,
                onSelected: (v) => setState(() {
                  v
                      ? _efectosSeleccionados.add(efecto)
                      : _efectosSeleccionados.remove(efecto);
                }),
                selectedColor:
                    colorScheme.secondaryContainer,
                checkmarkColor: colorScheme.secondary,
                side: BorderSide(
                  color: selected
                      ? colorScheme.secondary
                      : colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
          if (_efectosSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_efectosSeleccionados.length} efecto${_efectosSeleccionados.length == 1 ? '' : 's'} seleccionado${_efectosSeleccionados.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContraindicacionDialog extends StatefulWidget {
  final Contraindicacion? existing;

  const _ContraindicacionDialog({this.existing});

  @override
  State<_ContraindicacionDialog> createState() =>
      _ContraindicacionDialogState();
}

class _ContraindicacionDialogState extends State<_ContraindicacionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionController;
  late TipoContraindicacion _tipo;
  late Set<EfectoAdverso> _efectosAdversos;
  CondicionMedica? _condicion;

  @override
  void initState() {
    super.initState();
    _descripcionController =
        TextEditingController(text: widget.existing?.descripcion ?? '');
    _tipo = widget.existing?.tipoContraindicacion ?? TipoContraindicacion.relativa;
    _efectosAdversos = Set.from(widget.existing?.efectosAdversos ?? []);
    _condicion = widget.existing?.condicion;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final result = Contraindicacion(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      condicion: _condicion,
      medicinaId: widget.existing?.medicinaId ?? '',
      contraindicacionId: widget.existing?.contraindicacionId ?? '',
      tratamientoId: widget.existing?.tratamientoId ?? '',
      descripcion: _descripcionController.text.trim(),
      tipoContraindicacion: _tipo,
      efectosAdversos: _efectosAdversos.toList(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.block_rounded,
                          size: 16, color: colorScheme.error),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing
                          ? 'Editar Contraindicación'
                          : 'Nueva Contraindicación',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Ej. No usar en pacientes con insuficiencia renal.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'La descripción no puede estar vacía';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CondicionMedica?>(
                  value: _condicion,
                  decoration: InputDecoration(
                    labelText: 'Condición médica',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<CondicionMedica?>(
                      value: null,
                      child: Text('Sin condición específica'),
                    ),
                    ...CondicionMedica.values.map(
                      (c) => DropdownMenuItem<CondicionMedica?>(
                        value: c,
                        child: Text(c.label),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _condicion = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoContraindicacion>(
                  initialValue: _tipo,
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: TipoContraindicacion.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _tipo = v);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Efectos Adversos',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: EfectoAdverso.values.map((e) {
                    final selected = _efectosAdversos.contains(e);
                    return FilterChip(
                      label: Text(e.name, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v
                            ? _efectosAdversos.add(e)
                            : _efectosAdversos.remove(e);
                      }),
                      selectedColor: colorScheme.errorContainer,
                      checkmarkColor: colorScheme.error,
                      side: BorderSide(
                        color: selected
                            ? colorScheme.error
                            : colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _confirm,
                      child: Text(
                          isEditing ? 'Guardar Cambios' : 'Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
