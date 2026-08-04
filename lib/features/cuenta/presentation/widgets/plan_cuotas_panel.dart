import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/frecuencia_cuota.dart';

class PlanCuotasPanel extends StatelessWidget {
  final List<Cuota> cuotas;
  final VoidCallback onConfigurar;
  final ValueChanged<Cuota> onPagar;

  const PlanCuotasPanel({
    super.key,
    required this.cuotas,
    required this.onConfigurar,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final pagadas = cuotas.where((c) => c.estado == EstadoCuota.pagada).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.divider),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ac.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: ac.indigo,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendario de pagos',
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cuotas.isEmpty
                          ? 'Divide el saldo en fechas claras de cobro.'
                          : '$pagadas de ${cuotas.length} cuotas pagadas',
                      style: TextStyle(color: ac.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (cuotas.isNotEmpty)
                _ProgresoPlan(pagadas: pagadas, total: cuotas.length),
            ],
          ),
          const SizedBox(height: 16),
          if (cuotas.isEmpty)
            _PlanVacio(onConfigurar: onConfigurar)
          else
            for (var i = 0; i < cuotas.length; i++)
              _FilaCuota(
                cuota: cuotas[i],
                numero: i + 1,
                esUltima: i == cuotas.length - 1,
                onPagar: () => onPagar(cuotas[i]),
              ),
        ],
      ),
    );
  }
}

class _PlanVacio extends StatelessWidget {
  final VoidCallback onConfigurar;
  const _PlanVacio({required this.onConfigurar});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.indigo.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.indigo.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            'Aún no hay fechas programadas',
            style: TextStyle(
              color: ac.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configura la cantidad, la primera fecha y la frecuencia antes de confirmar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ac.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onConfigurar,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Configurar plan'),
            style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          ),
        ],
      ),
    );
  }
}

