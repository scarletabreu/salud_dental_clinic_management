import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/tarjeta_consulta.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

/// Sección opcional del cierre de consulta: qué consumibles se usaron y en
/// qué cantidad. Alimenta el descuento de stock al finalizar la consulta.
/// No modela receta de insumos por tratamiento (fuera de alcance del plazo).
class SeccionInsumos extends StatefulWidget {
  final List<InsumoUtilizado> insumos;

  const SeccionInsumos({super.key, required this.insumos});

  @override
  State<SeccionInsumos> createState() => _SeccionInsumosState();
}

class _SeccionInsumosState extends State<SeccionInsumos> {
  List<Consumible> _catalogo = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await sl<ConsumibleRepository>().getInventario();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo.where((c) => c.activo).toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregarInsumo() async {
    if (_catalogo.isEmpty) return;
    final resultado = await showDialog<InsumoUtilizado>(
      context: context,
      builder: (dialogCtx) => _DialogoAgregarInsumo(catalogo: _catalogo),
    );

    if (resultado == null || !mounted) return;
    context.read<ConsultaCubit>().agregarInsumo(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return TarjetaConsulta(
      icon: Icons.inventory_2_outlined,
      iconColor: ac.indigo,
      titulo: 'Insumos utilizados',
      subtitulo: 'Opcional: descuenta stock del inventario al finalizar',
      accion: TextButton.icon(
        onPressed: _cargando ? null : _agregarInsumo,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Agregar'),
      ),
      child: widget.insumos.isEmpty
          ? Text(
              _cargando
                  ? 'Cargando catálogo…'
                  : 'Ningún insumo registrado en esta consulta.',
              style: TextStyle(color: ac.textMuted, fontSize: 13),
            )
          : Column(
              children: [
                for (var i = 0; i < widget.insumos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FilaInsumo(
                      insumo: widget.insumos[i],
                      ac: ac,
                      onQuitar: () =>
                          context.read<ConsultaCubit>().quitarInsumo(i),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FilaInsumo extends StatelessWidget {
  const _FilaInsumo({
    required this.insumo,
    required this.ac,
    required this.onQuitar,
  });

  final InsumoUtilizado insumo;
  final AppColors ac;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              insumo.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Text(
            'x${insumo.cantidad}',
            style: TextStyle(
              color: ac.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onQuitar,
            borderRadius: BorderRadius.circular(6),
            child: Icon(Icons.close_rounded, size: 18, color: ac.red),
          ),
        ],
      ),
    );
  }
}

class _DialogoAgregarInsumo extends StatefulWidget {
  const _DialogoAgregarInsumo({required this.catalogo});
  final List<Consumible> catalogo;

  @override
  State<_DialogoAgregarInsumo> createState() => _DialogoAgregarInsumoState();
}

class _DialogoAgregarInsumoState extends State<_DialogoAgregarInsumo> {
  final _cantidadController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  Consumible? _seleccionado;

  @override
  void dispose() {
    // Se dispone aquí, en el ciclo de vida propio del diálogo: Flutter llama
    // a este dispose() cuando el widget realmente sale del árbol, incluida
    // la animación de cierre. Hacerlo manualmente después del `await
    // showDialog` corre esa animación con el controller ya muerto.
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Agregar insumo utilizado',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Consumible>(
              initialValue: _seleccionado,
              decoration: const InputDecoration(
                labelText: 'Consumible *',
                border: OutlineInputBorder(),
              ),
              items: widget.catalogo
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        '${c.nombre} (stock: ${c.stockActual})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _seleccionado = val),
              validator: (val) => val == null ? 'Selecciona uno' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad utilizada *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final cantidad = int.tryParse(v ?? '');
                if (cantidad == null || cantidad <= 0) {
                  return 'Ingresa una cantidad válida';
                }
                if (_seleccionado != null &&
                    cantidad > _seleccionado!.stockActual) {
                  return 'Supera el stock disponible (${_seleccionado!.stockActual})';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                InsumoUtilizado(
                  consumibleId: _seleccionado!.id!,
                  nombre: _seleccionado!.nombre,
                  cantidad: int.parse(_cantidadController.text),
                ),
              );
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}