import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_cubit.dart';

class RecepcionCompraPage extends StatefulWidget {
  final Compra compra;

  const RecepcionCompraPage({super.key, required this.compra});

  @override
  State<RecepcionCompraPage> createState() => _RecepcionCompraPageState();
}

class _RecepcionCompraPageState extends State<RecepcionCompraPage> {
  bool _procesando = false;

  Future<void> _confirmarRecepcion() async {
    setState(() => _procesando = true);

    final authState = context.read<AuthCubit>().state;
    final usuarioId = authState.usuario?.id;

    if (usuarioId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión no válida.')));
      setState(() => _procesando = false);
      return;
    }

    final error = await context.read<CompraCubit>().recibirCompra(
      compraId: widget.compra.id!,
      usuarioId: usuarioId,
    );

    if (!mounted) return;
    setState(() => _procesando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      try {
        context.read<CajaDiariaCubit>().cargar();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compra recibida correctamente e inventario/caja actualizados.',
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Recepción de Compra #${widget.compra.id?.substring(0, 8)}',
        ),
        backgroundColor: ac.cardBg,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ac.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ac.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: ac.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Impacto Financiero e Inventario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ac.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Al procesar la recepción, se debitará RD\$ ${widget.compra.precioTotal.toStringAsFixed(2)} de la caja abierta y se incrementará el stock de cada consumible.',
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
              ),
              const SizedBox(height: 20),

              Text(
                'Artículos a recibir (${widget.compra.items.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: ac.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.compra.items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: ac.divider),
                  itemBuilder: (context, i) {
                    final item = widget.compra.items[i];
                    return ListTile(
                      title: Text(
                        'Consumible ID: ${item.consumibleId.substring(0, 8)}...',
                      ),
                      subtitle: Text(
                        'RD\$ ${item.precioUnitario.toStringAsFixed(2)} c/u',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ac.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${item.cantidad} unids.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ac.primaryBlue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _procesando ? null : _confirmarRecepcion,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _procesando ? 'Procesando...' : 'Marcar como Recibida',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
