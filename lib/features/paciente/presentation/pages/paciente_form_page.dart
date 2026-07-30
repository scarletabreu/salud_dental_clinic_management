import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/paciente_avatar.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/recorte_foto_dialog.dart';
import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

// Importación condicional del helper web si se ejecuta en navegador
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/camera_web_helper.dart'
    if (dart.library.io) 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/camera_web_stub.dart';

enum PacienteFormModo { editar, completarRegistro }

class _CedulaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3) buffer.write('-');
      if (i == 10) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  }) : telefono = TextEditingController(text: telefonoInitial),
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

  ContactoModel toModel({bool esEmergencia = false}) => ContactoModel(
    id: originalId,
    numeroTelefono: telefono.text.trim(),
    email: email.text.trim(),
    direccion: direccion.text.trim(),
    esEmergencia: esEmergencia,
  );

  void dispose() {
    telefono.dispose();
    email.dispose();
    direccion.dispose();
  }
}

class PacienteFormPage extends StatefulWidget {
  final Paciente paciente;
  final PacienteFormModo modo;
  final VoidCallback? onCompletado;

  const PacienteFormPage({
    super.key,
    required this.paciente,
    this.modo = PacienteFormModo.editar,
    this.onCompletado,
  });

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
  late final TextEditingController _pesoController;
  late final TextEditingController _alturaController;
  late final TextEditingController _historialFamiliarController;
  late final TextEditingController _cantHijosController;
  late final List<_ContactoEntry> _contactos;

  DateTime? _fechaNacimiento;
  Genero _genero = Genero.masculino;
  TipoPaciente _tipoPaciente = TipoPaciente.integrado;

  List<Condicion> _condicionesIniciales = [];
  List<Condicion> _condicionesSeleccionadas = [];
  List<Condicion> _condicionesDisponibles = [];
  bool _cargandoCondiciones = true;
  bool _guardandoCondiciones = false;
  bool _isProcessingSave = false;

  Uint8List? _fotoPendiente;
  bool _eliminarFotoPendiente = false;
  bool _procesandoFoto = false;

  bool get _isCompletarRegistro =>
      widget.modo == PacienteFormModo.completarRegistro;

  @override
  void initState() {
    super.initState();
    final p = widget.paciente;
    _nombreController = TextEditingController(text: p.nombre);
    _apellidoController = TextEditingController(text: p.apellido);
    _cedulaController = TextEditingController(text: p.govID);
    _trabajoController = TextEditingController(text: p.trabajo);
    _referenciaController = TextEditingController(text: p.referencia);
    _pesoController = TextEditingController(
      text: p.peso != null ? p.peso.toString() : '',
    );
    _alturaController = TextEditingController(
      text: p.altura != null ? p.altura.toString() : '',
    );
    _historialFamiliarController = TextEditingController(
      text: p.record.historialFamiliar,
    );
    _cantHijosController = TextEditingController(
      text: p.record.cantHijos.toString(),
    );
    _fechaNacimiento = p.birthDate;
    _genero = p.genero;
    _tipoPaciente = p.tipoPaciente;
    _contactos = p.contactos.isEmpty
        ? [_ContactoEntry(isExpanded: true)]
        : p.contactos
              .asMap()
              .entries
              .map(
                (e) => _ContactoEntry.fromContacto(
                  e.value,
                  isExpanded: e.key == 0,
                ),
              )
              .toList();

    _cargarCondiciones();
  }

