import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/pages/resumen_cierre_page.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

class CajaDiariaPage extends StatefulWidget {
  const CajaDiariaPage({super.key});

  @override
  State<CajaDiariaPage> createState() => _CajaDiariaPageState();
}

class _CajaDiariaPageState extends State<CajaDiariaPage> {
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    context.read<CajaDiariaCubit>().cargar();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarApertura() async {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.parse(_montoController.text.replaceAll(',', '.'));
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar apertura'),
        content: Text(
          'Abrirás la caja de hoy con ${formatMoneda(monto)} como fondo inicial. Podrás registrar los movimientos del día a continuación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primaryBlue,
            ),
            child: const Text('Abrir caja'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _abriendo = true);
    final error = await context.read<CajaDiariaCubit>().abrirCaja(monto);
    if (!mounted) return;
    setState(() => _abriendo = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.bgPage,
      body: SafeArea(
        child: BlocBuilder<CajaDiariaCubit, CajaDiariaState>(
          builder: (context, state) => switch (state) {
            CajaDiariaLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CajaDiariaSinAbrir() => _AperturaView(
              formKey: _formKey,
              montoController: _montoController,
              abriendo: _abriendo,
              error: state.error,
              onConfirmar: _confirmarApertura,
            ),
            CajaDiariaAbierta() => _CajaAbiertaView(state: state),
            CajaDiariaError() => _ErrorView(
              mensaje: state.mensaje,
              onRetry: () => context.read<CajaDiariaCubit>().cargar(),
            ),
          },
        ),
      ),
    );
  }
}

