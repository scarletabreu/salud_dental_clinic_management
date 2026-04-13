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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar medicina' : 'Nueva medicina'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNombreField(context),
            const SizedBox(height: 24),
            _buildEfectosSection(context),
            const SizedBox(height: 32),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNombreField(BuildContext context) {
    return TextFormField(
      controller: _nombreController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ej. Ibuprofeno',
        prefixIcon: const Icon(Icons.medication_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'El nombre no puede estar vacío';
        }
        return null;
      },
    );
  }

  Widget _buildEfectosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efectos secundarios',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona los efectos que puede producir esta medicina.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: EfectoSecundario.values.map((efecto) {
            final selected = _efectosSeleccionados.contains(efecto);
            return FilterChip(
              label: Text(efecto.nombre),
              selected: selected,
              onSelected: (v) => setState(() {
                v
                    ? _efectosSeleccionados.add(efecto)
                    : _efectosSeleccionados.remove(efecto);
              }),
            );
          }).toList(),
        ),
        if (_efectosSeleccionados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_efectosSeleccionados.length} seleccionado${_efectosSeleccionados.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isEditing ? 'Guardar cambios' : 'Crear medicina'),
      ),
    );
  }
}