class _ProgresoPlan extends StatelessWidget {
  final int pagadas;
  final int total;
  const _ProgresoPlan({required this.pagadas, required this.total});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ac.green.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(pagadas / total * 100).round()}%',
        style: TextStyle(
          color: ac.green,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FilaCuota extends StatelessWidget {
  final Cuota cuota;
  final int numero;
  final bool esUltima;
  final VoidCallback onPagar;

  const _FilaCuota({
    required this.cuota,
    required this.numero,
    required this.esUltima,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (color, label) = _estiloEstado(ac, cuota.estado);
    final pagable =
        cuota.saldoPendiente > 0 && cuota.estado != EstadoCuota.cancelada;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: cuota.estado == EstadoCuota.pagada
                      ? Icon(Icons.check_rounded, size: 16, color: color)
                      : Text(
                          '$numero',
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (!esUltima)
                  Expanded(child: Container(width: 1.5, color: ac.divider)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltima ? 0 : 15),
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
                decoration: BoxDecoration(
                  color: ac.chipBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: ac.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fechaLargaEs(cuota.fechaVencimiento),
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cuota.montoPagado > 0 && pagable
                                    ? '${formatMoneda(cuota.montoPagado)} abonado de ${formatMoneda(cuota.monto)}'
                                    : formatMoneda(cuota.monto),
                                style: TextStyle(
                                  color: ac.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _EstadoChip(label: label, color: color),
                      ],
                    ),
                    if (cuota.montoPagado > 0 && pagable) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cuota.progreso,
                          minHeight: 4,
                          color: color,
                          backgroundColor: ac.divider,
                        ),
                      ),
                    ],
                    if (pagable) ...[
                      const SizedBox(height: 9),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onPagar,
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: Text(
                            cuota.montoPagado > 0
                                ? 'Completar cuota'
                                : 'Pagar cuota',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: ac.primaryGreen,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _EstadoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

(Color, String) _estiloEstado(AppColors ac, EstadoCuota estado) {
  return switch (estado) {
    EstadoCuota.pendiente => (ac.amber, 'PENDIENTE'),
    EstadoCuota.pagada => (ac.green, 'PAGADA'),
    EstadoCuota.vencida || EstadoCuota.atrasada => (ac.red, 'VENCIDA'),
    EstadoCuota.cancelada => (ac.textMuted, 'CANCELADA'),
  };
}

Future<bool?> mostrarDialogoPlanCuotas({
  required BuildContext context,
  required Cuenta cuenta,
  required PreFacturaCubit cubit,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoPlanCuotas(cuenta: cuenta, cubit: cubit),
  );
}

class _DialogoPlanCuotas extends StatefulWidget {
  final Cuenta cuenta;
  final PreFacturaCubit cubit;

  const _DialogoPlanCuotas({required this.cuenta, required this.cubit});

  @override
  State<_DialogoPlanCuotas> createState() => _DialogoPlanCuotasState();
}

class _DialogoPlanCuotasState extends State<_DialogoPlanCuotas> {
  int _numCuotas = 3;
  late DateTime _fechaPrimera;
  FrecuenciaCuota _frecuencia = FrecuenciaCuota.mensual;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaPrimera = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).add(const Duration(days: 30));
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaPrimera,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 5),
      helpText: 'Primera fecha de pago',
    );
    if (seleccionada != null && mounted) {
      setState(() {
        _fechaPrimera = seleccionada;
        _error = null;
      });
    }
  }

  Future<void> _confirmar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await widget.cubit.generarPlan(
      numCuotas: _numCuotas,
      fechaPrimera: _fechaPrimera,
      frecuencia: _frecuencia,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    List<Cuota> preview;
    String? previewError;
    try {
      preview = widget.cubit.previsualizarPlan(
        numCuotas: _numCuotas,
        fechaPrimera: _fechaPrimera,
        frecuencia: _frecuencia,
      );
    } on Failure catch (e) {
      preview = const [];
      previewError = e.message;
    }
    return AppDialog(
      backgroundColor: ac.cardBg,
      preferredWidth: 510,
      title: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: ac.indigo, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configurar plan',
              style: TextStyle(color: ac.textPrimary),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo a programar: ${formatMoneda(widget.cuenta.balancePendiente)}',
            style: TextStyle(color: ac.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 15),
          AppFormRow(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _numCuotas,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de cuotas',
                ),
                items: [2, 3, 4, 6, 8, 10, 12, 18, 24, 36]
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n, child: Text('$n cuotas')),
                    )
                    .toList(),
                onChanged: _guardando
                    ? null
                    : (value) => setState(() {
                        _numCuotas = value ?? 3;
                        _error = null;
                      }),
              ),
              DropdownButtonFormField<FrecuenciaCuota>(
                initialValue: _frecuencia,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: FrecuenciaCuota.values
                    .map(
                      (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                    )
                    .toList(),
                onChanged: _guardando
                    ? null
                    : (value) => setState(() {
                        _frecuencia = value ?? FrecuenciaCuota.mensual;
                        _error = null;
                      }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _guardando ? null : _elegirFecha,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Primera fecha de pago',
                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: Text(fechaLargaEs(_fechaPrimera)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Previsualización',
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: ac.chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ac.divider),
            ),
            child: Column(
              children: [
                for (var i = 0; i < preview.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            color: ac.indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fechaCortaEs(preview[i].fechaVencimiento),
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Text(
                          formatMoneda(preview[i].monto),
                          style: TextStyle(
                            color: ac.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != preview.length - 1)
                    Divider(height: 1, color: ac.divider),
                ],
              ],
            ),
          ),
          if (_error != null || previewError != null) ...[
            const SizedBox(height: 12),
            Text(
              _error ?? previewError!,
              style: TextStyle(color: ac.red, fontSize: 12.5),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: preview.isEmpty || _guardando ? null : _confirmar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Confirmar ${preview.length} cuotas'),
        ),
      ],
    );
  }
}
