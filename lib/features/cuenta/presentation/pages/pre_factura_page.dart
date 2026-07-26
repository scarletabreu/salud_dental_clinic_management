import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
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
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/presentation/pages/recibo_pago_page.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/pages/resumen_plan_page.dart';

/// Detalle de cuenta / pre-factura de una consulta. Punto de llegada al cerrar
/// una consulta (SD-96) y accesible desde el expediente del paciente.
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
          title: const Text('Detalle de cuenta'),
          backgroundColor: ac.cardBg,
          foregroundColor: ac.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
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
// Estados no-cargados
// ---------------------------------------------------------------------------

class _EstadoCargando extends StatelessWidget {
  final AppColors ac;
  const _EstadoCargando({required this.ac});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: ac.primaryBlue),
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
            Icon(Icons.error_outline_rounded, color: ac.red, size: 40),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: ac.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido (cuenta cargada)
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
      padding: const EdgeInsets.all(24),
      children: [
        _HeaderEstado(cuenta: cuenta),
        const SizedBox(height: 16),
        _SelectorModalidad(
          seleccionada: _modalidad,
          onChanged: (m) => setState(() => _modalidad = m),
        ),
        const SizedBox(height: 16),
        _Desglose(items: cuenta.itemCuentas),
        const SizedBox(height: 16),
        _Totales(cuenta: cuenta),
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
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header de estado
// ---------------------------------------------------------------------------

class _HeaderEstado extends StatelessWidget {
  final Cuenta cuenta;
  const _HeaderEstado({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (color, label, icon) = _infoEstado(cuenta.estado, ac);
    final consultaCorta = cuenta.consultaId.length > 8
        ? cuenta.consultaId.substring(0, 8)
        : cuenta.consultaId;

    return _Card(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El estado acompaña al título mientras haya ancho; con
                // pantallas estrechas o texto ampliado baja de línea en vez de
                // empujar el título fuera de la tarjeta.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Consulta #$consultaCorta',
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  fechaLargaEs(cuenta.fechaCreacion),
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
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
// Selector de modalidad. Crédito abre la configuración del calendario; al
// confirmar el plan la modalidad se persiste junto con las cuotas.
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
            titulo: 'Modalidad de pago',
            icono: Icons.tune_rounded,
            color: context.appColors.indigo,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _OpcionModalidad(
                metodo: MetodoPago.contado,
                icono: Icons.payments_outlined,
                activa: seleccionada == MetodoPago.contado,
                onTap: () => onChanged(MetodoPago.contado),
              ),
              const SizedBox(width: 10),
              _OpcionModalidad(
                metodo: MetodoPago.credito,
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
  final IconData icono;
  final bool activa;
  final VoidCallback onTap;

  const _OpcionModalidad({
    required this.metodo,
    required this.icono,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = activa ? ac.primaryBlue : ac.textMuted;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: activa
                  ? ac.primaryBlue.withValues(alpha: 0.08)
                  : ac.chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activa
                    ? ac.primaryBlue.withValues(alpha: 0.4)
                    : ac.divider,
                width: activa ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icono, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metodo.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: activa ? ac.textPrimary : ac.textSecondary,
                    ),
                  ),
                ),
                if (activa)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: ac.primaryBlue,
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
// Desglose de tratamientos
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
            titulo: 'Desglose de tratamientos',
            icono: Icons.receipt_long_rounded,
            color: ac.teal,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Esta cuenta no tiene tratamientos desglosados.',
                style: TextStyle(color: ac.textMuted, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              _FilaItem(item: items[i], esUltima: i == items.length - 1),
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ItemCuenta item;
  final bool esUltima;

  const _FilaItem({required this.item, required this.esUltima});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final detalle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.descripcion.isEmpty ? 'Tratamiento' : item.descripcion,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.cantidad} × ${formatMoneda(item.precioUnitario)}',
          style: TextStyle(color: ac.textMuted, fontSize: 12.5),
        ),
      ],
    );
    final total = Text(
      formatMoneda(item.precioTotal),
      style: TextStyle(
        color: ac.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: esUltima ? 0 : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // El importe nunca se recorta: si no cabe junto a la descripción,
          // pasa a su propia línea.
          final anchoTotal = _anchoTexto(context, total);
          if (anchoTotal > constraints.maxWidth * 0.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [detalle, const SizedBox(height: 4), total],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: detalle),
              const SizedBox(width: 12),
              total,
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totales
// ---------------------------------------------------------------------------

class _Totales extends StatelessWidget {
  final Cuenta cuenta;
  const _Totales({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return _Card(
      child: Column(
        children: [
          _FilaTotal(
            label: 'Subtotal',
            valor: formatMoneda(cuenta.montoTotal),
            color: ac.textPrimary,
          ),
          const SizedBox(height: 10),
          _FilaTotal(
            label: 'Pagado',
            valor: formatMoneda(cuenta.montoPagado),
            color: ac.green,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 12),
          _FilaTotal(
            label: 'Balance pendiente',
            valor: formatMoneda(cuenta.balancePendiente),
            color: cuenta.estado == EstadoCuenta.saldada ? ac.green : ac.red,
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final bool destacado;

  const _FilaTotal({
    required this.label,
    required this.valor,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final etiqueta = Text(
      label,
      style: TextStyle(
        color: destacado ? ac.textPrimary : ac.textSecondary,
        fontSize: destacado ? 15 : 14,
        fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    final importe = Text(
      valor,
      style: TextStyle(
        color: color,
        fontSize: destacado ? 18 : 14.5,
        fontWeight: destacado ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: destacado ? -0.4 : 0,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // El importe no se recorta nunca; si compite con la etiqueta, la
        // etiqueta pasa a su propia línea.
        if (_anchoTexto(context, importe) > constraints.maxWidth * 0.55) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [etiqueta, const SizedBox(height: 2), importe],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: etiqueta),
            const SizedBox(width: 12),
            importe,
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Recibos de pagos ya registrados
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
            titulo: 'Recibos de pago',
            icono: Icons.receipt_long_rounded,
            color: ac.teal,
          ),
          const SizedBox(height: 6),
          if (errorDatosRecibo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorDatosRecibo!,
                style: TextStyle(color: ac.red, fontSize: 12),
              ),
            ),
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
        : 'Pago #${pagoId.substring(0, pagoId.length < 8 ? pagoId.length : 8).toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ac.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_rounded, color: ac.green, size: 20),
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
            tooltip: habilitado
                ? 'Ver recibo'
                : 'Datos del recibo no disponibles',
            onPressed: habilitado ? onVer : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: ac.primaryBlue,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones
// ---------------------------------------------------------------------------

class _Acciones extends StatelessWidget {
  final Cuenta cuenta;
  final List<Cuota> cuotas;
  final String? pacienteId;
  const _Acciones({required this.cuenta, required this.cuotas, required this.pacienteId});

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
                  ? 'Cuenta saldada'
                  : proximaCuota != null
                  ? 'Pagar próxima cuota'
                  : 'Registrar pago',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ac.primaryBlue,
              disabledBackgroundColor: ac.green.withValues(alpha: 0.15),
              disabledForegroundColor: ac.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoAjuste(context, cuenta),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Ajustar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.textSecondary,
                  side: BorderSide(color: ac.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    foregroundColor: ac.primaryBlue,
                    side: BorderSide(color: ac.primaryBlue.withValues(alpha: 0.4)),
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

/// Abre el diálogo de cobro pasándole el cubit de la pantalla (capturado antes
/// de `showDialog`, ya que el diálogo se monta en otra rama del árbol). Al
/// confirmar el cobro, el cubit recarga la cuenta y aquí se muestra el aviso.
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

/// Diálogo de cobro: monto prellenado con el saldo, selector de método y un
/// resumen en vivo (monto, método y saldo tras el pago). Gestiona su propio
/// estado de carga y error; delega la operación atómica en [PreFacturaCubit].
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
      title: Row(
        children: [
          Icon(Icons.payments_rounded, color: ac.primaryBlue, size: 22),
          const SizedBox(width: 10),
          Text(
            widget.cuota == null ? 'Registrar pago' : 'Pagar cuota',
            style: TextStyle(color: ac.textPrimary),
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
                  ? 'Saldo pendiente: ${formatMoneda(_saldo)}'
                  : 'Vence ${fechaLargaEs(widget.cuota!.fechaVencimiento)} · '
                        'Restan ${formatMoneda(_saldoACobrar)}',
              style: TextStyle(color: ac.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _montoController,
              autofocus: true,
              enabled: !_procesando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Monto a cobrar (RD\$)',
                hintText: '0.00',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
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
                      Icon(
                        Icons.point_of_sale_rounded,
                        size: 19,
                        color: ac.red,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: ac.red,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Método de pago',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
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
            color: activo ? ac.primaryBlue.withValues(alpha: 0.1) : ac.chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo
                  ? ac.primaryBlue.withValues(alpha: 0.5)
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
                color: activo ? ac.primaryBlue : ac.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                metodo.name,
                style: TextStyle(
                  fontSize: 13,
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
          _FilaResumen(label: 'Monto', valor: formatMoneda(monto)),
          const SizedBox(height: 8),
          _FilaResumen(label: 'Método', valor: metodo.name),
          const SizedBox(height: 8),
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
        Text(label, style: TextStyle(color: ac.textSecondary, fontSize: 13)),
        Text(
          valor,
          style: TextStyle(
            color: resaltado ? ac.green : ac.textPrimary,
            fontSize: 13.5,
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

/// Diálogo de ajuste con gate de autorización por rol. La entrega de este ticket
/// (SD-101) es el gate funcionando; la persistencia del ajuste queda para un
/// ticket futuro.
void _mostrarDialogoAjuste(BuildContext context, Cuenta cuenta) {
  final autorizado = context.read<AuthCubit>().state.hasAnyRole([
    RolUsuario.admin,
    RolUsuario.doctor,
  ]);

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
            // TODO(SD-###): persistir el ajuste. El schema aún no tiene un
            // mecanismo de descuento/ajuste; este flujo queda cableado a un
            // ticket futuro. Por ahora solo confirma el gate de autorización.
            Navigator.of(context).pop();
            _mostrarProximamente(context, 'Aplicar ajuste');
          },
          style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers compartidos
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icono, size: 17, color: color),
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

/// Mide un [Text] sin renderizarlo, para decidir si cabe junto a otro widget.
double _anchoTexto(BuildContext context, Text texto) {
  final painter = TextPainter(
    text: TextSpan(text: texto.data, style: texto.style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return painter.width;
}
