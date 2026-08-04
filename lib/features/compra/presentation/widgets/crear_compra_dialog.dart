import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_state.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_cubit.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_state.dart';

Future<void> mostrarDialogoCrearCompra(BuildContext context) async {
  final ac = context.appColors;

  context.read<InventarioCubit>().cargar();
  context.read<SuplidorCubit>().cargar();

  final compraCubit = context.read<CompraCubit>();
  final inventarioCubit = context.read<InventarioCubit>();
  final suplidorCubit = context.read<SuplidorCubit>();

  final List<ConsumibleCompraModel> itemsCompra = [];
  final Map<String, String> nombresConsumibles = {};

  Suplidor? suplidorSeleccionado;
  Consumible? consumibleSeleccionado;
  final cantidadController = TextEditingController(text: '1');
  final precioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (dialogCtx) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: compraCubit),
        BlocProvider.value(value: inventarioCubit),
        BlocProvider.value(value: suplidorCubit),
      ],
      child: StatefulBuilder(
        builder: (context, setState) {
          final inventarioState = context.watch<InventarioCubit>().state;
          final suplidorState = context.watch<SuplidorCubit>().state;

          final List<Consumible> consumibles =
              inventarioState is InventarioLoaded
              ? inventarioState.consumibles
              : [];

          final List<Suplidor> suplidores = suplidorState is SuplidorLoaded
              ? suplidorState.suplidores
              : [];

          final double totalOrden = itemsCompra.fold(
            0,
            (sum, i) => sum + (i.precioUnitario * i.cantidad),
          );

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: ac.cardBg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ac.primaryGreen.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                color: ac.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registrar Nueva Compra',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: ac.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Selecciona el suplidor e insumos a reabastecer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ac.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: ac.divider),
                        const SizedBox(height: 16),

                        Text(
                          '1. Seleccionar Suplidor / Proveedor',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ac.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<Suplidor>(
                          initialValue: suplidorSeleccionado,
                          decoration: InputDecoration(
                            hintText: 'Seleccionar proveedor de la orden...',
                            prefixIcon: const Icon(
                              Icons.local_shipping_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: suplidores.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              suplidorSeleccionado = val;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        Text(
                          '2. Agregar Artículos a la Compra',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ac.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<Consumible>(
                          initialValue: consumibleSeleccionado,
                          decoration: InputDecoration(
                            hintText: 'Seleccionar consumible...',
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: consumibles.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.nombre} (Stock: ${c.stockActual})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              consumibleSeleccionado = val;
                              if (val != null) {
                                precioController.text = val.precio
                                    .toStringAsFixed(2);

                                if (suplidorSeleccionado == null &&
                                    val.suplidorId != null) {
                                  suplidorSeleccionado = suplidores
                                      .where((s) => s.id == val.suplidorId)
                                      .firstOrNull;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: cantidadController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Cantidad *',
                                  prefixIcon: const Icon(
                                    Icons.numbers_rounded,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: precioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Precio Unitario (RD\$) *',
                                  prefixIcon: const Icon(
                                    Icons.attach_money_rounded,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: ac.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (consumibleSeleccionado == null) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selecciona un consumible primero.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final cant =
                                    int.tryParse(cantidadController.text) ?? 0;
                                final prec =
                                    double.tryParse(
                                      precioController.text.replaceAll(
                                        ',',
                                        '.',
                                      ),
                                    ) ??
                                    0;

                                if (cant <= 0 || prec <= 0) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ingresa una cantidad y precio válidos.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  final item = ConsumibleCompraModel(
                                    compraId: '',
                                    consumibleId: consumibleSeleccionado!.id!,
                                    suplidorId:
                                        suplidorSeleccionado?.id ??
                                        consumibleSeleccionado!.suplidorId ??
                                        '',
                                    cantidad: cant,
                                    precioUnitario: prec,
                                  );

                                  itemsCompra.add(item);
                                  nombresConsumibles[consumibleSeleccionado!
                                          .id!] =
                                      consumibleSeleccionado!.nombre;

                                  consumibleSeleccionado = null;
                                  cantidadController.text = '1';
                                  precioController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (itemsCompra.isNotEmpty) ...[
                          Text(
                            'Detalle de la Orden (${itemsCompra.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ac.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: itemsCompra.length,
                              separatorBuilder: (_, _) =>
                                  Divider(height: 1, color: ac.divider),
                              itemBuilder: (context, index) {
                                final item = itemsCompra[index];
                                final totalItem =
                                    item.cantidad * item.precioUnitario;
                                final nombre =
                                    nombresConsumibles[item.consumibleId] ??
                                    'Artículo ${item.consumibleId.substring(0, 6)}';

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${item.cantidad} x RD\$ ${item.precioUnitario.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: ac.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'RD\$ ${totalItem.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: ac.red,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => itemsCompra.removeAt(index),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total de la Compra:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ac.textSecondary,
                                ),
                              ),
                              Text(
                                'RD\$ ${totalOrden.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ac.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Registrar Compra'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ac.primaryGreen,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: itemsCompra.isEmpty
                                  ? null
                                  : () async {
                                      final nuevaCompra = CompraModel(
                                        fecha: DateTime.now(),
                                        items: itemsCompra,
                                        estado: EstadoCompra.pendiente,
                                      );

                                      await compraCubit.registrarCompra(
                                        nuevaCompra,
                                      );
                                      if (dialogCtx.mounted) {
                                        Navigator.pop(dialogCtx);
                                      }
                                    },
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
        },
      ),
    ),
  );

  cantidadController.dispose();
  precioController.dispose();
}
