import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/add_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/update_medicina.dart';

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

class MedicinaFormPage extends StatefulWidget {
  final IMedicinaRepository repository;
  final Medicina? medicina;

  const MedicinaFormPage({super.key, required this.repository, this.medicina});

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
    _nombreController = TextEditingController(
      text: widget.medicina?.nombre ?? '',
    );
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
      id: widget.medicina?.id,
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
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: _buildAppBar(ac),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInfoCard(ac),
              const SizedBox(height: 16),
              _buildEfectosCard(ac),
              const SizedBox(height: 16),
              _buildContraindicacionesCard(ac),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColors ac) {
    return PreferredSize(
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
                    Row(
                      children: [
                        Text(
                          'Inventario',
                          style: TextStyle(
                            fontSize: 11,
                            color: ac.primaryGreen,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 13,
                          color: ac.textMuted,
                        ),
                        Text(
                          _isEditing ? 'Editar medicina' : 'Nueva medicina',
                          style: TextStyle(fontSize: 11, color: ac.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditing
                          ? 'Editar medicamento'
                          : 'Registro de medicamento',
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.textSecondary,
                  side: BorderSide(color: ac.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.primaryGreen,
      iconBg: ac.primaryGreen.withValues(alpha: 0.10),
      icon: Icons.medication_outlined,
      title: 'Información general',
      child: _FormField(
        ac: ac,
        icon: Icons.label_outline_rounded,
        label: 'Nombre del medicamento',
        child: TextFormField(
          controller: _nombreController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _sharedInputDeco(ac, hint: 'Ej. Ibuprofeno 400mg'),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'El nombre no puede estar vacío'
              : null,
        ),
      ),
    );
  }

  Widget _buildEfectosCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: const Color(0xFFB45309),
      iconBg: const Color(0xFFFEF3C7),
      icon: Icons.warning_amber_outlined,
      title: 'Efectos secundarios',
      subtitle: 'Selecciona los efectos más comunes reportados.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EfectoSecundario.values.map((efecto) {
              final selected = _efectosSeleccionados.contains(efecto);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
                      ? _efectosSeleccionados.remove(efecto)
                      : _efectosSeleccionados.add(efecto);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFEF3C7) : ac.bgPage,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? const Color(0xFFD97706) : ac.divider,
                      width: selected ? 1.0 : 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        efecto.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? const Color(0xFFB45309)
                              : ac.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_efectosSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                '${_efectosSeleccionados.length} efecto${_efectosSeleccionados.length == 1 ? '' : 's'} seleccionado${_efectosSeleccionados.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContraindicacionesCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.red,
      iconBg: ac.red.withValues(alpha: 0.10),
      icon: Icons.block_rounded,
      title: 'Contraindicaciones',
      subtitle: 'Condiciones en las que no se debe usar este medicamento.',
      action: TextButton.icon(
        onPressed: () => _showContraindicacionDialog(context),
        icon: Icon(Icons.add_rounded, size: 16, color: ac.primaryGreen),
        label: Text(
          'Agregar',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ac.primaryGreen,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: _contraindicaciones.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: ac.bgPage,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ac.divider, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 26,
                    color: ac.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no hay contraindicaciones registradas',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: ac.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: _contraindicaciones.asMap().entries.map((entry) {
                final index = entry.key;
                final c = entry.value;
                final isAbsoluta =
                    c.tipoContraindicacion == TipoContraindicacion.absoluta;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _contraindicaciones.length - 1 ? 10 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ac.bgPage,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ac.red.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: ac.red.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.block_rounded,
                            size: 15,
                            color: ac.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAbsoluta
                                          ? ac.red
                                          : ac.red.withValues(alpha: 0.60),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _capitalize(c.tipoContraindicacion.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.descripcion,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ac.textPrimary,
                                ),
                              ),
                              if (c.efectosAdversos.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: c.efectosAdversos
                                      .map(
                                        (e) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ac.red.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: ac.red.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            e.name,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ac.red,
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
                        GestureDetector(
                          onTap: () => _showContraindicacionDialog(
                            context,
                            index: index,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: ac.textMuted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                            () => _contraindicaciones.removeAt(index),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                              color: ac.red.withValues(alpha: 0.70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _showContraindicacionDialog(
    BuildContext context, {
    int? index,
  }) async {
    final existing = index != null ? _contraindicaciones[index] : null;
    final result = await showDialog<Contraindicacion>(
      context: context,
      builder: (_) => _ContraindicacionDialog(
        existing: existing,
        medicinaIdReal: widget.medicina?.id,
      ),
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
}

class _FormCard extends StatelessWidget {
  final AppColors ac;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  const _FormCard({
    required this.ac,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider, width: 0.5),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: ac.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final AppColors ac;
  final IconData icon;
  final String label;
  final Widget child;

  const _FormField({
    required this.ac,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: ac.primaryGreen),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: ac.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final AppColors ac;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final Color activeColor;
  final void Function(T) onSelected;

  const _ChipSelector({
    required this.ac,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.activeColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: 0.10) : ac.bgPage,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.50)
                    : ac.divider,
                width: isActive ? 1.0 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) ...[
                  Icon(Icons.check_rounded, size: 12, color: activeColor),
                  const SizedBox(width: 5),
                ],
                Text(
                  labelOf(opt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? activeColor : ac.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ContraindicacionDialog extends StatefulWidget {
  final Contraindicacion? existing;
  final String? medicinaIdReal;

  const _ContraindicacionDialog({this.existing, this.medicinaIdReal});

  @override
  State<_ContraindicacionDialog> createState() =>
      _ContraindicacionDialogState();
}

class _ContraindicacionDialogState extends State<_ContraindicacionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionController;
  late TipoContraindicacion _tipo;
  late Set<EfectoAdverso> _efectosAdversos;

  String? _condicionId;
  List<Condicion> _condicionesDisponibles = [];
  bool _loadingCondiciones = true;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(
      text: widget.existing?.descripcion ?? '',
    );
    _tipo =
        widget.existing?.tipoContraindicacion ?? TipoContraindicacion.relativa;
    _efectosAdversos = Set.from(widget.existing?.efectosAdversos ?? []);

    if (widget.existing != null && widget.existing!.condicionId != 'TODO') {
      _condicionId = widget.existing!.condicionId;
    }

    _cargarCondiciones();
  }

  Future<void> _cargarCondiciones() async {
    try {
      final list = await sl<CondicionRepository>().getCondiciones();
      if (!mounted) return;
      setState(() {
        _condicionesDisponibles = List.from(list);
        _loadingCondiciones = false;

        if (_condicionId == null && _condicionesDisponibles.isNotEmpty) {
          _condicionId = _condicionesDisponibles.first.id;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCondiciones = false);
    }
  }

  Future<Condicion?> _mostrarDialogoNuevaCondicion(BuildContext context) async {
    final ac = context.appColors;
    final nombreCtrl = TextEditingController();
    TipoCondicion tipoSeleccionado = TipoCondicion.fisiologica;
    CategoriaCondicion categoriaSeleccionada = CategoriaCondicion.cronica;
    final formKeyCondicion = GlobalKey<FormState>();
    bool savingCondicion = false;

    return showDialog<Condicion>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ac.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: ac.primaryGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: 16,
                      color: ac.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nueva Condición Médica',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKeyCondicion,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _sharedInputDeco(
                          ac,
                          hint: 'Ej. Diabetes Mellitus',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa el nombre'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TipoCondicion>(
                        initialValue: tipoSeleccionado,
                        decoration: _sharedInputDeco(ac, hint: 'Tipo'),
                        items: TipoCondicion.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => tipoSeleccionado = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CategoriaCondicion>(
                        initialValue: categoriaSeleccionada,
                        decoration: _sharedInputDeco(ac, hint: 'Categoría'),
                        items: CategoriaCondicion.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => categoriaSeleccionada = v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: savingCondicion
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.textSecondary,
                    side: BorderSide(color: ac.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: savingCondicion
                      ? null
                      : () async {
                          if (!formKeyCondicion.currentState!.validate())
                            return;
                          setDialogState(() => savingCondicion = true);

                          try {
                            final borrador = Condicion(
                              nombre: nombreCtrl.text.trim(),
                              tipo: tipoSeleccionado,
                              categoria: categoriaSeleccionada,
                            );

                            final nuevaCondicionGuardada =
                                await sl<CondicionRepository>()
                                    .registrarNuevaCondicion(borrador);

                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx, nuevaCondicionGuardada);
                          } catch (e) {
                            if (!dialogCtx.mounted) return;
                            setDialogState(() => savingCondicion = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al crear condición: $e'),
                              ),
                            );
                          }
                        },
                  child: savingCondicion
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    if (_condicionId == null || _condicionId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una condición médica.'),
        ),
      );
      return;
    }

    final idMedicinaValida =
        (widget.medicinaIdReal != null &&
            widget.medicinaIdReal!.trim().isNotEmpty &&
            widget.medicinaIdReal!.contains('-'))
        ? widget.medicinaIdReal!.trim()
        : '00000000-0000-0000-0000-000000000000';

    Navigator.pop(
      context,
      Contraindicacion(
        id: widget.existing?.id,
        condicionId: _condicionId!,
        medicinaId: idMedicinaValida,
        procedimientoId: null,
        tratamientoId: null,
        descripcion: _descripcionController.text.trim(),
        tipoContraindicacion: _tipo,
        efectosAdversos: _efectosAdversos.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final isEditing = widget.existing != null;

    return Dialog(
      backgroundColor: ac.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ac.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 17,
                          color: ac.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Editar contraindicación'
                              : 'Nueva contraindicación',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ac.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _FormField(
                    ac: ac,
                    icon: Icons.health_and_safety_outlined,
                    label: 'Condición médica *',
                    child: _loadingCondiciones
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey(_condicionId),
                                  value: _condicionId,
                                  decoration: _sharedInputDeco(
                                    ac,
                                    hint: 'Seleccionar condición',
                                  ),
                                  items: _condicionesDisponibles.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(
                                        c.nombre,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                      ? 'Selecciona una condición médica'
                                      : null,
                                  onChanged: (val) =>
                                      setState(() => _condicionId = val),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Tooltip(
                                message: 'Crear nueva condición médica',
                                child: InkWell(
                                  onTap: () async {
                                    final creada =
                                        await _mostrarDialogoNuevaCondicion(
                                          context,
                                        );
                                    if (creada != null && creada.id != null) {
                                      setState(() {
                                        _condicionesDisponibles = [
                                          ..._condicionesDisponibles,
                                          creada,
                                        ];
                                        _condicionId = creada.id;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: ac.primaryGreen.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: ac.primaryGreen.withValues(
                                          alpha: 0.30,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: ac.primaryGreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),

                  _FormField(
                    ac: ac,
                    icon: Icons.notes_rounded,
                    label: 'Descripción *',
                    child: TextFormField(
                      controller: _descripcionController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: _sharedInputDeco(
                        ac,
                        hint:
                            'Ej. No usar en pacientes con insuficiencia renal.',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'La descripción no puede estar vacía'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _FormField(
                    ac: ac,
                    icon: Icons.flag_outlined,
                    label: 'Tipo',
                    child: _ChipSelector<TipoContraindicacion>(
                      ac: ac,
                      options: TipoContraindicacion.values,
                      selected: _tipo,
                      labelOf: (t) => _capitalize(t.name),
                      activeColor: ac.red,
                      onSelected: (t) => setState(() => _tipo = t),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _FormField(
                    ac: ac,
                    icon: Icons.warning_amber_outlined,
                    label: 'Efectos adversos',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: EfectoAdverso.values.map((e) {
                        final selected = _efectosAdversos.contains(e);
                        return GestureDetector(
                          onTap: () => setState(() {
                            selected
                                ? _efectosAdversos.remove(e)
                                : _efectosAdversos.add(e);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? ac.red.withValues(alpha: 0.08)
                                  : ac.bgPage,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: selected
                                    ? ac.red.withValues(alpha: 0.50)
                                    : ac.divider,
                                width: selected ? 1.0 : 0.5,
                              ),
                            ),
                            child: Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selected ? ac.red : ac.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ac.textSecondary,
                          side: BorderSide(color: ac.divider),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: ac.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Text(isEditing ? 'Guardar cambios' : 'Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
