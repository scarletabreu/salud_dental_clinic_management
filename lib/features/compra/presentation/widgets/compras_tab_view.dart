import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_cubit.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_state.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/pages/recepcion_compra_page.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/widgets/crear_compra_dialog.dart';

class ComprasTabView extends StatefulWidget {
  const ComprasTabView({super.key});

  @override
  State<ComprasTabView> createState() => _ComprasTabViewState();
}

class _ComprasTabViewState extends State<ComprasTabView> {
  @override
  void initState() {
    super.initState();
    context.read<CompraCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Padding(
      padding: context.pageInsets(top: 16, bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Órdenes de Compra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gestión de pedidos a suplidores y recepción de inventario',
                      style: TextStyle(fontSize: 12, color: ac.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => mostrarDialogoCrearCompra(context),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Nueva Compra'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: BlocBuilder<CompraCubit, CompraState>(
              builder: (context, state) {
                if (state is CompraLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CompraError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: ac.red,
                        ),
                        const SizedBox(height: 12),
                        Text(state.mensaje),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.read<CompraCubit>().cargar(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CompraLoaded) {
                  final items = state.comprasFiltradas;

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: ac.textMuted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay compras registradas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usa el botón "Nueva Compra" para registrar una orden de reabastecimiento.',
                            style: TextStyle(fontSize: 12, color: ac.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final compra = items[index];
                      final esPendiente =
                          compra.estado != EstadoCompra.recibido &&
                          compra.estado != EstadoCompra.cancelado;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ac.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ac.divider.withValues(alpha: 0.5),
                            width: 0.6,
                          ),
                          boxShadow: [ac.cardShadow],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: ac.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                color: ac.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Orden #${compra.id?.substring(0, 8) ?? '---'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'RD\$ ${compra.precioTotal.toStringAsFixed(2)} · ${compra.items.length} artículos',
                                    style: TextStyle(
                                      color: ac.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (esPendiente)
                              FilledButton.icon(
                                icon: const Icon(Icons.input_rounded, size: 16),
                                label: const Text('Recibir'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ac.green,
                                ),
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<CompraCubit>(),
                                        child: RecepcionCompraPage(
                                          compra: compra,
                                        ),
                                      ),
                                    ),
                                  );

                                  if (res == true && context.mounted) {
                                    context.read<CajaDiariaCubit>().cargar();
                                  }
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (compra.estado == EstadoCompra.recibido
                                              ? ac.green
                                              : ac.red)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  compra.estado.name.toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        compra.estado == EstadoCompra.recibido
                                        ? ac.green
                                        : ac.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
