import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cierre_caja_cubit.dart';
import '../cubit/cierre_caja_state.dart';
import 'reporte_cierre_page.dart';

class CierreCajaPage extends StatelessWidget {
  const CierreCajaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<CierreCajaCubit>()..cargarResumen(),
      child: const _CierreCajaView(),
    );
  }
}

class _CierreCajaView extends StatefulWidget {
  const _CierreCajaView();

  @override
  State<_CierreCajaView> createState() => _CierreCajaViewState();
}

class _CierreCajaViewState extends State<_CierreCajaView> {
  final _conteoController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void dispose() {
    _conteoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de caja')),
      body: BlocConsumer<CierreCajaCubit, CierreCajaState>(
        listener: (context, state) {
          if (state is CierreCajaError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.mensaje)));
          }
          if (state is CierreCajaExito) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ReporteCierrePage(
                  resumen: state.resumen,
                  montoContado: state.montoContado,
                  diferencia: state.diferencia,
                  fechaCierre: state.fechaCierre,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CierreCajaLoading || state is CierreCajaInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! CierreCajaResumenCargado &&
              state is! CierreCajaConfirmando) {
            return const Center(child: Text('No se pudo cargar la caja.'));
          }

          final resumenState = state is CierreCajaResumenCargado
              ? state
              : context.read<CierreCajaCubit>().state
                    as CierreCajaResumenCargado;

          final confirmando = state is CierreCajaConfirmando;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tarjetaMonto(
                  label: 'Monto esperado (calculado)',
                  monto: resumenState.resumen.montoEsperado,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _conteoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Conteo físico (RD\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calculate_outlined),
                  ),
                  onChanged: (value) {
                    final monto = double.tryParse(value) ?? 0;
                    context.read<CierreCajaCubit>().actualizarConteo(monto);
                  },
                ),
                const SizedBox(height: 16),
                _tarjetaDiferencia(resumenState),
                const SizedBox(height: 16),
                TextField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: confirmando
                      ? null
                      : () => _confirmarCierre(context, resumenState),
                  icon: confirmando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(confirmando ? 'Cerrando...' : 'Confirmar cierre'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaMonto({required String label, required double monto}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            'RD\$ ${monto.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDiferencia(CierreCajaResumenCargado state) {
    final cuadra = state.diferencia == 0;
    final color = cuadra ? Colors.green : Colors.red;
    final texto = cuadra
        ? 'Cuadra'
        : state.esFaltante
        ? 'Faltante de RD\$ ${state.diferencia.abs().toStringAsFixed(2)}'
        : 'Sobrante de RD\$ ${state.diferencia.abs().toStringAsFixed(2)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            cuadra ? Icons.check_circle : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCierre(
    BuildContext context,
    CierreCajaResumenCargado state,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cierre de caja'),
        content: Text(
          state.hayDescuadre
              ? 'Hay un descuadre de RD\$ ${state.diferencia.abs().toStringAsFixed(2)}. '
                    '¿Deseas cerrar la caja de todos modos?'
              : '¿Confirmas el cierre de caja del día?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      context.read<CierreCajaCubit>().confirmarCierre(
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );
    }
  }
}
