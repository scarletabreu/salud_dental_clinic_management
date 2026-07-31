import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';

/// Bottom sheet de búsqueda de medicinas del catálogo, calcado del patrón
/// de seleccionarTratamiento (asignar_tratamiento_sheet.dart).
Future<Medicina?> seleccionarMedicina(
  BuildContext context,
  List<Medicina> catalogo,
) {
  return showModalBottomSheet<Medicina>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MedicinaSheetContent(catalogo: catalogo),
  );
}

class _MedicinaSheetContent extends StatefulWidget {
  final List<Medicina> catalogo;
  const _MedicinaSheetContent({required this.catalogo});

  @override
  State<_MedicinaSheetContent> createState() => _MedicinaSheetContentState();
}

class _MedicinaSheetContentState extends State<_MedicinaSheetContent> {
  final _searchController = TextEditingController();
  late List<Medicina> _filtradas = widget.catalogo;

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtradas = q.isEmpty
          ? widget.catalogo
          : widget.catalogo
                .where((m) => m.nombre.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        // El fondo lo pone un Material y no un BoxDecoration: las filas del
        // catálogo son ListTile y pintan su realce sobre el Material más
        // cercano, que aquí era el de la hoja modal —transparente— y quedaba
        // tapado por este contenedor. En debug eso no era un detalle estético:
        // el framework lanzaba una aserción y el selector de medicinas no
        // llegaba a abrirse (HFX-CLIN-005).
        return Material(
          color: ac.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ac.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Buscar medicina',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Nombre de la medicina…',
                    prefixIcon: Icon(Icons.search_rounded, color: ac.textMuted),
                    filled: true,
                    fillColor: ac.bgPage,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ac.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ac.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ac.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtradas.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados.',
                          style: TextStyle(color: ac.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        itemCount: _filtradas.length,
                        itemBuilder: (ctx, i) {
                          final m = _filtradas[i];
                          return ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: ac.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.medication_rounded,
                                size: 18,
                                color: ac.primaryGreen,
                              ),
                            ),
                            title: Text(
                              m.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ac.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: m.contraindicaciones.isNotEmpty
                                ? Text(
                                    '${m.contraindicaciones.length} contraindicación(es) registrada(s)',
                                    style: TextStyle(
                                      color: ac.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(m),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
