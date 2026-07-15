import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';

class CuentaCard extends StatelessWidget {
  final Cuenta cuenta;
  final VoidCallback? onEliminar;

  const CuentaCard({super.key, required this.cuenta, this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final currFmt = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');

    final estado = _estadoDeCuenta(cuenta);
    final (statusColor, statusLabel, statusIcon) = _statusInfo(estado, ac);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consulta #${cuenta.consultaId.length > 8 ? cuenta.consultaId.substring(0, 8) : cuenta.consultaId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFmt.format(cuenta.fechaCreacion),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: ac.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MontoItem(
                  label: 'Total',
                  value: currFmt.format(cuenta.montoTotal),
                  color: ac.textPrimary,
                  ac: ac,
                ),
              ),
              Expanded(
                child: _MontoItem(
                  label: 'Pagado',
                  value: currFmt.format(cuenta.montoPagado),
                  color: ac.green,
                  ac: ac,
                ),
              ),
              Expanded(
                child: _MontoItem(
                  label: 'Balance',
                  value: currFmt.format(cuenta.balancePendiente),
                  color: cuenta.estaPagada ? ac.green : ac.red,
                  ac: ac,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ac.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cuenta.metodoPago.name == 'Crédito'
                          ? Icons.credit_card_rounded
                          : Icons.payments_outlined,
                      size: 12,
                      color: ac.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cuenta.metodoPago.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              if (cuenta.nota != null && cuenta.nota!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cuenta.nota!,
                    style: TextStyle(fontSize: 11, color: ac.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (onEliminar != null)
                IconButton(
                  onPressed: onEliminar,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: ac.textSecondary.withValues(alpha: 0.5),
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Eliminar cuenta',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static EstadoCuenta _estadoDeCuenta(Cuenta c) {
    if (c.estaPagada) return EstadoCuenta.saldada;
    if (c.montoPagado > 0) return EstadoCuenta.pendiente;
    return EstadoCuenta.abierta;
  }

  static (Color, String, IconData) _statusInfo(
    EstadoCuenta estado,
    AppColors ac,
  ) {
    return switch (estado) {
      EstadoCuenta.saldada => (
        ac.green,
        'Saldada',
        Icons.check_circle_outline_rounded,
      ),
      EstadoCuenta.pendiente => (ac.amber, 'Pendiente', Icons.schedule_rounded),
      EstadoCuenta.cancelada => (
        ac.textSecondary,
        'Cancelada',
        Icons.cancel_outlined,
      ),
      EstadoCuenta.abierta => (ac.red, 'Sin pago', Icons.receipt_long_outlined),
    };
  }
}

class _MontoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppColors ac;

  const _MontoItem({
    required this.label,
    required this.value,
    required this.color,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ac.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
