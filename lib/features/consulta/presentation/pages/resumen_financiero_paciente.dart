import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/historial_financiero_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/historial_financiero_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';

class ResumenFinancieroPaciente extends StatelessWidget {
  final String pacienteId;
  final void Function(Cuenta cuenta)? onVerDetalle;

  const ResumenFinancieroPaciente({
    super.key,
    required this.pacienteId,
    this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HistorialFinancieroCubit>()..cargar(pacienteId),
      child: _ResumenFinancieroView(onVerDetalle: onVerDetalle),
    );
  }
}

class _ResumenFinancieroView extends StatelessWidget {
  final void Function(Cuenta cuenta)? onVerDetalle;

  const _ResumenFinancieroView({this.onVerDetalle});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocBuilder<HistorialFinancieroCubit, HistorialFinancieroState>(
      builder: (context, state) {
        return _Seccion(
          titulo: 'Resumen financiero',
          icono: Icons.payments_rounded,
          colorIcono: ac.green,
          child: switch (state) {
            HistorialFinancieroLoading() => _buildLoading(ac),
            HistorialFinancieroError(:final message) => _buildError(
              context,
              ac,
              message,
            ),
            HistorialFinancieroLoaded() => _buildLoaded(context, ac, state),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Widget _buildLoading(AppColors ac) {
    return SizedBox(
      height: 80,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: ac.primaryBlue),
      ),
    );
  }

  Widget _buildError(BuildContext context, AppColors ac, String message) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, color: ac.red, size: 32),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(color: ac.red, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            // El BlocProvider está arriba, pero no tenemos el pacienteId aquí.
            // El padre (ResumenFinancieroPaciente) debe reconstruirse.
            // En la práctica se usa con un key para forzar rebuild si hace falta.
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AppColors ac,
    HistorialFinancieroLoaded state,
  ) {
    if (state.cuentas.isEmpty) {
      return _buildVacio(ac);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarjetasResumen(state: state),
        const SizedBox(height: 16),

        if (state.tieneDeuda) ...[
          _BannerDeuda(monto: state.totalPendiente),
          const SizedBox(height: 16),
        ],

        Text(
          'Historial de cuentas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ac.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),

        ...state.cuentas.map(
          (cuenta) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FilaCuenta(
              cuenta: cuenta,
              onTap: onVerDetalle != null ? () => onVerDetalle!(cuenta) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVacio(AppColors ac) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          'Este paciente no tiene cuentas registradas.',
          style: TextStyle(color: ac.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _TarjetasResumen extends StatelessWidget {
  final HistorialFinancieroLoaded state;

  const _TarjetasResumen({required this.state});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final currFmt = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);

    final tarjetas = [
      (
        label: 'Total facturado',
        value: currFmt.format(state.totalFacturado),
        color: ac.primaryBlue,
        icon: Icons.receipt_long_rounded,
      ),
      (
        label: 'Total cobrado',
        value: currFmt.format(state.totalCobrado),
        color: ac.green,
        icon: Icons.check_circle_outline_rounded,
      ),
      (
        label: 'Balance pendiente',
        value: currFmt.format(state.totalPendiente),
        color: state.tieneDeuda ? ac.red : ac.green,
        icon: state.tieneDeuda
            ? Icons.pending_actions_rounded
            : Icons.done_all_rounded,
      ),
    ];

    if (isNarrow) {
      return Column(
        children: tarjetas
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TarjetaStat(
                  label: t.label,
                  value: t.value,
                  color: t.color,
                  icon: t.icon,
                ),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: tarjetas
          .map(
            (t) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: t == tarjetas.last ? 0 : 10),
                child: _TarjetaStat(
                  label: t.label,
                  value: t.value,
                  color: t.color,
                  icon: t.icon,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TarjetaStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TarjetaStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ac.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerDeuda extends StatelessWidget {
  final double monto;

  const _BannerDeuda({required this.monto});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final currFmt = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ac.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: ac.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: ac.textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Este paciente tiene un balance pendiente de ',
                  ),
                  TextSpan(
                    text: currFmt.format(monto),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ac.red,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCuenta extends StatelessWidget {
  final Cuenta cuenta;
  final VoidCallback? onTap;

  const _FilaCuenta({required this.cuenta, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final currFmt = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final estado = cuenta.estado;
    final (statusColor, statusLabel) = _statusInfo(estado, ac);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ac.chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ac.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconEstado(estado), color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFmt.format(cuenta.fechaCreacion),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cuenta.metodoPago.name,
                      style: TextStyle(fontSize: 11, color: ac.textMuted),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currFmt.format(cuenta.montoTotal),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (cuenta.estado != EstadoCuenta.saldada)
                    Text(
                      '${currFmt.format(cuenta.balancePendiente)} pend.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),

              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ac.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static (Color, String) _statusInfo(EstadoCuenta estado, AppColors ac) {
    return switch (estado) {
      EstadoCuenta.saldada => (ac.green, 'Saldada'),
      EstadoCuenta.pendiente => (ac.amber, 'Pendiente'),
      EstadoCuenta.cancelada => (ac.textSecondary, 'Cancelada'),
      EstadoCuenta.abierta => (ac.red, 'Sin pago'),
    };
  }

  static IconData _iconEstado(EstadoCuenta estado) {
    return switch (estado) {
      EstadoCuenta.saldada => Icons.check_circle_outline_rounded,
      EstadoCuenta.pendiente => Icons.schedule_rounded,
      EstadoCuenta.cancelada => Icons.cancel_outlined,
      EstadoCuenta.abierta => Icons.receipt_long_outlined,
    };
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final Widget child;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icono, size: 17, color: colorIcono),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
