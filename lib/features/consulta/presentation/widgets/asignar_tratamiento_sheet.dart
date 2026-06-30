import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

/// Abre un bottom sheet con el catálogo de tratamientos y devuelve el elegido
/// (o `null` si se cancela).
Future<Tratamiento?> seleccionarTratamiento(
  BuildContext context,
  List<Tratamiento> catalogo,
) {
  return showModalBottomSheet<Tratamiento>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SelectorTratamiento(catalogo: catalogo),
  );
}

/// Si el tratamiento tiene contraindicaciones específicas que coincidan con las 
/// condiciones registradas del paciente, muestra una advertencia bloqueante.
/// Devuelve `true` si se puede asignar, `false` si se cancela.
Future<bool> confirmarRiesgoContraindicaciones(
  BuildContext context,
  Tratamiento tratamiento,
  List<Condicion> condicionesPaciente,
) async {
  // Validación inicial: Si no hay contraindicaciones o el paciente no tiene condiciones, es seguro.
  if (tratamiento.contraindicaciones.isEmpty || condicionesPaciente.isEmpty) {
    return true;
  }

  // Filtrar únicamente las condiciones del paciente que generan conflicto con las contraindicaciones del tratamiento
  final condicionesEnConflicto = condicionesPaciente.where((condicion) {
    return tratamiento.contraindicaciones.any(
      (ci) => ci.condicionId == condicion.id,
    );
  }).toList();

  // Si no hay ninguna coincidencia real, el tratamiento no representa riesgo y se aprueba directamente
  if (condicionesEnConflicto.isEmpty) return true;

  final c = context.appColors;
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.red),
          const SizedBox(width: 8),
          const Expanded(child: Text('Contraindicación Detectada')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${tratamiento.nombre}" está contraindicado para las siguientes condiciones actuales del paciente:',
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 12),
          // Mostramos únicamente las condiciones del paciente que están en conflicto real
          _Bloque(
            c, 
            'Condiciones de riesgo detectadas', 
            condicionesEnConflicto.map((c) => c.nombre).join('\n'),
          ),
          const SizedBox(height: 10),
          ...tratamiento.contraindicaciones.map(
            (ci) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: c.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ci.descripcion,
                      style: TextStyle(color: c.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: c.red),
          child: const Text('Asignar bajo mi responsabilidad'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}

class _Bloque extends StatelessWidget {
  final AppColors c;
  final String titulo;
  final String valor;
  const _Bloque(this.c, this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: c.red,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(valor, style: TextStyle(color: c.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SelectorTratamiento extends StatelessWidget {
  final List<Tratamiento> catalogo;
  const _SelectorTratamiento({required this.catalogo});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Asignar tratamiento',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: c.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (catalogo.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'No hay tratamientos en el catálogo.',
                style: TextStyle(color: c.textMuted),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: catalogo.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TratamientoTile(tratamiento: catalogo[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _TratamientoTile extends StatelessWidget {
  final Tratamiento tratamiento;
  const _TratamientoTile({required this.tratamiento});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final tieneCi = tratamiento.contraindicaciones.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pop(tratamiento),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.searchFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.healing_rounded, size: 18, color: c.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tratamiento.nombre,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RD\$ ${tratamiento.costo.toStringAsFixed(2)}',
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (tieneCi)
              Tooltip(
                message: 'Tiene contraindicaciones',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: c.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}