import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/presentation/pdf/recibo_pdf.dart';

class ReciboPagoPage extends StatefulWidget {
  final ReciboPago recibo;

  const ReciboPagoPage({super.key, required this.recibo});

  @override
  State<ReciboPagoPage> createState() => _ReciboPagoPageState();
}

class _ReciboPagoPageState extends State<ReciboPagoPage> {
  bool _procesando = false;

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await accion();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo preparar el recibo. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _imprimir() => _ejecutar(() async {
    await Printing.layoutPdf(
      name: widget.recibo.nombreArchivo,
      onLayout: (formato) => generarReciboPdf(
        widget.recibo,
        formato: formato == PdfPageFormat.undefined
            ? PdfPageFormat.a4
            : formato,
      ),
    );
  });

  Future<void> _guardarPdf() => _ejecutar(() async {
    final bytes = await generarReciboPdf(widget.recibo);
    await Printing.sharePdf(
      bytes: bytes,
      filename: widget.recibo.nombreArchivo,
    );
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        title: const Text('Recibo de pago'),
        backgroundColor: ac.cardBg,
        foregroundColor: ac.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _BarraAcciones(
            procesando: _procesando,
            onImprimir: _imprimir,
            onGuardarPdf: _guardarPdf,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: _DocumentoRecibo(recibo: widget.recibo),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  final bool procesando;
  final VoidCallback onImprimir;
  final VoidCallback onGuardarPdf;

  const _BarraAcciones({
    required this.procesando,
    required this.onImprimir,
    required this.onGuardarPdf,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      color: ac.cardBg,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('guardar_pdf_button'),
                onPressed: procesando ? null : onGuardarPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                label: const Text('Guardar PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.textSecondary,
                  side: BorderSide(color: ac.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('imprimir_recibo_button'),
                onPressed: procesando ? null : onImprimir,
                icon: procesando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print_rounded, size: 19),
                label: Text(procesando ? 'Preparando…' : 'Imprimir'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
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

class _DocumentoRecibo extends StatelessWidget {
  final ReciboPago recibo;

  const _DocumentoRecibo({required this.recibo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final compacto = MediaQuery.sizeOf(context).width < 600;
    return Container(
      key: const Key('recibo_documento'),
      padding: EdgeInsets.all(compacto ? 16 : 32),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Encabezado(recibo: recibo),
          const SizedBox(height: 24),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final paciente = _BloqueInformacion(
                titulo: 'Paciente',
                filas: [
                  ('Nombre', recibo.paciente.fullName),
                  (
                    'Cédula',
                    recibo.paciente.govID.isEmpty ? '—' : recibo.paciente.govID,
                  ),
                ],
              );
              final pago = _BloqueInformacion(
                titulo: 'Pago y consulta',
                filas: [
                  (
                    'Fecha',
                    '${fechaLargaEs(recibo.pago.fecha.toLocal())} · ${_hora(recibo.pago.fecha)}',
                  ),
                  ('Consulta', '#${recibo.consultaNumero}'),
                  ('Método', recibo.pago.metodoPago.name),
                ],
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [paciente, const SizedBox(height: 12), pago],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: paciente),
                  const SizedBox(width: 12),
                  Expanded(child: pago),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Text(
            'DESGLOSE DE LA CUENTA',
            style: TextStyle(
              color: ac.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _DesgloseRecibo(recibo: recibo),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: _ResumenTotales(recibo: recibo),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: ac.divider),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Este documento acredita el pago indicado. No constituye factura ni comprobante fiscal para fines de la DGII.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ac.textMuted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final ReciboPago recibo;

  const _Encabezado({required this.recibo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final identidad = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ac.primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'SD',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recibo.clinica.nombre,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                recibo.clinica.descripcion,
                style: TextStyle(color: ac.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
    final referencia = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'RECIBO DE PAGO',
          style: TextStyle(
            color: ac.primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '#${recibo.numero}',
          style: TextStyle(color: ac.textMuted, fontSize: 12),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identidad,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: referencia),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identidad),
            const SizedBox(width: 16),
            referencia,
          ],
        );
      },
    );
  }
}

class _BloqueInformacion extends StatelessWidget {
  final String titulo;
  final List<(String, String)> filas;

  const _BloqueInformacion({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: TextStyle(
              color: ac.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          for (final fila in filas) ...[
            Text(
              fila.$1,
              style: TextStyle(color: ac.textMuted, fontSize: 10.5),
            ),
            const SizedBox(height: 1),
            Text(
              fila.$2,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _DesgloseRecibo extends StatelessWidget {
  final ReciboPago recibo;

  const _DesgloseRecibo({required this.recibo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ac.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < recibo.cuenta.itemCuentas.length; i++) ...[
            _FilaItem(itemIndex: i, recibo: recibo),
            if (i < recibo.cuenta.itemCuentas.length - 1)
              Divider(height: 1, color: ac.divider),
          ],
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final int itemIndex;
  final ReciboPago recibo;

  const _FilaItem({required this.itemIndex, required this.recibo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final item = recibo.cuenta.itemCuentas[itemIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.cantidad} × ${formatMoneda(item.precioUnitario)}',
                  style: TextStyle(color: ac.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            formatMoneda(item.precioTotal),
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenTotales extends StatelessWidget {
  final ReciboPago recibo;

  const _ResumenTotales({required this.recibo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      children: [
        _LineaTotal(
          label: 'Total de la cuenta',
          valor: formatMoneda(recibo.cuenta.montoTotal),
        ),
        const SizedBox(height: 9),
        _LineaTotal(
          label: 'Pagado anteriormente',
          valor: formatMoneda(recibo.pagadoAntes),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: ac.primaryBlue,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'PAGO RECIBIDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMoneda(recibo.pago.monto),
                key: const Key('monto_pago_recibo'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _LineaTotal(
          label: 'Balance pendiente',
          valor: formatMoneda(recibo.saldoDespues),
          destacado: true,
        ),
      ],
    );
  }
}

class _LineaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacado;

  const _LineaTotal({
    required this.label,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: destacado ? ac.textPrimary : ac.textSecondary,
              fontSize: 12.5,
              fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valor,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: destacado ? 14 : 12.5,
            fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _hora(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
