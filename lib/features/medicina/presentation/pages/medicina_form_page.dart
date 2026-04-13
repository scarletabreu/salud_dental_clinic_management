import 'package:flutter/material.dart';
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
      contraindicaciones: widget.medicina?.contraindicaciones ?? [],
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
                child: _buildInfoPanel(context),
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
          if (_isEditing && widget.medicina!.contraindicaciones.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildContraindicacionesSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildContraindicacionesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contras = widget.medicina!.contraindicaciones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: colorScheme.error),
            const SizedBox(width: 6),
            Text(
              'Contraindicaciones',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...contras.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: colorScheme.error.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.block,
                    size: 14, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.descripcion,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
