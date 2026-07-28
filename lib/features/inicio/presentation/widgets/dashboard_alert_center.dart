// lib/features/inicio/presentation/widgets/dashboard_alert_center.dart
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/entities/alerta_operativa.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/entidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/severidad_alerta.dart';

/// Centro de alertas: recibe alertas ya generadas como datos (tipo,
/// severidad, entidad destino) y solo filtra por rol, ordena por prioridad
/// y enruta el tap. El estilo (color/pulso) se deriva de la severidad más
/// alta presente — no hay texto ni umbrales de negocio hardcodeados aquí.
class DashboardAlertCenter extends StatefulWidget {
  const DashboardAlertCenter({
    super.key,
    required this.alertas,
    required this.rolesUsuario,
    this.onAlertaCita,
    this.onAlertaConsumible,
    this.onAlertaCaja,
    this.onAlertaEquipo,
  });

  final List<AlertaOperativa> alertas;
  final List<RolUsuario> rolesUsuario;
  final VoidCallback? onAlertaCita;
  final VoidCallback? onAlertaConsumible;
  final VoidCallback? onAlertaCaja;
  final VoidCallback? onAlertaEquipo;

  @override
  State<DashboardAlertCenter> createState() => _DashboardAlertCenterState();
}

class _DashboardAlertCenterState extends State<DashboardAlertCenter>
    with SingleTickerProviderStateMixin {
  static const _limiteColapsado = 4;
  bool _expandido = false;
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    // Pulso sutil en el indicador cuando hay alertas críticas, para que el
    // panel se note de un vistazo sin depender solo del color.
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  /// Arranca o detiene el pulso según haga falta.
  ///
  /// SD-132: antes el controlador hacía `repeat()` en `initState` y no paraba
  /// nunca. El punto solo se dibuja si hay alertas críticas, pero el
  /// controlador seguía pidiendo un frame cada 16 ms toda la sesión —con el
  /// inicio abierto o retenido en segundo plano—, gastando batería por un
  /// dibujo que nadie estaba viendo. Y como no cesaba, `pumpAndSettle` nunca
  /// terminaba: las pruebas del inicio no podían pasar de ahí.
  void _sincronizarPulso(bool hayCriticas) {
    if (hayCriticas) {
      if (!_pulso.isAnimating) _pulso.repeat(reverse: true);
    } else if (_pulso.isAnimating) {
      _pulso.stop();
      _pulso.value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    final visibles = widget.alertas
        .where((a) => a.esVisibleParaRoles(widget.rolesUsuario))
        .toList();
    final mostrar = _expandido
        ? visibles
        : visibles.take(_limiteColapsado).toList();

    final hayCriticas = visibles.any(
      (a) => a.severidad == SeveridadAlerta.critica,
    );
    _sincronizarPulso(hayCriticas);
    final colorPrincipal = visibles.isEmpty
        ? ac.textSecondary
        : _colorSeveridadMasAlta(visibles, ac);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        // AÑADIDO: borde de color cuando hay alertas, más notorio si hay
        // críticas — es lo primero que distingue este panel del resto.
        border: visibles.isNotEmpty
            ? Border.all(
                color: colorPrincipal.withValues(
                  alpha: hayCriticas ? 0.55 : 0.3,
                ),
                width: hayCriticas ? 1.6 : 1.2,
              )
            : null,
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: visibles.isNotEmpty
                ? colorPrincipal.withValues(alpha: 0.07)
                : null,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                if (hayCriticas)
                  // El punto se redibuja 60 veces por segundo. Sin frontera,
                  // arrastra en cada frame a la cabecera entera: título,
                  // contador y el borde con sombra de la tarjeta.
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pulso,
                      builder: (context, _) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          color: ac.red.withValues(
                            alpha: 0.45 + (_pulso.value * 0.55),
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ac.red.withValues(
                                alpha: 0.5 * _pulso.value,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: visibles.isEmpty ? ac.textPrimary : colorPrincipal,
                  ),
                const SizedBox(width: 8),
                // `Expanded` hace el trabajo del `Spacer` que había aquí y
                // además cede espacio: con el título fijo, a 320 px o con el
                // texto ampliado la fila se salía 45 px y el contador quedaba
                // fuera de pantalla.
                Expanded(
                  child: Text(
                    'Centro de Alertas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (visibles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrincipal,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrincipal.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${visibles.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: ac.divider),
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Sin alertas operativas por ahora',
                  style: TextStyle(color: ac.textSecondary, fontSize: 13),
                ),
              ),
            )
          else ...[
            for (int i = 0; i < mostrar.length; i++) ...[
              _AlertaTile(
                alerta: mostrar[i],
                ac: ac,
                onTap: () => _onTapAlerta(mostrar[i]),
              ),
              if (i < mostrar.length - 1)
                Divider(height: 1, color: ac.divider, indent: 56),
            ],
            if (visibles.length > _limiteColapsado)
              InkWell(
                onTap: () => setState(() => _expandido = !_expandido),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      _expandido
                          ? 'Ver menos'
                          : 'Ver ${visibles.length - _limiteColapsado} más',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ac.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _onTapAlerta(AlertaOperativa alerta) {
    switch (alerta.entidadTipo) {
      case EntidadAlerta.cita:
        widget.onAlertaCita?.call();
      case EntidadAlerta.consumible:
        widget.onAlertaConsumible?.call();
      case EntidadAlerta.cajaDiaria:
        widget.onAlertaCaja?.call();
      case EntidadAlerta.equipo:
        widget.onAlertaEquipo?.call();
    }
  }

  Color _colorSeveridadMasAlta(List<AlertaOperativa> alertas, AppColors ac) {
    final masAlta = alertas
        .map((a) => a.severidad)
        .reduce((a, b) => a.prioridad <= b.prioridad ? a : b);
    return _colorSeveridad(masAlta, ac);
  }
}

Color _colorSeveridad(SeveridadAlerta severidad, AppColors ac) {
  return switch (severidad) {
    SeveridadAlerta.critica => ac.red,
    SeveridadAlerta.alta => ac.amber,
    SeveridadAlerta.media => ac.indigo,
    SeveridadAlerta.baja => ac.textSecondary,
  };
}

class _AlertaTile extends StatelessWidget {
  const _AlertaTile({
    required this.alerta,
    required this.ac,
    required this.onTap,
  });

  final AlertaOperativa alerta;
  final AppColors ac;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorSeveridad(alerta.severidad, ac);
    final esCritica = alerta.severidad == SeveridadAlerta.critica;

    return InkWell(
      onTap: onTap,
      child: Container(
        // AÑADIDO: fondo tenue en filas críticas — se distinguen sin tener
        // que leer el texto primero.
        color: esCritica ? ac.red.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            esCritica
                ? Icon(Icons.error_rounded, size: 16, color: color)
                : Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: esCritica ? FontWeight.w700 : FontWeight.w600,
                      color: esCritica ? color : ac.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alerta.descripcion,
                    style: TextStyle(fontSize: 12, color: ac.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ac.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
