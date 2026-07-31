import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seleccionar_condicion_sheet.dart';

class FormularioEvaluacion extends StatefulWidget {
  final String pacienteId;
  final String doctorId;
  final String? citaId;

  /// Lo que se anotó al agendar la cita. Solo prellena el campo: el odontólogo
  /// lo corrige o lo amplía antes de iniciar.
  final String? motivoCita;

  const FormularioEvaluacion({
    super.key,
    required this.pacienteId,
    required this.doctorId,
    this.citaId,
    this.motivoCita,
  });

  @override
  State<FormularioEvaluacion> createState() => _FormularioEvaluacionState();
}

class _FormularioEvaluacionState extends State<FormularioEvaluacion> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _condicionController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _sistolicaCtrl = TextEditingController();
  final _diastolicaCtrl = TextEditingController();
  final _pulsoCtrl = TextEditingController();
  final _temperaturaCtrl = TextEditingController();
  final _saturacionCtrl = TextEditingController();
  final _dolorCtrl = TextEditingController();
  // Peso y talla: la dosificación pediátrica depende del peso, así que tiene
  // que poder registrarse aquí y no solo en el expediente.
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();

  /// Texto libre: sigue existiendo como complemento de la anamnesis.
  final List<String> _condiciones = [];

  /// Condiciones de catálogo: son las que participan en contraindicaciones y
  /// alertas desde el primer momento (HFX-CLIN-003).
  final List<CondicionDetectada> _condicionesCatalogo = [];
  List<Condicion> _catalogoCondiciones = const [];

  final List<DocumentoAdjunto> _adjuntos = [];

  /// Lo que la base rechazaría, calculado antes de enviar.
  List<ProblemaSignoVital> _problemasVitales = const [];

  @override
  void initState() {
    super.initState();
    _motivoController.text = widget.motivoCita ?? '';
    for (final ctrl in [
      _sistolicaCtrl,
      _diastolicaCtrl,
      _pulsoCtrl,
      _temperaturaCtrl,
      _saturacionCtrl,
      _dolorCtrl,
      _pesoCtrl,
      _tallaCtrl,
    ]) {
      ctrl.addListener(_revisarSignosVitales);
    }
    _cargarCondiciones();
  }

  Future<void> _cargarCondiciones() async {
    try {
      final catalogo = await sl<CondicionRepository>().getCondiciones();
      if (!mounted) return;
      setState(() => _catalogoCondiciones = catalogo);
    } catch (_) {
      // Sin catálogo el doctor sigue pudiendo anotar en texto libre.
    }
  }

  void _revisarSignosVitales() {
    final problemas = _construirSignosVitales(validando: true).validar();
    if (problemas.length == _problemasVitales.length &&
        problemas
            .map((p) => p.mensaje)
            .join()
            .compareTo(_problemasVitales.map((p) => p.mensaje).join()) ==
            0) {
      return;
    }
    setState(() => _problemasVitales = problemas);
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _condicionController.dispose();
    _descripcionController.dispose();
    _sistolicaCtrl.dispose();
    _diastolicaCtrl.dispose();
    _pulsoCtrl.dispose();
    _temperaturaCtrl.dispose();
    _saturacionCtrl.dispose();
    _dolorCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    super.dispose();
  }

  void _agregarCondicion() {
    final texto = _condicionController.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _condiciones.add(texto);
      _condicionController.clear();
    });
  }

  Future<void> _adjuntarDocumento() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'dcm'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    final desc = _descripcionController.text.trim();
    setState(() {
      _adjuntos.add(
        DocumentoAdjunto(
          bytes: bytes,
          fileName: file.name,
          descripcion: desc.isEmpty ? file.name : desc,
        ),
      );
      _descripcionController.clear();
    });
  }

  SignosVitales _construirSignosVitales({bool validando = false}) =>
      SignosVitales.valores(
        presionSistolica: double.tryParse(_sistolicaCtrl.text.trim()),
        presionDiastolica: double.tryParse(_diastolicaCtrl.text.trim()),
        pulso: double.tryParse(_pulsoCtrl.text.trim()),
        temperatura: double.tryParse(_temperaturaCtrl.text.trim()),
        saturacionO2: double.tryParse(_saturacionCtrl.text.trim()),
        dolor: double.tryParse(_dolorCtrl.text.trim()),
        peso: double.tryParse(_pesoCtrl.text.trim()),
        talla: double.tryParse(_tallaCtrl.text.trim()),
        medidoEn: validando ? null : DateTime.now(),
        medidoPor: validando ? null : widget.doctorId,
      );

  SignosVitales? _buildSignosVitales() {
    final sv = _construirSignosVitales();
    return sv.estaVacia ? null : sv;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    // Un valor imposible no llega al servidor: se corrige aquí, con el nombre
    // del signo y su rango, en vez de morir con un error de base de datos.
    final problemas = _construirSignosVitales(validando: true).validar();
    if (problemas.isNotEmpty) {
      setState(() => _problemasVitales = problemas);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(problemas.first.mensaje),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    context.read<ConsultaCubit>().iniciar(
      pacienteId: widget.pacienteId,
      doctorId: widget.doctorId,
      citaId: widget.citaId,
      motivoConsulta: _motivoController.text.trim(),
      tempCondiciones: _condiciones,
      condicionesDetectadas: _condicionesCatalogo,
      adjuntos: _adjuntos,
      signosVitales: _buildSignosVitales(),
    );
  }

  Future<void> _agregarCondicionCatalogo() async {
    final disponibles = [
      for (final c in _catalogoCondiciones)
        if (!_condicionesCatalogo.any((d) => d.condicionId == c.id)) c,
    ];
    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más condiciones en el catálogo.'),
        ),
      );
      return;
    }
    final elegida = await seleccionarCondicionDetectada(context, disponibles);
    if (elegida == null || !mounted) return;
    setState(() => _condicionesCatalogo.add(elegida));
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        children: [
          _PageHeader(
            title: 'Iniciar consulta',
            subtitle: 'Documenta el motivo y el contexto clínico inicial',
            step: '01',
            ac: ac,
          ),
          const SizedBox(height: 24),

          _FormCard(
            ac: ac,
            icon: Icons.notes_rounded,
            iconColor: ac.primaryGreen,
            title: 'Motivo de consulta',
            subtitle: 'Describe el motivo principal',
            child: TextFormField(
              controller: _motivoController,
              minLines: 3,
              maxLines: 5,
              style: TextStyle(
                fontSize: 14,
                color: ac.textPrimary,
                height: 1.5,
              ),
              decoration: _fieldDecoration(
                ac,
                hint: 'Ej: Dolor en molar superior derecho desde hace 3 días…',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El motivo de consulta es obligatorio'
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          _FormCard(
            ac: ac,
            icon: Icons.medical_information_outlined,
            iconColor: ac.amber,
            title: 'Condiciones detectadas hoy',
            subtitle:
                'Del catálogo, para que cuenten en contraindicaciones y alertas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _agregarCondicionCatalogo,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Agregar condición del catálogo'),
                  ),
                ),
                if (_condicionesCatalogo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._condicionesCatalogo.asMap().entries.map((entrada) {
                    final condicion = entrada.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: ac.amber.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ac.amber.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    condicion.nombre,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: ac.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${condicion.severidad.etiqueta}'
                                    '${condicion.incorporarAlExpediente ? ' · pasa al expediente' : ' · solo esta consulta'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ac.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(
                                () => _condicionesCatalogo.removeAt(
                                  entrada.key,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: ac.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 14),
                Text(
                  'Complemento en texto libre',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ac.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _condicionController,
                        style: TextStyle(fontSize: 14, color: ac.textPrimary),
                        decoration: _fieldDecoration(
                          ac,
                          hint: 'Añade un hallazgo o condición temporal',
                        ),
                        onSubmitted: (_) => _agregarCondicion(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AddButton(onTap: _agregarCondicion, ac: ac),
                  ],
                ),
                if (_condiciones.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _condiciones.map((cond) {
                        return _CondicionChip(
                          label: cond,
                          ac: ac,
                          onDelete: () =>
                              setState(() => _condiciones.remove(cond)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _FormCard(
            ac: ac,
            icon: Icons.attach_file_rounded,
            iconColor: ac.teal,
            title: 'Documentos clínicos',
            subtitle: 'Radiografías u otros archivos de apoyo diagnóstico',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descripcionController,
                        style: TextStyle(fontSize: 14, color: ac.textPrimary),
                        decoration: _fieldDecoration(
                          ac,
                          hint: 'Descripción del documento (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AttachButton(onTap: _adjuntarDocumento, ac: ac),
                  ],
                ),
                if (_adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._adjuntos.map(
                    (adj) => _AdjuntoTile(
                      adj: adj,
                      ac: ac,
                      onRemove: () => setState(() => _adjuntos.remove(adj)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _FormCard(
            ac: ac,
            icon: Icons.monitor_heart_outlined,
            iconColor: ac.red,
            title: 'Signos vitales',
            subtitle:
                'Presión, pulso, temperatura, saturación, dolor, peso y talla',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _campoVital(ac, _sistolicaCtrl, 'PS mmHg')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _campoVital(ac, _diastolicaCtrl, 'PD mmHg'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _campoVital(ac, _pulsoCtrl, 'Pulso lpm')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _campoVital(
                        ac,
                        _temperaturaCtrl,
                        'Temp °C',
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _campoVital(ac, _saturacionCtrl, 'Sat %')),
                    const SizedBox(width: 8),
                    Expanded(child: _campoVital(ac, _dolorCtrl, 'Dolor 0-10')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _campoVital(ac, _pesoCtrl, 'Peso kg', decimal: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _campoVital(ac, _tallaCtrl, 'Talla cm', decimal: true),
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
                if (_problemasVitales.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._problemasVitales.map(
                    (problema) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 15, color: ac.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              problema.mensaje,
                              style: TextStyle(
                                fontSize: 12,
                                color: ac.red,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          BlocBuilder<ConsultaCubit, ConsultaState>(
            builder: (context, state) {
              final cargando = state is ConsultaGuardando;
              return _IniciarButton(
                cargando: cargando,
                onTap: cargando ? null : _guardar,
                ac: ac,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _campoVital(
    AppColors c,
    TextEditingController ctrl,
    String hint, {
    bool decimal = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    inputFormatters: [
      decimal
          ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    decoration: _fieldDecoration(c, hint: hint),
    textAlign: TextAlign.center,
  );

  InputDecoration _fieldDecoration(AppColors ac, {required String hint}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: ac.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: ac.bgPage,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ac.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ac.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ac.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ac.red, width: 1.2),
        ),
      );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.step,
    required this.ac,
  });

  final String title;
  final String subtitle;
  final String step;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ac.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ac.textPrimary,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.ac,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final AppColors ac;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider.withValues(alpha: 0.6), width: 1),
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
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: ac.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.ac});
  final VoidCallback onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ac.primaryGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap, required this.ac});
  final VoidCallback onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ac.teal.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ac.teal.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_outlined, size: 16, color: ac.teal),
            const SizedBox(width: 6),
            Text(
              'Adjuntar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ac.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CondicionChip extends StatelessWidget {
  const _CondicionChip({
    required this.label,
    required this.ac,
    required this.onDelete,
  });
  final String label;
  final AppColors ac;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ac.amber.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: ac.amber),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: Icon(Icons.close_rounded, size: 14, color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AdjuntoTile extends StatelessWidget {
  const _AdjuntoTile({
    required this.adj,
    required this.ac,
    required this.onRemove,
  });
  final DocumentoAdjunto adj;
  final AppColors ac;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ac.teal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ac.teal.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 18, color: ac.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adj.descripcion,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                    ),
                  ),
                  Text(
                    adj.fileName,
                    style: TextStyle(fontSize: 11, color: ac.textMuted),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: ac.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IniciarButton extends StatelessWidget {
  const _IniciarButton({
    required this.cargando,
    required this.onTap,
    required this.ac,
  });
  final bool cargando;
  final VoidCallback? onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: ac.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        icon: cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_circle_outline_rounded, size: 20),
        label: Text(
          cargando ? 'Abriendo consulta…' : 'Continuar con la consulta',
        ),
      ),
    );
  }
}
