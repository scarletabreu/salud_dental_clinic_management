import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/contraindicacion_dialog.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/receta_item_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seleccionar_medicina_sheet.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/usecases/verificar_contraindicaciones_usecase.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

/// Sección "Receta" del workspace de consulta: buscador de medicinas,
/// verificación de contraindicaciones (mismo diálogo de HOTFIX-5) y lista
/// editable de ítems en memoria vía ConsultaCubit.
class SeccionReceta extends StatefulWidget {
  final List<Condicion> condicionesPaciente;
  final List<Receta> recetas;

  const SeccionReceta({
    super.key,
    required this.condicionesPaciente,
    required this.recetas,
  });

  @override
  State<SeccionReceta> createState() => _SeccionRecetaState();
}

class _SeccionRecetaState extends State<SeccionReceta> {
  List<Medicina> _catalogo = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await sl<IMedicinaRepository>().getCatalogoMedicinas();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _onAgregarMedicina() async {
    if (_cargando) return;
    final consultaCubit = context.read<ConsultaCubit>();
    final medicina = await seleccionarMedicina(context, _catalogo);
    if (medicina == null || !mounted) return;

    final conflictos = const VerificarContraindicacionesUseCase().callMedicina(
      condicionesPaciente: widget.condicionesPaciente,
      medicina: medicina,
    );

    String? justificacion;
    if (conflictos.isNotEmpty) {
      justificacion = await mostrarContraindicacionDialog(
        context,
        medicina.nombre,
        conflictos,
      );
      if (justificacion == null || !mounted) return;
    }

    if (!mounted) return;
    final receta = await mostrarRecetaItemFormDialog(
      context,
      medicina,
      justificacionClinica: justificacion,
    );
    if (receta == null || !mounted) return;

    consultaCubit.agregarItemReceta(receta);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${medicina.nombre}" agregada a la receta.'),
        backgroundColor: context.appColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onQuitar(int index) async {
    final ac = context.appColors;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitar de la receta'),
        content: Text(
          '¿Quitar "${widget.recetas[index].title}" de la receta?',
          style: TextStyle(color: ac.textSecondary, fontSize: 13, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ac.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    context.read<ConsultaCubit>().quitarItemReceta(index);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider.withValues(alpha: 0.6)),
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
                  color: ac.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 17,
                  color: ac.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Medicinas recetadas en esta consulta',
                      style: TextStyle(fontSize: 11, color: ac.textMuted),
                    ),
                  ],
                ),
              ),
              if (_cargando)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ac.primaryBlue,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _onAgregarMedicina,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar medicina'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          if (widget.recetas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no se han agregado medicinas a la receta.',
                style: TextStyle(color: ac.textMuted, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < widget.recetas.length; i++)
                  _tarjetaItem(context, widget.recetas[i], i),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tarjetaItem(BuildContext context, Receta receta, int index) {
    final ac = context.appColors;
    return Container(
      margin: EdgeInsets.only(
        bottom: index == widget.recetas.length - 1 ? 0 : 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_rounded, size: 18, color: ac.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  receta.title,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Quitar',
                icon: Icon(Icons.close_rounded, size: 18, color: ac.textMuted),
                onPressed: () => _onQuitar(index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pildora(ac, 'Dosis', receta.dosis),
              _pildora(ac, 'Frecuencia', receta.frecuencia),
              _pildora(ac, 'Duración', receta.duracion),
            ],
          ),
          if (receta.indicaciones.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              receta.indicaciones.trim(),
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          if ((receta.notas ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: ac.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    receta.notas!.trim(),
                    style: TextStyle(
                      color: ac.amber,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pildora(AppColors ac, String label, String valor) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ac.divider),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: ac.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: valor.trim(),
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
