import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

InputDecoration _sharedInputDeco(
  AppColors ac, {
  String? hint,
  bool alignLabelWithHint = false,
}) => InputDecoration(
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
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: ac.red, width: 0.5),
  ),
  alignLabelWithHint: alignLabelWithHint,
);

class DiagnosisFormPage extends StatefulWidget {
  final DiagnosisRepository repository;
  final Diagnosis? diagnosis;

  const DiagnosisFormPage({
    super.key,
    required this.repository,
    this.diagnosis,
  });

  @override
  State<DiagnosisFormPage> createState() => _DiagnosisFormPageState();
}

class _DiagnosisFormPageState extends State<DiagnosisFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _claveOdontogramaController;

  late SeveridadDiagnosis _severidad;
  late Alcance _alcance;
  late CategoriaDiagnosis _categoria;

  bool _saving = false;
  bool get _isEditing => widget.diagnosis != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.diagnosis?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.diagnosis?.descripcion ?? '',
    );
    _claveOdontogramaController = TextEditingController(
      text: widget.diagnosis?.claveOdontograma ?? '',
    );

    _severidad = widget.diagnosis?.severidadDefault ?? SeveridadDiagnosis.leve;
    _alcance = widget.diagnosis?.alcance ?? Alcance.diente;
    _categoria = widget.diagnosis?.categoria ?? CategoriaDiagnosis.caries;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _claveOdontogramaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final claveClean = _claveOdontogramaController.text.trim();

    final diagnosis = Diagnosis(
      id: widget.diagnosis?.id,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      severidadDefault: _severidad,
      alcance: _alcance,
      categoria: _categoria,
      claveOdontograma: claveClean.isEmpty ? null : claveClean,
    );

    try {
      if (_isEditing) {
        await widget.repository.actualizarDiagnosis(diagnosis);
      } else {
        await widget.repository.agregarDiagnosis(diagnosis);
      }

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el diagnóstico: $e')),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditing ? 'Editar diagnóstico' : 'Nuevo diagnóstico',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ac.textPrimary,
                        ),
                      ),
                    ],
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
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _sharedInputDeco(
                    ac,
                    hint: 'Nombre del diagnóstico (ej. Caries dental)',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el nombre del diagnóstico'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: _sharedInputDeco(
                    ac,
                    hint: 'Descripción clínica...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CategoriaDiagnosis>(
                        value: _categoria,
                        decoration: _sharedInputDeco(ac, hint: 'Categoría'),
                        items: CategoriaDiagnosis.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.nombre),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _categoria = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<SeveridadDiagnosis>(
                        value: _severidad,
                        decoration: _sharedInputDeco(ac, hint: 'Severidad'),
                        items: SeveridadDiagnosis.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.etiqueta),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _severidad = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Alcance>(
                        value: _alcance,
                        decoration: _sharedInputDeco(ac, hint: 'Alcance'),
                        items: Alcance.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(_capitalize(a.name)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _alcance = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _claveOdontogramaController,
                        decoration: _sharedInputDeco(
                          ac,
                          hint: 'Clave odontograma (opcional)',
                        ),
                      ),
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
