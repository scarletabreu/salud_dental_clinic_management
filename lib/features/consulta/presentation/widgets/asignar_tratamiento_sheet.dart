import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

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
                itemBuilder: (_, i) =>
                    _TratamientoTile(tratamiento: catalogo[i]),
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
                    // El alcance explica por qué unos tratamientos toman la
                    // cara marcada y otros la ignoran: es del catálogo, no un
                    // descuido de la pantalla.
                    tratamiento.alcance == Alcance.puntual
                        ? 'RD\$ ${tratamiento.costo.toStringAsFixed(2)} · por cara'
                        : 'RD\$ ${tratamiento.costo.toStringAsFixed(2)} · '
                              'pieza completa',
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
