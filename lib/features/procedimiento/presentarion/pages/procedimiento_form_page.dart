import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';

InputDecoration _sharedInputDeco(AppColors ac, {String? hint}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      filled: true,
      fillColor: ac.bgPage,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ac.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ac.divider, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ac.primaryGreen, width: 1.0),
      ),
    );

class ProcedimientoFormPage extends StatefulWidget {
  final ProcedimientoRepository repository;
  final Procedimiento? procedimiento;

  const ProcedimientoFormPage({
    super.key,
    required this.repository,
    this.procedimiento,
  });

  @override
  State<ProcedimientoFormPage> createState() => _ProcedimientoFormPageState();
}

class _ProcedimientoFormPageState extends State<ProcedimientoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  final List<Contraindicacion> _contraindicaciones = [];

  bool _saving = false;
  bool get _isEditing => widget.procedimiento != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.procedimiento?.nombre ?? '',
    );
    if (widget.procedimiento != null) {
      _contraindicaciones.addAll(widget.procedimiento!.contraindicaciones);
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

    final procedimiento = Procedimiento(
      id: widget.procedimiento?.id,
      nombre: _nombreController.text.trim(),
      contraindicaciones: _contraindicaciones,
    );

    try {
      await widget.repository.guardarProcedimiento(procedimiento);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el procedimiento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          color: ac.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: ac.divider),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: ac.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditing ? 'Editar procedimiento' : 'Nuevo procedimiento',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ac.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ac.divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre del procedimiento *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _sharedInputDeco(
                    ac,
                    hint: 'Ej. Profilaxis Dental Profunda',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el nombre del procedimiento'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
