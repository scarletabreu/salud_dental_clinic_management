import 'dart:io';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
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
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

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

  String get resumen {
    final tel = telefono.text.trim();
    final mail = email.text.trim();
    if (tel.isNotEmpty) return tel;
    if (mail.isNotEmpty) return mail;
    return 'Nuevo contacto';
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
  XFile? _fotoFile;
  Uint8List? _fotoBytesWeb;
  bool _fotoEliminada = false;

  List<Condicion> _condicionesIniciales = [];
  List<Condicion> _condicionesSeleccionadas = [];
  List<Condicion> _condicionesDisponibles = [];
  bool _cargandoCondiciones = true;
  bool _guardandoCondiciones = false;
  bool _isProcessingSave = false;

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

  Future<Uint8List?> _mostrarDialogoCamaraWeb(BuildContext context) async {
    final ac = context.appColors;
    final viewType = 'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

    web.HTMLVideoElement videoElement = web.HTMLVideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => videoElement,
    );

    web.MediaStream? stream;

    try {
      final mediaDevices = web.window.navigator.mediaDevices;
      final constraints = web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      );

      final mediaStreamPromise = mediaDevices.getUserMedia(constraints);
      stream = await mediaStreamPromise.toDart;
      videoElement.srcObject = stream;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ac.red,
          content: const Text(
            'No se pudo acceder a la cámara. Por favor permite el acceso en los permisos del navegador.',
          ),
        ),
      );
      return null;
    }

    Uint8List? fotoCapturadaBytes;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: ac.cardBg,
          title: Text(
            'Capturar fotografía',
            style: TextStyle(color: ac.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: HtmlElementView(viewType: viewType),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                stream?.getTracks().toDart.forEach((track) {
                  (track as web.MediaStreamTrack).stop();
                });
                Navigator.pop(dialogCtx);
              },
              child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
              icon: const Icon(Icons.camera_rounded, size: 18),
              label: const Text('Tirar foto'),
              onPressed: () {
                final canvas = web.HTMLCanvasElement()
                  ..width = videoElement.videoWidth
                  ..height = videoElement.videoHeight;

                final ctx = canvas.context2D;
                ctx.drawImage(videoElement, 0, 0);

                final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
                final base64String = dataUrl.split(',').last;
                fotoCapturadaBytes = Uri.parse(dataUrl).data?.contentAsBytes();

                // Detener la cámara
                stream?.getTracks().toDart.forEach((track) {
                  (track as web.MediaStreamTrack).stop();
                });

                Navigator.pop(dialogCtx);
              },
            ),
          ],
        );
      },
    );

    return fotoCapturadaBytes;
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

  Future<void> _mostrarOpcionesFoto() async {
    final picker = ImagePicker();
    final ac = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: ac.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ac.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fotografía del paciente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ac.primaryGreen.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: ac.primaryGreen,
                    ),
                  ),
                  title: Text(
                    'Tomar fotografía',
                    style: TextStyle(color: ac.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);

                    if (kIsWeb) {
                      final Uint8List? fotoCapturada =
                          await _mostrarDialogoCamaraWeb(context);
                      if (fotoCapturada != null) {
                        setState(() {
                          _fotoBytesWeb = fotoCapturada;
                          _fotoFile = XFile.fromData(
                            fotoCapturada,
                            name: 'foto_paciente.jpg',
                          );
                          _fotoEliminada = false;
                        });
                      }
                    } else {
                      try {
                        final picked = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          _procesarFotoSeleccionada(picked);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: ac.red,
                            content: Text('Error al abrir cámara: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ac.teal.withValues(alpha: 0.12),
                    child: Icon(Icons.photo_library_rounded, color: ac.teal),
                  ),
                  title: Text(
                    'Elegir de la galería',
                    style: TextStyle(color: ac.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1000,
                      );
                      if (picked != null) _procesarFotoSeleccionada(picked);
                    } catch (_) {}
                  },
                ),
                if (_fotoFile != null ||
                    (widget.paciente.fotoRuta != null && !_fotoEliminada))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ac.red.withValues(alpha: 0.12),
                      child: Icon(Icons.delete_outline_rounded, color: ac.red),
                    ),
                    title: Text('Quitar foto', style: TextStyle(color: ac.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _fotoFile = null;
                        _fotoBytesWeb = null;
                        _fotoEliminada = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const int _maxFotoBytes = 10 * 1024 * 1024;

  Future<void> _procesarFotoSeleccionada(XFile picked) async {
    final bytes = await picked.readAsBytes();

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

    setState(() {
      _fotoFile = picked;
      _fotoBytesWeb = bytes;
      _fotoEliminada = false;
    });
  }

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

    final bytesFoto =
        _fotoBytesWeb ??
        (_fotoFile != null ? await _fotoFile!.readAsBytes() : null);

    final pacienteId = widget.paciente.id;

    String? fotoRutaFinal = widget.paciente.fotoRuta;
    String? fotoMimeTypeFinal = widget.paciente.fotoMimeType;
    int? fotoTamanoBytesFinal = widget.paciente.fotoTamanoBytes;
    DateTime? fotoActualizadaEnFinal = widget.paciente.fotoActualizadaEn;

    if (_fotoEliminada) {
      fotoRutaFinal = null;
      fotoMimeTypeFinal = null;
      fotoTamanoBytesFinal = null;
      fotoActualizadaEnFinal = null;
    } else if (_fotoFile != null && bytesFoto != null) {
      fotoRutaFinal = '${pacienteId ?? 'nuevo'}/perfil.jpg';
      fotoMimeTypeFinal = 'image/jpeg';
      fotoTamanoBytesFinal = bytesFoto.length;
      fotoActualizadaEnFinal = DateTime.now();
    }

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
      fotoRuta: fotoRutaFinal,
      fotoMimeType: fotoMimeTypeFinal,
      fotoTamanoBytes: fotoTamanoBytesFinal,
      fotoActualizadaEn: fotoActualizadaEnFinal,
    );

    context.read<PacienteCubit>().updatePaciente(
      paciente,
      fotoBytes: bytesFoto,
    );
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
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ac.bgPage,
                      border: Border.all(
                        color: ac.primaryGreen.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      image: _buildAvatarDecorationImage(),
                    ),
                    child:
                        (_fotoFile == null &&
                            (_fotoEliminada ||
                                widget.paciente.fotoRuta == null ||
                                widget.paciente.fotoRuta!.isEmpty))
                        ? Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: ac.textMuted,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _mostrarOpcionesFoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ac.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: ac.cardBg, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  DecorationImage? _buildAvatarDecorationImage() {
    if (_fotoBytesWeb != null) {
      return DecorationImage(
        image: MemoryImage(_fotoBytesWeb!),
        fit: BoxFit.cover,
      );
    }
    if (_fotoFile != null && !kIsWeb) {
      return DecorationImage(
        image: FileImage(File(_fotoFile!.path)),
        fit: BoxFit.cover,
      );
    }
    if (!_fotoEliminada &&
        widget.paciente.fotoRuta != null &&
        widget.paciente.fotoRuta!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(widget.paciente.fotoRuta!),
        fit: BoxFit.cover,
      );
    }
    return null;
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
