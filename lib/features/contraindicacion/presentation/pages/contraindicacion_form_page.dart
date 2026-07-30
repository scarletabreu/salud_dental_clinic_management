import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class ContraindicacionFormPage extends StatefulWidget {
  final String? medicinaIdDefault;

  const ContraindicacionFormPage({super.key, this.medicinaIdDefault});

  @override
  State<ContraindicacionFormPage> createState() =>
      _ContraindicacionFormPageState();
}

class _ContraindicacionFormPageState extends State<ContraindicacionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  String? _selectedCondicionId;
  String? _selectedMedicinaId;
  TipoContraindicacion _tipo = TipoContraindicacion.relativa;
  final Set<EfectoAdverso> _efectosAdversos = {};

  List<Condicion> _condiciones = [];
  List<Medicina> _medicinas = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMedicinaId = widget.medicinaIdDefault;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final condiciones = await sl<CondicionRepository>().getCondiciones();
      final medicinas = await sl<IMedicinaRepository>().getCatalogoMedicinas();

      if (!mounted) return;
      setState(() {
        _condiciones = condiciones;
        _medicinas = medicinas;
        if (_condiciones.isNotEmpty) {
          _selectedCondicionId = _condiciones.first.id;
        }
        if (_selectedMedicinaId == null && _medicinas.isNotEmpty) {
          _selectedMedicinaId = _medicinas.first.id;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondicionId == null || _selectedMedicinaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una condición médica y un fármaco.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final nuevaContraindicacion = Contraindicacion(
        condicionId: _selectedCondicionId!,
        medicinaId: _selectedMedicinaId,
        procedimientoId: null,
        tratamientoId: null,
        descripcion: _descripcionController.text.trim(),
        tipoContraindicacion: _tipo,
        efectosAdversos: _efectosAdversos.toList(),
      );

      await sl<ContraindicacionRepository>().guardarContraindicacion(
        nuevaContraindicacion,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraindicación registrada exitosamente.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        title: const Text('Nueva Contraindicación'),
        backgroundColor: ac.cardBg,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: ac.primaryGreen))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🩺 1. Seleccionar Condición Médica
                    Text('CONDICIÓN MÉDICA *', style: _labelStyle(ac)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCondicionId,
                      decoration: _inputDecoration(ac),
                      items: _condiciones.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombre),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCondicionId = val),
                    ),
                    const SizedBox(height: 16),

                    // 💊 2. Seleccionar Medicina Asocida
                    Text('MEDICAMENTO ASOCIADO *', style: _labelStyle(ac)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedMedicinaId,
                      decoration: _inputDecoration(ac),
                      items: _medicinas.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nombre),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedMedicinaId = val),
                    ),
                    const SizedBox(height: 16),

                    // 📝 3. Descripción
                    Text(
                      'DESCRIPCIÓN / NOTA CLÍNICA *',
                      style: _labelStyle(ac),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        ac,
                        hint:
                            'Ej. Contraindicado en pacientes hipertensos por riesgo de arritmias.',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa una descripción'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ⚠️ 4. Tipo de Contraindicación
                    Text('TIPO DE CONTRAINDICACIÓN', style: _labelStyle(ac)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TipoContraindicacion>(
                      value: _tipo,
                      decoration: _inputDecoration(ac),
                      items: TipoContraindicacion.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _tipo = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ⚡ 5. Efectos Adversos
                    Text('EFECTOS ADVERSOS', style: _labelStyle(ac)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: EfectoAdverso.values.map((e) {
                        final selected = _efectosAdversos.contains(e);
                        return FilterChip(
                          label: Text(e.name),
                          selected: selected,
                          selectedColor: ac.red.withValues(alpha: 0.15),
                          onSelected: (val) {
                            setState(() {
                              val
                                  ? _efectosAdversos.add(e)
                                  : _efectosAdversos.remove(e);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // 💾 Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Registrar Contraindicación'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ac.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  TextStyle _labelStyle(AppColors ac) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: ac.textMuted,
  );

  InputDecoration _inputDecoration(AppColors ac, {String? hint}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: ac.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}
