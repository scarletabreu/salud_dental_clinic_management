import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;

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
                PreFacturaCargada(:final cuenta) => _Contenido(cuenta: cuenta),
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
  const _Contenido({required this.cuenta});

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
        _Acciones(cuenta: cuenta),
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
    final (color, label, icon) = _infoEstado(cuenta.estadoCuenta, ac);
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
                Text(
                  'Consulta #$consultaCorta',
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fechaLargaEs(cuenta.fechaCreacion),
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Selector de modalidad (estado local, no persiste en este ticket)
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
                Text(
                  metodo.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: activa ? ac.textPrimary : ac.textSecondary,
                  ),
                ),
                const Spacer(),
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
    return Padding(
      padding: EdgeInsets.only(bottom: esUltima ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoneda(item.precioTotal),
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            color: cuenta.estaPagada ? ac.green : ac.red,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: destacado ? ac.textPrimary : ac.textSecondary,
            fontSize: destacado ? 15 : 14,
            fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: destacado ? 18 : 14.5,
            fontWeight: destacado ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: destacado ? -0.4 : 0,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones
// ---------------------------------------------------------------------------

class _Acciones extends StatelessWidget {
  final Cuenta cuenta;
  const _Acciones({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final saldada = cuenta.estaPagada;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saldada ? null : () => _mostrarDialogoPago(context, cuenta),
            icon: Icon(
              saldada ? Icons.check_circle_rounded : Icons.payments_rounded,
              size: 20,
            ),
            label: Text(saldada ? 'Cuenta saldada' : 'Registrar pago'),
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
                onPressed: () => _mostrarProximamente(context, 'Plan de cuotas'),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Plan de cuotas'),
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

/// Abre el diálogo de cobro pasándole el cubit de la pantalla (capturado antes
/// de `showDialog`, ya que el diálogo se monta en otra rama del árbol). Al
/// confirmar el cobro, el cubit recarga la cuenta y aquí se muestra el aviso.
Future<void> _mostrarDialogoPago(BuildContext context, Cuenta cuenta) async {
  final cubit = context.read<PreFacturaCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ac = context.appColors;

  final registrado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoRegistrarPago(cuenta: cuenta, cubit: cubit),
  );

  if (registrado == true) {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Pago registrado correctamente.'),
        backgroundColor: ac.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Diálogo de cobro: monto prellenado con el saldo, selector de método y un
/// resumen en vivo (monto, método y saldo tras el pago). Gestiona su propio
/// estado de carga y error; delega la operación atómica en [PreFacturaCubit].
class _DialogoRegistrarPago extends StatefulWidget {
  final Cuenta cuenta;
  final PreFacturaCubit cubit;

  const _DialogoRegistrarPago({required this.cuenta, required this.cubit});

  @override
  State<_DialogoRegistrarPago> createState() => _DialogoRegistrarPagoState();
}

class _DialogoRegistrarPagoState extends State<_DialogoRegistrarPago> {
  late final TextEditingController _montoController;
  pago_enums.MetodoPago _metodo = pago_enums.MetodoPago.efectivo;
  bool _procesando = false;
  String? _error;

  double get _saldo => widget.cuenta.balancePendiente;

  double? get _montoIngresado {
    final texto = _montoController.text.trim().replaceAll(',', '');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  bool get _montoValido {
    final m = _montoIngresado;
    return m != null && m > 0 && m <= _saldo + 0.01;
  }

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: _saldo.toStringAsFixed(2),
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
          Text('Registrar pago', style: TextStyle(color: ac.textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo pendiente: ${formatMoneda(_saldo)}',
              style: TextStyle(color: ac.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _montoController,
              autofocus: true,
              enabled: !_procesando,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Monto a cobrar (RD\$)',
                hintText: '0.00',
                errorText: _error,
              ),
            ),
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
          onPressed: _procesando ? null : () => Navigator.of(context).pop(false),
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
              Icon(_iconoMetodo(metodo), size: 16, color: activo ? ac.primaryBlue : ac.textMuted),
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
        Text(
          label,
          style: TextStyle(color: ac.textSecondary, fontSize: 13),
        ),
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
    pago_enums.MetodoPago.transferenciaBancaria => Icons.account_balance_rounded,
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
            decoration: const InputDecoration(
              labelText: 'Motivo del ajuste',
            ),
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
        Text(
          titulo,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
