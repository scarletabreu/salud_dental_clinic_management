import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/widgets/plan_cuotas_panel.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/presentation/pages/recibo_pago_page.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/pages/resumen_plan_page.dart';

class PreFacturaPage extends StatelessWidget {
  final String cuentaId;

  const PreFacturaPage({super.key, required this.cuentaId});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocProvider(
      create: (_) => sl<PreFacturaCubit>()..cargar(cuentaId),
      child: Scaffold(
        backgroundColor: ac.bgPage,
        appBar: AppBar(
          title: const Text(
            'Detalle de Cuenta',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: ac.cardBg,
          foregroundColor: ac.textPrimary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: ac.divider),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: BlocBuilder<PreFacturaCubit, PreFacturaState>(
              builder: (context, state) => switch (state) {
                PreFacturaCargada(
                  :final cuenta,
                  :final cuotas,
                  :final consulta,
                  :final paciente,
                  :final errorDatosRecibo,
                ) =>
                  _Contenido(
                    cuenta: cuenta,
                    cuotas: cuotas,
                    consulta: consulta,
                    paciente: paciente,
                    errorDatosRecibo: errorDatosRecibo,
                  ),
                PreFacturaError(:final mensaje) => _EstadoError(
                  mensaje: mensaje,
                  onReintentar: () =>
                      context.read<PreFacturaCubit>().recargar(cuentaId),
                ),
                _ => _EstadoCargando(ac: ac),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados de Carga y Error
// ---------------------------------------------------------------------------

class _EstadoCargando extends StatelessWidget {
  final AppColors ac;
  const _EstadoCargando({required this.ac});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5, color: ac.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Cargando detalles de la cuenta...',
            style: TextStyle(color: ac.textMuted, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ac.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, color: ac.red, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: ac.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: ac.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido Principal
// ---------------------------------------------------------------------------

class _Contenido extends StatefulWidget {
  final Cuenta cuenta;
  final List<Cuota> cuotas;
  final Consulta? consulta;
  final Paciente? paciente;
  final String? errorDatosRecibo;

  const _Contenido({
    required this.cuenta,
    required this.cuotas,
    required this.consulta,
    required this.paciente,
    required this.errorDatosRecibo,
  });

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  late MetodoPago _modalidad;

  @override
  void initState() {
    super.initState();
    _modalidad = widget.cuenta.metodoPago;
  }

  @override
  void didUpdateWidget(covariant _Contenido oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cuenta.metodoPago != widget.cuenta.metodoPago) {
      _modalidad = widget.cuenta.metodoPago;
    }
  }

  Cuenta get cuenta => widget.cuenta;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _HeaderEstado(cuenta: cuenta, paciente: widget.paciente),
        const SizedBox(height: 16),
        _ResumenKpis(cuenta: cuenta),
        const SizedBox(height: 16),
        _SelectorModalidad(
          seleccionada: _modalidad,
          onChanged: (m) => setState(() => _modalidad = m),
        ),
        const SizedBox(height: 16),
        _Desglose(items: cuenta.itemCuentas),
        const SizedBox(height: 16),
        if (cuenta.pagos.isNotEmpty) ...[
          _HistorialPagos(
            cuenta: cuenta,
            consulta: widget.consulta,
            paciente: widget.paciente,
            errorDatosRecibo: widget.errorDatosRecibo,
          ),
          const SizedBox(height: 16),
        ],
        if (_modalidad == MetodoPago.credito || widget.cuotas.isNotEmpty) ...[
          PlanCuotasPanel(
            cuotas: widget.cuotas,
            onConfigurar: () => _mostrarDialogoPlan(context, cuenta),
            onPagar: (cuota) =>
                _mostrarDialogoPago(context, cuenta, cuota: cuota),
          ),
          const SizedBox(height: 16),
        ],
        _Acciones(
          cuenta: cuenta,
          cuotas: widget.cuotas,
          pacienteId: widget.paciente?.id,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header Hero
// ---------------------------------------------------------------------------

class _HeaderEstado extends StatelessWidget {
  final Cuenta cuenta;
  final Paciente? paciente;

  const _HeaderEstado({required this.cuenta, this.paciente});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (color, label, icon) = _infoEstado(cuenta.estado, ac);
    final consultaCorta = cuenta.consultaId.length > 8
        ? cuenta.consultaId.substring(0, 8).toUpperCase()
        : cuenta.consultaId.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap y no Row: con el texto ampliado la insignia de estado
                // no cabe al lado del nombre y debe bajar de línea.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      paciente != null
                          ? paciente!.fullName
                          : 'Consulta #$consultaCorta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta #$consultaCorta · ${fechaLargaEs(cuenta.fechaCreacion)}',
                  style: TextStyle(color: ac.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas KPIs Financieras
// ---------------------------------------------------------------------------

class _ResumenKpis extends StatelessWidget {
  final Cuenta cuenta;
  const _ResumenKpis({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final esSaldada = cuenta.estado == EstadoCuenta.saldada;

    return LayoutBuilder(
      builder: (context, constraints) {
        final estrecho = constraints.maxWidth < 500;
        final items = [
          _KpiCard(
            etiqueta: 'TOTAL CUENTA',
            monto: formatMoneda(cuenta.montoTotal),
            color: ac.textPrimary,
            icono: Icons.receipt_long_rounded,
          ),
          _KpiCard(
            etiqueta: 'PAGADO',
            monto: formatMoneda(cuenta.montoPagado),
            color: ac.green,
            icono: Icons.check_circle_rounded,
          ),
          _KpiCard(
            etiqueta: 'PENDIENTE',
            monto: formatMoneda(cuenta.balancePendiente),
            color: esSaldada ? ac.green : ac.red,
            icono: esSaldada
                ? Icons.verified_rounded
                : Icons.pending_actions_rounded,
            destacado: !esSaldada,
          ),
        ];

        if (estrecho) {
          return Column(
            children: items
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: i,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: items
              .map(
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: i,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String etiqueta;
  final String monto;
  final Color color;
  final IconData icono;
  final bool destacado;

  const _KpiCard({
    required this.etiqueta,
    required this.monto,
    required this.color,
    required this.icono,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: destacado ? color.withValues(alpha: 0.05) : ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destacado ? color.withValues(alpha: 0.3) : ac.divider,
          width: destacado ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ac.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              monto,
              style: TextStyle(
                color: color,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selector de Modalidad
// ---------------------------------------------------------------------------

class _SelectorModalidad extends StatelessWidget {
  final MetodoPago seleccionada;
  final ValueChanged<MetodoPago> onChanged;

  const _SelectorModalidad({
    required this.seleccionada,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSeccion(
            titulo: 'Modalidad de Pago',
            icono: Icons.tune_rounded,
            color: context.appColors.indigo,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _OpcionModalidad(
                metodo: MetodoPago.contado,
                subtitulo: 'Pago único de contado',
                icono: Icons.payments_outlined,
                activa: seleccionada == MetodoPago.contado,
                onTap: () => onChanged(MetodoPago.contado),
              ),
              const SizedBox(width: 12),
              _OpcionModalidad(
                metodo: MetodoPago.credito,
                subtitulo: 'Plan por cuotas',
                icono: Icons.credit_card_rounded,
                activa: seleccionada == MetodoPago.credito,
                onTap: () => onChanged(MetodoPago.credito),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcionModalidad extends StatelessWidget {
  final MetodoPago metodo;
  final String subtitulo;
  final IconData icono;
  final bool activa;
  final VoidCallback onTap;

  const _OpcionModalidad({
    required this.metodo,
    required this.subtitulo,
    required this.icono,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = activa ? ac.primaryGreen : ac.textMuted;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activa
                  ? ac.primaryGreen.withValues(alpha: 0.08)
                  : ac.chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activa
                    ? ac.primaryGreen.withValues(alpha: 0.4)
                    : ac.divider,
                width: activa ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activa
                        ? ac.primaryGreen.withValues(alpha: 0.12)
                        : ac.cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metodo.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: activa ? ac.textPrimary : ac.textSecondary,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: TextStyle(fontSize: 11, color: ac.textMuted),
                      ),
                    ],
                  ),
                ),
                if (activa)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: ac.primaryGreen,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desglose
// ---------------------------------------------------------------------------

class _Desglose extends StatelessWidget {
  final List<ItemCuenta> items;
  const _Desglose({required this.items});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSeccion(
            titulo: 'Desglose de Tratamientos',
            icono: Icons.receipt_long_rounded,
            color: ac.teal,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Esta cuenta no tiene tratamientos desglosados.',
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ac.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _FilaItem(item: items[i]),
                    if (i < items.length - 1)
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

class _FilaItem extends StatelessWidget {
  final ItemCuenta item;

  const _FilaItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ac.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 18,
              color: ac.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion.isEmpty ? 'Tratamiento' : item.descripcion,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.cantidad} × ${formatMoneda(item.precioUnitario)}',
                  style: TextStyle(color: ac.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoneda(item.precioTotal),
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Historial de Recibos
// ---------------------------------------------------------------------------

class _HistorialPagos extends StatelessWidget {
  final Cuenta cuenta;
  final Consulta? consulta;
  final Paciente? paciente;
  final String? errorDatosRecibo;

  const _HistorialPagos({
    required this.cuenta,
    required this.consulta,
    required this.paciente,
    required this.errorDatosRecibo,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final pagos = cuenta.pagos.where((pago) => pago.fueExitoso).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    if (pagos.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSeccion(
            titulo: 'Recibos Emitidos',
            icono: Icons.point_of_sale_rounded,
            color: ac.green,
          ),
          const SizedBox(height: 12),
          if (errorDatosRecibo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorDatosRecibo!,
                style: TextStyle(color: ac.red, fontSize: 12),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: ac.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var i = 0; i < pagos.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: ac.divider),
                  _FilaPago(
                    pago: pagos[i],
                    habilitado: consulta != null && paciente != null,
                    onVer: () => _abrirRecibo(
                      context,
                      cuenta: cuenta,
                      pago: pagos[i],
                      consulta: consulta!,
                      paciente: paciente!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaPago extends StatelessWidget {
  final Pago pago;
  final bool habilitado;
  final VoidCallback onVer;

  const _FilaPago({
    required this.pago,
    required this.habilitado,
    required this.onVer,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final pagoId = pago.id;
    final numero = pagoId == null
        ? 'Pago'
        : 'Recibo #${pagoId.substring(0, pagoId.length < 8 ? pagoId.length : 8).toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ac.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_rounded, color: ac.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numero,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fechaCortaEs(pago.fecha.toLocal())} · ${pago.metodoPago.name}',
                  style: TextStyle(color: ac.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            formatMoneda(pago.monto),
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: habilitado ? 'Ver Recibo PDF' : 'Datos no disponibles',
            onPressed: habilitado ? onVer : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: ac.primaryGreen,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones Inferiores
// ---------------------------------------------------------------------------

class _Acciones extends StatelessWidget {
  final Cuenta cuenta;
  final List<Cuota> cuotas;
  final String? pacienteId;
  const _Acciones({
    required this.cuenta,
    required this.cuotas,
    required this.pacienteId,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final saldada = cuenta.estado == EstadoCuenta.saldada;
    Cuota? proximaCuota;
    for (final cuota in cuotas) {
      if (cuota.saldoPendiente > 0 && cuota.estado != EstadoCuota.cancelada) {
        proximaCuota = cuota;
        break;
      }
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: saldada
                ? null
                : () =>
                      _mostrarDialogoPago(context, cuenta, cuota: proximaCuota),
            icon: Icon(
              saldada ? Icons.check_circle_rounded : Icons.payments_rounded,
              size: 20,
            ),
            label: Text(
              saldada
                  ? 'Cuenta Saldada Completamente'
                  : proximaCuota != null
                  ? 'Pagar Próxima Cuota'
                  : 'Registrar Cobro / Pago',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ac.primaryGreen,
              disabledBackgroundColor: ac.green.withValues(alpha: 0.15),
              disabledForegroundColor: ac.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: cuotas.isEmpty
                      ? () => _mostrarDialogoPlan(context, cuenta)
                      : null,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    cuotas.isEmpty ? 'Plan de cuotas' : 'Plan configurado',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.textSecondary,
                    side: BorderSide(color: ac.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoAjuste(context, cuenta),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Ajustar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.textSecondary,
                    side: BorderSide(color: ac.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (pacienteId != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResumenPlanPage.porPaciente(pacienteId!),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Ver plan de tratamiento completo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.primaryGreen,
                side: BorderSide(color: ac.primaryGreen.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogos
// ---------------------------------------------------------------------------

void _mostrarProximamente(BuildContext context, String accion) {
  final ac = context.appColors;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ac.cardBg,
      title: Text(accion, style: TextStyle(color: ac.textPrimary)),
      content: Text(
        'Esta función estará disponible próximamente.',
        style: TextStyle(color: ac.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

Future<void> _mostrarDialogoPlan(BuildContext context, Cuenta cuenta) async {
  final cubit = context.read<PreFacturaCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ac = context.appColors;
  final creado = await mostrarDialogoPlanCuotas(
    context: context,
    cuenta: cuenta,
    cubit: cubit,
  );
  if (creado == true) {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Plan de cuotas creado correctamente.'),
        backgroundColor: ac.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _mostrarDialogoPago(
  BuildContext context,
  Cuenta cuenta, {
  Cuota? cuota,
}) async {
  final cubit = context.read<PreFacturaCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final ac = context.appColors;

  final registrado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _DialogoRegistrarPago(cuenta: cuenta, cubit: cubit, cuota: cuota),
  );

  if (registrado == true) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          cuota == null
              ? 'Pago registrado correctamente.'
              : 'Abono a la cuota registrado correctamente.',
        ),
        backgroundColor: ac.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    final estado = cubit.state;
    final pago = cubit.ultimoPagoRegistrado;
    if (estado is PreFacturaCargada &&
        estado.puedeEmitirRecibo &&
        pago != null &&
        navigator.mounted) {
      await navigator.push(
        _rutaRecibo(
          cuenta: estado.cuenta,
          pago: pago,
          consulta: estado.consulta!,
          paciente: estado.paciente!,
        ),
      );
    }
  }
}

Future<void> _abrirRecibo(
  BuildContext context, {
  required Cuenta cuenta,
  required Pago pago,
  required Consulta consulta,
  required Paciente paciente,
}) {
  return Navigator.of(context).push(
    _rutaRecibo(
      cuenta: cuenta,
      pago: pago,
      consulta: consulta,
      paciente: paciente,
    ),
  );
}

MaterialPageRoute<void> _rutaRecibo({
  required Cuenta cuenta,
  required Pago pago,
  required Consulta consulta,
  required Paciente paciente,
}) => MaterialPageRoute<void>(
  builder: (_) => ReciboPagoPage(
    recibo: ReciboPago(
      cuenta: cuenta,
      pago: pago,
      consulta: consulta,
      paciente: paciente,
    ),
  ),
);

class _DialogoRegistrarPago extends StatefulWidget {
  final Cuenta cuenta;
  final PreFacturaCubit cubit;
  final Cuota? cuota;

  const _DialogoRegistrarPago({
    required this.cuenta,
    required this.cubit,
    this.cuota,
  });

  @override
  State<_DialogoRegistrarPago> createState() => _DialogoRegistrarPagoState();
}

class _DialogoRegistrarPagoState extends State<_DialogoRegistrarPago> {
  late final TextEditingController _montoController;
  pago_enums.MetodoPago _metodo = pago_enums.MetodoPago.efectivo;
  bool _procesando = false;
  String? _error;

  double get _saldo => widget.cuenta.balancePendiente;
  double get _saldoACobrar {
    final saldoCuota = widget.cuota?.saldoPendiente;
    if (saldoCuota == null || saldoCuota <= _saldo) return saldoCuota ?? _saldo;
    return _saldo;
  }

  double? get _montoIngresado {
    final texto = _montoController.text.trim().replaceAll(',', '');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  bool get _montoValido {
    final m = _montoIngresado;
    return m != null && m > 0 && m <= _saldoACobrar + 0.01;
  }

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: _saldoACobrar.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final monto = _montoIngresado;
    if (monto == null || !_montoValido) return;

    setState(() {
      _procesando = true;
      _error = null;
    });

    final error = await widget.cubit.registrarPago(
      monto: monto,
      metodo: _metodo,
      cuota: widget.cuota,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _procesando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final monto = _montoIngresado ?? 0;
    final saldoRestante = _saldo - monto;

    return AlertDialog(
      backgroundColor: ac.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ac.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: ac.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.cuota == null ? 'Registrar Pago' : 'Pagar Cuota',
            style: TextStyle(
              color: ac.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cuota == null
                  ? 'Saldo pendiente total: ${formatMoneda(_saldo)}'
                  : 'Vence ${fechaLargaEs(widget.cuota!.fechaVencimiento)} · '
                        'Restan ${formatMoneda(_saldoACobrar)}',
              style: TextStyle(color: ac.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoController,
              autofocus: true,
              enabled: !_procesando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                labelText: 'Monto a cobrar (RD\$)',
                hintText: '0.00',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ac.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ac.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: ac.red),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: ac.red,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Método de Pago',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metodo in pago_enums.MetodoPago.values)
                  _ChipMetodoPago(
                    metodo: metodo,
                    activo: _metodo == metodo,
                    onTap: _procesando
                        ? null
                        : () => setState(() => _metodo = metodo),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _ResumenPago(
              monto: monto,
              metodo: _metodo,
              saldoRestante: saldoRestante < 0 ? 0 : saldoRestante,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _procesando
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_montoValido && !_procesando) ? _registrar : null,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          child: _procesando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Cobrar ${formatMoneda(monto)}'),
        ),
      ],
    );
  }
}

class _ChipMetodoPago extends StatelessWidget {
  final pago_enums.MetodoPago metodo;
  final bool activo;
  final VoidCallback? onTap;

  const _ChipMetodoPago({
    required this.metodo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? ac.primaryGreen.withValues(alpha: 0.1) : ac.chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo
                  ? ac.primaryGreen.withValues(alpha: 0.5)
                  : ac.divider,
              width: activo ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconoMetodo(metodo),
                size: 16,
                color: activo ? ac.primaryGreen : ac.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                metodo.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: activo ? ac.textPrimary : ac.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenPago extends StatelessWidget {
  final double monto;
  final pago_enums.MetodoPago metodo;
  final double saldoRestante;

  const _ResumenPago({
    required this.monto,
    required this.metodo,
    required this.saldoRestante,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider),
      ),
      child: Column(
        children: [
          _FilaResumen(label: 'Monto a cobrar', valor: formatMoneda(monto)),
          const SizedBox(height: 6),
          _FilaResumen(label: 'Método seleccionado', valor: metodo.name),
          const SizedBox(height: 6),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 6),
          _FilaResumen(
            label: 'Saldo tras el pago',
            valor: formatMoneda(saldoRestante),
            resaltado: saldoRestante <= 0,
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String valor;
  final bool resaltado;

  const _FilaResumen({
    required this.label,
    required this.valor,
    this.resaltado = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: ac.textSecondary, fontSize: 12.5)),
        Text(
          valor,
          style: TextStyle(
            color: resaltado ? ac.green : ac.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

IconData _iconoMetodo(pago_enums.MetodoPago metodo) {
  return switch (metodo) {
    pago_enums.MetodoPago.efectivo => Icons.payments_outlined,
    pago_enums.MetodoPago.tarjetaCredito => Icons.credit_card_rounded,
    pago_enums.MetodoPago.tarjetaDebito => Icons.credit_card_outlined,
    pago_enums.MetodoPago.transferenciaBancaria =>
      Icons.account_balance_rounded,
  };
}

void _mostrarDialogoAjuste(BuildContext context, Cuenta cuenta) {
  // Ajustar una cuenta toca el resultado clínico facturado: lo hace quien
  // ejerce, no quien sólo opera la agenda.
  final autorizado = context.read<AuthCubit>().state.puedeEjercerClinica;

  if (!autorizado) {
    _mostrarNoAutorizado(context);
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => _FormularioAjuste(cuenta: cuenta),
  );
}

void _mostrarNoAutorizado(BuildContext context) {
  final ac = context.appColors;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ac.cardBg,
      title: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: ac.amber, size: 22),
          const SizedBox(width: 10),
          Text('Acción restringida', style: TextStyle(color: ac.textPrimary)),
        ],
      ),
      content: Text(
        'Requiere rol Administrador o Doctor para ajustar la cuenta.',
        style: TextStyle(color: ac.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _FormularioAjuste extends StatefulWidget {
  final Cuenta cuenta;
  const _FormularioAjuste({required this.cuenta});

  @override
  State<_FormularioAjuste> createState() => _FormularioAjusteState();
}

class _FormularioAjusteState extends State<_FormularioAjuste> {
  final _montoController = TextEditingController();
  final _notaController = TextEditingController();

  @override
  void dispose() {
    _montoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AlertDialog(
      backgroundColor: ac.cardBg,
      title: Text('Ajustar cuenta', style: TextStyle(color: ac.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto del ajuste (RD\$)',
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notaController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo del ajuste'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _mostrarProximamente(context, 'Aplicar ajuste');
          },
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers Compartidos
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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
      child: child,
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;

  const _TituloSeccion({
    required this.titulo,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icono, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

(Color, String, IconData) _infoEstado(EstadoCuenta estado, AppColors ac) {
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
