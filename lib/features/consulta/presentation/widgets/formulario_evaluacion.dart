import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';

/// Formulario de evaluación clínica: motivo, condiciones temporales y adjuntar
/// documentos (radiografías). Al guardar invoca el [ConsultaCubit].
class FormularioEvaluacion extends StatefulWidget {
  final String pacienteId;
  final String doctorId;
  final String? citaId;

  const FormularioEvaluacion({
    super.key,
    required this.pacienteId,
    required this.doctorId,
    this.citaId,
  });

  @override
  State<FormularioEvaluacion> createState() => _FormularioEvaluacionState();
}

class _FormularioEvaluacionState extends State<FormularioEvaluacion> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _condicionController = TextEditingController();
  final _descripcionController = TextEditingController();

  final List<String> _condiciones = [];
  final List<DocumentoAdjunto> _adjuntos = [];

  @override
  void dispose() {
    _motivoController.dispose();
    _condicionController.dispose();
    _descripcionController.dispose();
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

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ConsultaCubit>().crearConsulta(
      pacienteId: widget.pacienteId,
      doctorId: widget.doctorId,
      citaId: widget.citaId,
      motivoConsulta: _motivoController.text.trim(),
      tempCondiciones: _condiciones,
      adjuntos: _adjuntos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            'Evaluación clínica',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 24),
          _label(c, 'Motivo de consulta'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivoController,
            minLines: 2,
            maxLines: 4,
            decoration: _dec(c, 'Describe el motivo principal de la consulta'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El motivo de consulta es obligatorio'
                : null,
          ),
          const SizedBox(height: 24),
          _label(c, 'Condiciones temporales'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _condicionController,
                  decoration: _dec(c, 'Añade un hallazgo o condición temporal'),
                  onSubmitted: (_) => _agregarCondicion(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _agregarCondicion,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: c.primaryBlue),
              ),
            ],
          ),
          if (_condiciones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _condiciones
                  .map(
                    (cond) => Chip(
                      label: Text(cond),
                      onDeleted: () => setState(() => _condiciones.remove(cond)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          _label(c, 'Documentos clínicos (radiografías)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descripcionController,
                  decoration: _dec(c, 'Descripción del documento (opcional)'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _adjuntarDocumento,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Adjuntar'),
              ),
            ],
          ),
          ..._adjuntos.map(
            (adj) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.description_outlined, color: c.teal),
              title: Text(
                adj.descripcion,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                adj.fileName,
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18, color: c.textMuted),
                onPressed: () => setState(() => _adjuntos.remove(adj)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          BlocBuilder<ConsultaCubit, ConsultaState>(
            builder: (context, state) {
              final cargando = state is ConsultaLoading;
              return SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: cargando ? null : _guardar,
                  style: FilledButton.styleFrom(backgroundColor: c.primaryBlue),
                  child: cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Iniciar consulta'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors c, String text) => Text(
    text,
    style: TextStyle(
      color: c.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _dec(AppColors c, String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: c.searchFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