  Future<void> _cargarCondiciones() async {
    try {
      final results = await Future.wait([
        sl<RecordRepository>().getCondicionesDelPaciente(widget.paciente.id!),
        sl<CondicionRepository>().getCondiciones(),
      ]);
      if (!mounted) return;
      setState(() {
        _condicionesIniciales = results[0];
        _condicionesSeleccionadas = List.of(results[0]);
        _condicionesDisponibles = results[1];
        _cargandoCondiciones = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoCondiciones = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _trabajoController.dispose();
    _referenciaController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _historialFamiliarController.dispose();
    _cantHijosController.dispose();
    for (final c in _contactos) {
      c.dispose();
    }
    super.dispose();
  }

  static const int _maxFotoBytes = 10 * 1024 * 1024;

  void _addContacto() {
    setState(() {
      for (final c in _contactos) {
        c.isExpanded = false;
      }
      _contactos.add(_ContactoEntry(isExpanded: true));
    });
  }

  void _removeContacto(int index) {
    final removed = _contactos.removeAt(index);
    setState(() {
      if (_contactos.isNotEmpty && _contactos.every((c) => !c.isExpanded)) {
        _contactos.first.isExpanded = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _toggleContacto(int index) {
    setState(() {
      final nowExpanded = !_contactos[index].isExpanded;
      for (final c in _contactos) {
        c.isExpanded = false;
      }
      _contactos[index].isExpanded = nowExpanded;
    });
  }

  void _toggleCondicion(Condicion condicion, bool selected) {
    setState(() {
      if (selected) {
        _condicionesSeleccionadas = [..._condicionesSeleccionadas, condicion];
      } else {
        _condicionesSeleccionadas = _condicionesSeleccionadas
            .where((c) => c.id != condicion.id)
            .toList();
      }
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _fechaNacimiento == null) {
      if (_fechaNacimiento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar la fecha de nacimiento.'),
          ),
        );
      }
      return;
    }

    if (_contactos.isEmpty || _contactos.first.telefono.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar el teléfono del contacto principal.'),
        ),
      );
      return;
    }

    final pacienteId = widget.paciente.id;

    final recordActualizado = widget.paciente.record.copyWith(
      historialFamiliar: _historialFamiliarController.text.trim(),
      cantHijos: int.tryParse(_cantHijosController.text.trim()) ?? 0,
    );

    final paciente = Paciente(
      id: pacienteId,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      birthDate: _fechaNacimiento!,
      govID: _cedulaController.text.trim(),
      contactos: _contactos
          .asMap()
          .entries
          .map((e) => e.value.toModel(esEmergencia: e.key > 0))
          .toList(),
      estatus: widget.paciente.estatus,
      genero: _genero,
      tipoPaciente: _tipoPaciente,
      trabajo: _trabajoController.text.trim(),
      referencia: _referenciaController.text.trim(),
      peso: double.tryParse(_pesoController.text.trim()),
      altura: double.tryParse(_alturaController.text.trim()),
      record: recordActualizado,
      citas: widget.paciente.citas,
      fotoRuta: widget.paciente.fotoRuta,
      fotoMimeType: widget.paciente.fotoMimeType,
      fotoTamanoBytes: widget.paciente.fotoTamanoBytes,
      fotoActualizadaEn: widget.paciente.fotoActualizadaEn,
    );

    context.read<PacienteCubit>().updatePaciente(paciente);
  }

  Future<void> _guardarDiffCondiciones() async {
    final idsIniciales = _condicionesIniciales.map((c) => c.id).toSet();
    final idsFinales = _condicionesSeleccionadas.map((c) => c.id).toSet();
    final agregadas = idsFinales.difference(idsIniciales);
    final quitadas = idsIniciales.difference(idsFinales);

    if (agregadas.isEmpty && quitadas.isEmpty) return;

    final pacienteId = widget.paciente.id;
    if (pacienteId == null) return;

    setState(() => _guardandoCondiciones = true);
    final recordRepo = sl<RecordRepository>();
    try {
      for (final id in agregadas) {
        await recordRepo.agregarCondicion(pacienteId, id!);
      }
      for (final id in quitadas) {
        await recordRepo.quitarCondicion(pacienteId, id!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.red,
            content: const Text('Error al actualizar condiciones médicas.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoCondiciones = false);
    }
  }

  Future<void> _onPacienteGuardadoExitosamente() async {
    if (_isProcessingSave) return;
    _isProcessingSave = true;

    try {
      if (!await _guardarFotoPendiente() || !mounted) return;
      await _guardarDiffCondiciones();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.appColors.teal,
          content: Text(
            _isCompletarRegistro
                ? 'Ficha clínica completada'
                : 'Paciente actualizado exitosamente',
          ),
        ),
      );

      if (_isCompletarRegistro) {
        widget.onCompletado?.call();
      } else {
        Navigator.pop(context);
      }
    } finally {
      _isProcessingSave = false;
    }
  }

  Future<bool> _guardarFotoPendiente() async {
    final pacienteId = widget.paciente.id;
    if (pacienteId == null ||
        (_fotoPendiente == null && !_eliminarFotoPendiente)) {
      return true;
    }

    setState(() => _procesandoFoto = true);
    try {
      final storage = sl<PacienteFotoStorage>();
      if (_fotoPendiente != null) {
        await storage.guardar(pacienteId: pacienteId, bytes: _fotoPendiente!);
      } else if (_eliminarFotoPendiente && widget.paciente.fotoRuta != null) {
        await storage.eliminar(
          pacienteId: pacienteId,
          ruta: widget.paciente.fotoRuta!,
        );
      }
      if (mounted) await context.read<PacienteCubit>().load();
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.appColors.red,
          content: Text('No se pudo guardar la fotografía: $error'),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _procesandoFoto = false);
    }
    return true;
  }

  bool get _soportaCamara =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _elegirFoto() async {
    ImageSource? source = ImageSource.gallery;
    if (_soportaCamara) {
      if (kIsWeb) {
        final Uint8List? fotoCapturada = await mostrarDialogoCamaraWeb(context);
        if (fotoCapturada != null) {
          setState(() {
            _fotoPendiente = fotoCapturada;
            _eliminarFotoPendiente = false;
          });
        }
        return;
      }

      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar fotografía'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null || !mounted) return;

    setState(() => _procesandoFoto = true);
    try {
      final storage = sl<PacienteFotoStorage>();
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();

      if (bytes.length > _maxFotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.amber,
            content: const Text(
              'La imagen seleccionada es muy pesada. Debe pesar menos de 10 MB.',
            ),
          ),
        );
        return;
      }

      final decodificada = storage.decodificar(bytes);
      if (!mounted) return;
      final optimizada = await RecorteFotoDialog.mostrar(
        context,
        imagen: decodificada,
        storage: storage,
      );
      if (optimizada == null) return;
      if (mounted) {
        setState(() {
          _fotoPendiente = optimizada;
          _eliminarFotoPendiente = false;
        });
      }
    } on FormatoFotoInvalido catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.red,
            content: Text(error.message),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.red,
            content: Text('No se pudo preparar la fotografía: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesandoFoto = false);
    }
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return BlocConsumer<PacienteCubit, PacienteState>(
      listener: (context, state) {
        if (state is PacienteError) {
          _isProcessingSave = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: ac.red, content: Text(state.message)),
          );
        }
        if (state is PacienteOperationSuccess) {
          _onPacienteGuardadoExitosamente();
        }
      },
      builder: (context, state) {
        final isSaving =
            state is PacienteLoading ||
            _guardandoCondiciones ||
            _isProcessingSave;

        return Scaffold(
          backgroundColor: ac.bgPage,
          appBar: _buildAppBar(ac, isSaving),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isCompletarRegistro) ...[
                    _buildAvisoCompletarRegistro(ac),
                    const SizedBox(height: 16),
                  ],
                  _buildFotoCard(ac),
                  const SizedBox(height: 16),
                  _buildDatosPersonalesCard(ac),
                  const SizedBox(height: 16),
                  _buildContactosCard(ac),
                  const SizedBox(height: 16),
                  _buildInfoAdicionalCard(ac),
                  const SizedBox(height: 16),
                  _buildHistorialFamiliarCard(ac),
                  const SizedBox(height: 16),
                  _buildCondicionesCard(ac),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFotoCard(AppColors ac) {
    final hasCurrent =
        widget.paciente.fotoRuta != null && !_eliminarFotoPendiente;
    return _FormCard(
      ac: ac,
      iconColor: ac.primaryGreen,
      iconBg: ac.primaryGreen.withValues(alpha: 0.10),
      icon: Icons.account_circle_outlined,
      title: 'Fotografía de identificación',
      child: Row(
        children: [
          if (_fotoPendiente != null)
            ClipOval(
              child: Image.memory(
                _fotoPendiente!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            )
          else
            PacienteAvatar(
              paciente: widget.paciente,
              size: 88,
              forzarIniciales: !hasCurrent,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _procesandoFoto
                      ? 'Preparando imagen…'
                      : 'JPG, PNG o WebP · máximo 10 MB',
                  style: TextStyle(fontSize: 12, color: ac.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _procesandoFoto ? null : _elegirFoto,
                      icon: const Icon(
                        Icons.photo_camera_back_outlined,
                        size: 16,
                      ),
                      label: Text(
                        hasCurrent || _fotoPendiente != null
                            ? 'Reemplazar'
                            : 'Agregar foto',
                      ),
                    ),
                    if (hasCurrent || _fotoPendiente != null)
                      TextButton.icon(
                        onPressed: _procesandoFoto
                            ? null
                            : () => setState(() {
                                _fotoPendiente = null;
                                _eliminarFotoPendiente =
                                    widget.paciente.fotoRuta != null;
                              }),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Quitar'),
                        style: TextButton.styleFrom(foregroundColor: ac.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoCompletarRegistro(AppColors ac) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: ac.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Completa la ficha clínica del paciente para habilitar consultas.',
              style: TextStyle(fontSize: 12.5, color: ac.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColors ac, bool isSaving) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        color: ac.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              if (!_isCompletarRegistro)
                GestureDetector(
                  onTap: isSaving ? null : () => Navigator.pop(context),
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
              if (!_isCompletarRegistro) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isCompletarRegistro
                          ? 'Completar ficha clínica'
                          : 'Editar paciente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : _save,
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatosPersonalesCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.primaryGreen,
      iconBg: ac.primaryGreen.withValues(alpha: 0.10),
      icon: Icons.person_outline_rounded,
      title: 'Datos personales',
      child: Column(
        children: [
          const SizedBox(height: 18),
          AppFormRow(
            children: [
              _FormField(
                ac: ac,
                icon: Icons.badge_outlined,
                label: 'Nombre *',
                child: TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDeco(ac, hint: 'Ana'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nombre obligatorio'
                      : null,
                ),
              ),
              _FormField(
                ac: ac,
                icon: Icons.badge_outlined,
                label: 'Apellido *',
                child: TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDeco(ac, hint: 'García'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Apellido obligatorio'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.credit_card_outlined,
            label: 'Cédula *',
            child: TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [_CedulaInputFormatter()],
              decoration: _inputDeco(ac, hint: '000-0000000-0'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Cédula obligatoria';
                if (v.replaceAll('-', '').length != 11) {
                  return 'Debe tener 11 dígitos';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha de nacimiento *',
            child: GestureDetector(
              onTap: _pickFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ac.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ac.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: ac.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fechaNacimiento != null
                          ? _formatDate(_fechaNacimiento!)
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        fontSize: 13,
                        color: _fechaNacimiento != null
                            ? ac.textPrimary
                            : ac.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.wc_outlined,
            label: 'Género',
            child: _ChipSelector<Genero>(
              ac: ac,
              options: Genero.values,
              selected: _genero,
              labelOf: (g) => g.label,
              activeColor: ac.primaryGreen,
              onSelected: (g) => setState(() => _genero = g),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactosCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.teal,
      iconBg: ac.teal.withValues(alpha: 0.10),
      icon: Icons.phone_outlined,
      title: 'Contactos',
      action: TextButton.icon(
        onPressed: _addContacto,
        icon: Icon(Icons.add_rounded, size: 16, color: ac.primaryGreen),
        label: Text(
          'Agregar',
          style: TextStyle(fontSize: 12, color: ac.primaryGreen),
        ),
      ),
      child: Column(
        children: List.generate(
          _contactos.length,
          (i) => Padding(
            padding: EdgeInsets.only(
              bottom: i < _contactos.length - 1 ? 12 : 0,
            ),
            child: _buildContactoCard(ac, i),
          ),
        ),
      ),
    );
  }

  Widget _buildContactoCard(AppColors ac, int index) {
    final entry = _contactos[index];
    final isFirst = index == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleContacto(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    isFirst ? Icons.phone : Icons.contact_emergency,
                    size: 16,
                    color: isFirst ? ac.primaryGreen : ac.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isFirst
                          ? 'Contacto principal *'
                          : 'Contacto de emergencia #$index',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFirst ? ac.textPrimary : ac.red,
                      ),
                    ),
                  ),
                  if (!isFirst)
                    GestureDetector(
                      onTap: () => _removeContacto(index),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: ac.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: entry.isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(height: 16, color: ac.divider),
                  _FormField(
                    ac: ac,
                    icon: Icons.phone_outlined,
                    label: isFirst ? 'Teléfono *' : 'Teléfono de emergencia *',
                    child: TextFormField(
                      controller: entry.telefono,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDeco(ac, hint: '809-000-0000'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    ac: ac,
                    icon: Icons.email_outlined,
                    label: 'Correo electrónico',
                    child: TextFormField(
                      controller: entry.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDeco(ac, hint: 'correo@ejemplo.com'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    ac: ac,
                    icon: Icons.home_outlined,
                    label: 'Dirección',
                    child: TextFormField(
                      controller: entry.direccion,
                      maxLines: 2,
                      decoration: _inputDeco(ac, hint: 'Calle, ciudad…'),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAdicionalCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: const Color(0xFF534AB7),
      iconBg: const Color(0xFFEEEDFE),
      icon: Icons.info_outline_rounded,
      title: 'Información adicional',
      child: Column(
        children: [
          _FormField(
            ac: ac,
            icon: Icons.category_outlined,
            label: 'Tipo de paciente',
            child: _ChipSelector<TipoPaciente>(
              ac: ac,
              options: TipoPaciente.values,
              selected: _tipoPaciente,
              labelOf: (t) => t.label,
              activeColor: ac.teal,
              onSelected: (t) => setState(() => _tipoPaciente = t),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  ac: ac,
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso (kg)',
                  child: TextFormField(
                    controller: _pesoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDeco(ac, hint: 'Ej. 70.5'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  ac: ac,
                  icon: Icons.height_rounded,
                  label: 'Altura (cm)',
                  child: TextFormField(
                    controller: _alturaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDeco(ac, hint: 'Ej. 170'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.work_outline_rounded,
            label: 'Ocupación',
            child: TextFormField(
              controller: _trabajoController,
              decoration: _inputDeco(ac, hint: 'Ej. Ingeniero, estudiante...'),
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.share_outlined,
            label: 'Referencia',
            child: TextFormField(
              controller: _referenciaController,
              decoration: _inputDeco(ac, hint: '¿Cómo nos conoció?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialFamiliarCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.indigo,
      iconBg: ac.indigo.withValues(alpha: 0.10),
      icon: Icons.family_restroom_outlined,
      title: 'Antecedentes y contexto familiar',
      child: Column(
        children: [
          _FormField(
            ac: ac,
            icon: Icons.child_care_outlined,
            label: 'Cantidad de Hijos',
            child: TextFormField(
              controller: _cantHijosController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDeco(ac, hint: '0'),
            ),
          ),
          const SizedBox(height: 14),
          _FormField(
            ac: ac,
            icon: Icons.notes_outlined,
            label: 'Historial / Antecedentes Familiares',
            child: TextFormField(
              controller: _historialFamiliarController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(
                ac,
                hint: 'Ej. Padre con hipertensión, antecedentes de diabetes...',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCondicionesCard(AppColors ac) {
    return _FormCard(
      ac: ac,
      iconColor: ac.red,
      iconBg: ac.red.withValues(alpha: 0.10),
      icon: Icons.health_and_safety_outlined,
      title: 'Condiciones médicas generales',
      child: _cargandoCondiciones
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _condicionesDisponibles.isEmpty
          ? Text(
              'Sin catálogo de condiciones.',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _condicionesDisponibles.map((c) {
                final isActive = _condicionesSeleccionadas.any(
                  (s) => s.id == c.id,
                );
                return FilterChip(
                  label: Text(c.nombre),
                  selected: isActive,
                  onSelected: (v) => _toggleCondicion(c, v),
                  selectedColor: ac.red.withValues(alpha: 0.12),
                  checkmarkColor: ac.red,
                  backgroundColor: ac.bgPage,
                  labelStyle: TextStyle(
                    color: isActive ? ac.red : ac.textSecondary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
    );
  }

  InputDecoration _inputDeco(
    AppColors ac, {
    String? hint,
    bool alignLabelWithHint = false,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    filled: true,
    fillColor: ac.bgPage,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.divider, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.primaryGreen, width: 1.0),
    ),
    alignLabelWithHint: alignLabelWithHint,
  );
}

class _FormCard extends StatelessWidget {
  final AppColors ac;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? action;

  const _FormCard({
    required this.ac,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.child,
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
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ac.textMuted,
                ),
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
            child: Text(
              labelOf(opt),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? activeColor : ac.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