class _AperturaView extends StatelessWidget {
  const _AperturaView({
    required this.formKey,
    required this.montoController,
    required this.abriendo,
    required this.error,
    required this.onConfirmar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController montoController;
  final bool abriendo;
  final String? error;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.appLayout.isCompact ? 12 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: EdgeInsets.all(context.appLayout.isNarrow ? 18 : 32),
            decoration: BoxDecoration(
              color: ac.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [ac.cardShadow],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: ac.teal.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.lock_open_rounded, color: ac.teal),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Inicia la operación del día',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Abre la caja antes de recibir pagos o registrar movimientos. El fondo inicial quedará incluido en el balance esperado.',
                    style: TextStyle(color: ac.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Fondo inicial',
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('monto-apertura'),
                    controller: montoController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,.]?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      prefixText: 'RD\$  ',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final monto = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (monto == null || monto < 0) {
                        return 'Escribe un monto válido.';
                      }
                      return null;
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: TextStyle(color: ac.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: abriendo ? null : onConfirmar,
                      icon: abriendo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_rounded),
                      label: Text(
                        abriendo ? 'Abriendo caja...' : 'Abrir caja de hoy',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CajaAbiertaView extends StatefulWidget {
  const _CajaAbiertaView({required this.state});

  final CajaDiariaAbierta state;

  @override
  State<_CajaAbiertaView> createState() => _CajaAbiertaViewState();
}

class _CajaAbiertaViewState extends State<_CajaAbiertaView> {
  bool _cerrando = false;

  Future<void> _mostrarDialogoRegistrarEgreso(BuildContext context) async {
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ac = context.appColors;

    final registrado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: ac.orange.withValues(alpha: 0.12),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: ac.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Registrar egreso',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ac.bgPage,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ac.divider.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Efectivo disponible:',
                        style: TextStyle(color: ac.textSecondary, fontSize: 13),
                      ),
                      Text(
                        formatMoneda(widget.state.montoEsperado),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ac.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto a retirar *',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un monto mayor a cero.';
                    }
                    if (parsed > widget.state.montoEsperado) {
                      return 'El monto supera el disponible en caja.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del gasto *',
                    hintText: 'Ej. Compra de agua, botiquín, transporte...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ac.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogCtx, true);
              }
            },
            child: const Text('Registrar egreso'),
          ),
        ],
      ),
    );

    if (registrado != true || !mounted) return;

    final monto = double.parse(montoController.text.replaceAll(',', '.'));
    final descripcion = descripcionController.text;

    final error = await context.read<CajaDiariaCubit>().registrarEgreso(
      monto: monto,
      descripcion: descripcion,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: ac.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Egreso registrado correctamente por ${formatMoneda(monto)}.',
          ),
          backgroundColor: ac.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _mostrarDialogoCierre(BuildContext context) async {
    final montoController = TextEditingController(
      text: widget.state.montoEsperado.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar caja del día'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto esperado en caja: ${formatMoneda(widget.state.montoEsperado)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text('Ingresa el monto contado físicamente en caja:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[,.]?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  prefixText: 'RD\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un monto válido.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.red,
            ),
            child: const Text('Confirmar y Cerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final montoContado = double.parse(
      montoController.text.replaceAll(',', '.'),
    );
    final cubit = context.read<CajaDiariaCubit>();
    final resumen = cubit.obtenerResumenCierre();

    if (resumen == null) return;

    setState(() => _cerrando = true);
    final error = await cubit.cerrarCaja(montoReal: montoContado);

    if (!mounted) return;
    setState(() => _cerrando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      final diferencia = BalanceCaja.diferencia(
        montoReal: montoContado,
        montoEsperado: resumen.montoEsperado,
      );
      final fechaCierre = DateTime.now();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReporteCierrePage(
            resumen: resumen,
            montoContado: montoContado,
            diferencia: diferencia,
            fechaCierre: fechaCierre,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return RefreshIndicator(
      onRefresh: () => context.read<CajaDiariaCubit>().cargar(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caja de hoy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fechaLargaEs(DateTime.now().toLocal()),
                    style: TextStyle(color: ac.textSecondary),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ac.green.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: ac.green),
                        const SizedBox(width: 7),
                        Text(
                          'ABIERTA',
                          style: TextStyle(
                            color: ac.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarDialogoRegistrarEgreso(context),
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: ac.orange,
                      size: 18,
                    ),
                    label: Text(
                      'Registrar egreso',
                      style: TextStyle(color: ac.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ac.orange.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _cerrando
                        ? null
                        : () => _mostrarDialogoCierre(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: _cerrando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_outlined, size: 18),
                    label: Text(_cerrando ? 'Cerrando...' : 'Cerrar caja'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 550
                  ? 2
                  : 1;
              final gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _MetricCard(
                    width: width,
                    label: 'Apertura',
                    value: formatMoneda(widget.state.caja.montoApertura),
                    icon: Icons.lock_open_rounded,
                    color: ac.primaryBlue,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'Ingresos',
                    value: formatMoneda(widget.state.ingresos),
                    icon: Icons.arrow_downward_rounded,
                    color: ac.green,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'Egresos',
                    value: formatMoneda(widget.state.egresos),
                    icon: Icons.arrow_upward_rounded,
                    color: ac.orange,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'Esperado',
                    value: formatMoneda(widget.state.montoEsperado),
                    icon: Icons.account_balance_wallet_rounded,
                    color: ac.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                'Movimientos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Se actualiza automáticamente',
                style: TextStyle(color: ac.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.state.movimientos.isEmpty)
            _EmptyMovements(ac: ac)
          else
            Container(
              decoration: BoxDecoration(
                color: ac.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [ac.cardShadow],
              ),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < widget.state.movimientos.length;
                    index++
                  ) ...[
                    _MovementRow(movimiento: widget.state.movimientos[index]),
                    if (index != widget.state.movimientos.length - 1)
                      Divider(height: 1, color: ac.divider),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.appColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [context.appColors.cardShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.35,
          ),
        ),
      ],
    ),
  );
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movimiento});
  final MovimientoCaja movimiento;
  @override
  Widget build(BuildContext context) {
    final isIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    final color = isIngreso
        ? context.appColors.green
        : context.appColors.orange;
    final hora =
        '${movimiento.fecha.toLocal().hour.toString().padLeft(2, '0')}:${movimiento.fecha.toLocal().minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(
          isIngreso ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        movimiento.descripcion,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${movimiento.tipo.displayName} · $hora'),
      trailing: Text(
        '${isIngreso ? '+' : '-'}${formatMoneda(movimiento.monto)}',
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements({required this.ac});
  final AppColors ac;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
    decoration: BoxDecoration(
      color: ac.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ac.divider),
    ),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 34, color: ac.textMuted),
        const SizedBox(height: 10),
        const Text(
          'Aún no hay movimientos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Los cobros y egresos registrados hoy aparecerán aquí.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ac.textSecondary),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});
  final String mensaje;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 40),
        const SizedBox(height: 12),
        Text(mensaje),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
