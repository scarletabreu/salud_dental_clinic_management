import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_cubit.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_state.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/widgets/editor_regla_clinica.dart';

/// Las reglas que disparan las alertas clínicas, editables desde ajustes.
///
/// Sólo la ve quien ejerce clínica: mover un umbral es una decisión médica.
/// La pantalla la monta `ConfiguracionPage`, que ya comprueba la capacidad.
class SeccionReglasClinicas extends StatelessWidget {
  const SeccionReglasClinicas({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReglasClinicasCubit, ReglasClinicasState>(
      listener: (context, state) {
        if (state is! ReglasClinicasCargadas) return;
        final mensaje = state.error ?? state.aviso;
        if (mensaje == null) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: state.error != null
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          );
        context.read<ReglasClinicasCubit>().descartarMensajes();
      },
      builder: (context, state) {
        return switch (state) {
          ReglasClinicasInicial() || ReglasClinicasCargando() =>
            const _Marco(child: _Cargando()),
          ReglasClinicasError(:final mensaje) => _Marco(
            child: _Error(mensaje: mensaje),
          ),
          ReglasClinicasCargadas() => _Marco(child: _Lista(state: state)),
        };
      },
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.rule_folder_outlined, size: 14, color: ac.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'REGLAS CLÍNICAS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ac.primaryGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1.1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(
            onPressed: () => context.read<ReglasClinicasCubit>().cargar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.state});
  final ReglasClinicasCargadas state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reglas = state.reglas;

    if (reglas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No hay reglas clínicas configuradas.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'Umbrales que disparan las alertas durante la consulta. Al publicar '
            'un cambio se guarda una versión nueva firmada; las alertas ya '
            'emitidas conservan la versión con la que se emitieron.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (var i = 0; i < reglas.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          _FilaRegla(
            regla: reglas[i],
            catalogo: state.catalogo,
            publicando: state.publicando == reglas[i].codigo,
            bloqueada: state.publicando != null,
          ),
        ],
      ],
    );
  }
}

class _FilaRegla extends StatelessWidget {
  const _FilaRegla({
    required this.regla,
    required this.catalogo,
    required this.publicando,
    required this.bloqueada,
  });

  final ReglaClinica regla;
  final List<SignoVitalCatalogo> catalogo;
  final bool publicando;
  final bool bloqueada;

  Future<void> _editar(BuildContext context) async {
    final cubit = context.read<ReglasClinicasCubit>();
    final resultado = await EditorReglaClinica.abrir(
      context,
      regla: regla,
      catalogo: catalogo,
    );
    if (resultado == null) return;
    await cubit.publicar(resultado.regla, nota: resultado.nota);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habilitada = regla.editable && !bloqueada;

    return Semantics(
      button: regla.editable,
      label: '${regla.nombre}. ${_resumen()}',
      child: InkWell(
        onTap: habilitada ? () => _editar(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Con el texto ampliado en un móvil estrecho el nombre y
                    // la insignia no caben en la misma línea; un `Wrap` los
                    // baja en vez de desbordar.
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          regla.nombre,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        _Insignia(regla: regla),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _resumen(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (publicando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (regla.editable)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                )
              else
                Tooltip(
                  message: 'Definida por el catálogo de signos vitales',
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qué vigila la regla, en una línea legible.
  String _resumen() {
    final p = regla.parametros;
    switch (regla.tipo) {
      case TipoRegla.valorCritico:
        final partes = <String>[
          if (p.minimo != null) 'por debajo de ${p.minimo}',
          if (p.maximo != null) 'por encima de ${p.maximo}',
        ];
        if (partes.isEmpty) return 'Sin umbral configurado.';
        return 'Avisa ${partes.join(' o ')}.';
      case TipoRegla.combinacionCondicionSigno:
        return 'Con "${p.condicion ?? '—'}": '
            '${p.signos.map(_umbral).join(', ')}.';
      case TipoRegla.requisitoDato:
        final edad = p.edadMaximaAnios;
        return edad == null
            ? 'Exige el dato en toda consulta.'
            : 'Exige el dato en menores de $edad años.';
      case TipoRegla.rangoImposible:
        return 'Rechaza valores fuera de lo físicamente posible.';
      case TipoRegla.relacionImposible:
        return 'Rechaza combinaciones de medidas imposibles.';
    }
  }

  String _umbral(UmbralSigno s) {
    if (s.minimo != null && s.maximo != null) {
      return '${s.codigo} fuera de ${s.minimo}–${s.maximo}';
    }
    if (s.minimo != null) return '${s.codigo} < ${s.minimo}';
    if (s.maximo != null) return '${s.codigo} > ${s.maximo}';
    return '${s.codigo} sin límite';
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia({required this.regla});
  final ReglaClinica regla;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = context.appColors;

    // El estado manda sobre la severidad: una regla sin aprobar no vigila nada,
    // y pintarla de "crítica" haría creer lo contrario.
    final (texto, color) = regla.estaEnVigor
        ? (
            switch (regla.severidad) {
              SeveridadAlerta.absoluta => 'Bloqueante',
              SeveridadAlerta.critica => 'Crítica',
              SeveridadAlerta.advertencia => 'Advertencia',
              SeveridadAlerta.informativa => 'Informativa',
            },
            regla.severidad == SeveridadAlerta.informativa
                ? theme.colorScheme.onSurfaceVariant
                : ac.primaryGreen,
          )
        : ('Sin aprobar', theme.colorScheme.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'v${regla.version} · $texto',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
