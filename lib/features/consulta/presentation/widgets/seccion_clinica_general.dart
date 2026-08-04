import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Lo que el catálogo declara global o de arcada (HFX-CLIN-003).
///
/// Antes estos elementos aparecían dentro del selector de una pieza y quedaban
/// colgados de un molar cualquiera. Ahora tienen su propio sitio, y la base
/// rechaza que se asignen a una pieza.
class SeccionClinicaGeneral extends StatelessWidget {
  const SeccionClinicaGeneral({
    super.key,
    required this.tratamientos,
    required this.diagnosticos,
    required this.nombreTratamiento,
    required this.nombreDiagnostico,
    required this.onAgregarTratamiento,
    required this.onAgregarDiagnostico,
    required this.onQuitarTratamiento,
    required this.onQuitarDiagnostico,
    this.hayCatalogoGeneral = true,
  });

  final List<TratamientoAplicado> tratamientos;
  final List<DiagnosticoAplicado> diagnosticos;
  final String Function(String tratamientoId) nombreTratamiento;
  final String Function(String diagnosisId) nombreDiagnostico;
  final VoidCallback onAgregarTratamiento;
  final VoidCallback onAgregarDiagnostico;
  final void Function(int index) onQuitarTratamiento;
  final void Function(int index) onQuitarDiagnostico;
  final bool hayCatalogoGeneral;

  /// Los que pueden registrarse aquí: nada de lo que va sobre una pieza.
  static List<Tratamiento> tratamientosGenerales(List<Tratamiento> catalogo) => [
    for (final t in catalogo)
      if (t.alcance == Alcance.global || t.alcance == Alcance.arcada) t,
  ];

  static List<Diagnosis> diagnosticosGenerales(List<Diagnosis> catalogo) => [
    for (final d in catalogo)
      if (d.alcance == Alcance.global || d.alcance == Alcance.arcada) d,
  ];

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hallazgos y tratamientos que no corresponden a una pieza concreta: '
          'profilaxis, gingivitis generalizada, fluorización de arcada.',
          style: TextStyle(fontSize: 12.5, color: ac.textMuted, height: 1.4),
        ),
        const SizedBox(height: 12),
        _Bloque(
          titulo: 'Hallazgos generales',
          icono: Icons.search_rounded,
          color: ac.indigo,
          onAgregar: hayCatalogoGeneral ? onAgregarDiagnostico : null,
          vacio: 'Sin hallazgos generales en esta consulta.',
          filas: [
            for (var i = 0; i < diagnosticos.length; i++)
              _Fila(
                titulo:
                    diagnosticos[i].nombreDiagnostico ??
                    nombreDiagnostico(diagnosticos[i].diagnosisId),
                detalle: diagnosticos[i].severidad.name,
                onQuitar: () => onQuitarDiagnostico(i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Bloque(
          titulo: 'Tratamientos generales ejecutados',
          icono: Icons.medical_services_outlined,
          color: ac.teal,
          onAgregar: hayCatalogoGeneral ? onAgregarTratamiento : null,
          vacio: 'Sin tratamientos generales registrados.',
          filas: [
            for (var i = 0; i < tratamientos.length; i++)
              _Fila(
                titulo:
                    tratamientos[i].nombreTratamiento ??
                    nombreTratamiento(tratamientos[i].tratamientoId),
                detalle: tratamientos[i].precioAplicado == null
                    ? tratamientos[i].estado.etiqueta
                    : '${tratamientos[i].estado.etiqueta} · '
                          'RD\$ ${tratamientos[i].precioAplicado!.toStringAsFixed(2)}',
                onQuitar: () => onQuitarTratamiento(i),
              ),
          ],
        ),
        if (!hayCatalogoGeneral)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'El catálogo no tiene elementos de alcance global o de arcada.',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            ),
          ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.onAgregar,
    required this.vacio,
    required this.filas,
  });

  final String titulo;
  final IconData icono;
  final Color color;
  final VoidCallback? onAgregar;
  final String vacio;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (filas.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              vacio,
              style: TextStyle(fontSize: 12.5, color: ac.textMuted),
            ),
          )
        else
          ...filas,
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.titulo,
    required this.detalle,
    required this.onQuitar,
  });

  final String titulo;
  final String detalle;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
                Text(
                  detalle,
                  style: TextStyle(fontSize: 11.5, color: ac.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: Icon(Icons.close_rounded, size: 16, color: ac.textMuted),
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}
