import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';

/// Diálogo donde el doctor mueve el umbral de una regla clínica.
///
/// Valida lo mismo que la base y con los mismos límites, pero antes de enviar:
/// un umbral fuera del rango del catálogo no alertaría nunca, y descubrirlo por
/// un error del servidor obliga a rehacer el formulario. La base sigue siendo
/// la autoridad —esto es comodidad, no permiso—.
class EditorReglaClinica extends StatefulWidget {
  const EditorReglaClinica({
    super.key,
    required this.regla,
    required this.catalogo,
  });

  final ReglaClinica regla;
  final List<SignoVitalCatalogo> catalogo;

  /// Devuelve la regla editada y la nota, o `null` si se cancela.
  static Future<({ReglaClinica regla, String? nota})?> abrir(
    BuildContext context, {
    required ReglaClinica regla,
    required List<SignoVitalCatalogo> catalogo,
  }) {
    return showDialog<({ReglaClinica regla, String? nota})>(
      context: context,
      builder: (_) => EditorReglaClinica(regla: regla, catalogo: catalogo),
    );
  }

  @override
  State<EditorReglaClinica> createState() => _EditorReglaClinicaState();
}

class _EditorReglaClinicaState extends State<EditorReglaClinica> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nota;

  /// Un controlador por campo numérico, indexado por una clave estable
  /// (`min`, `max`, `pulso.max`…). Los campos dependen del tipo de regla, así
  /// que declararlos uno a uno duplicaría el `switch` de la entidad.
  final Map<String, TextEditingController> _numericos = {};

  late SeveridadAlerta _severidad;
  late AccionAlerta _accion;

  @override
  void initState() {
    super.initState();
    _nota = TextEditingController();
    _severidad = widget.regla.severidad;
    _accion = widget.regla.accion;

    final p = widget.regla.parametros;
    switch (widget.regla.tipo) {
      case TipoRegla.valorCritico:
        _controlador('min', p.minimo);
        _controlador('max', p.maximo);
      case TipoRegla.combinacionCondicionSigno:
        for (final signo in p.signos) {
          _controlador('${signo.codigo}.min', signo.minimo);
          _controlador('${signo.codigo}.max', signo.maximo);
        }
      case TipoRegla.requisitoDato:
        _controlador('edad_max', p.edadMaximaAnios);
      case TipoRegla.rangoImposible:
      case TipoRegla.relacionImposible:
        break;
    }
  }

  TextEditingController _controlador(String clave, num? valor) =>
      _numericos.putIfAbsent(
        clave,
        () => TextEditingController(text: valor?.toString() ?? ''),
      );

  num? _valor(String clave) {
    final texto = _numericos[clave]?.text.trim() ?? '';
    return texto.isEmpty ? null : num.tryParse(texto);
  }

  @override
  void dispose() {
    _nota.dispose();
    for (final c in _numericos.values) {
      c.dispose();
    }
    super.dispose();
  }

  SignoVitalCatalogo? _signo(String? codigo) {
    if (codigo == null) return null;
    for (final s in widget.catalogo) {
      if (s.codigo == codigo) return s;
    }
    return null;
  }

  /// Reconstruye los parámetros a partir de los campos.
  ParametrosRegla _parametrosEditados() {
    final p = widget.regla.parametros;
    switch (widget.regla.tipo) {
      case TipoRegla.valorCritico:
        return p.copyWith(
          minimo: _valor('min'),
          maximo: _valor('max'),
          limpiarMinimo: _valor('min') == null,
          limpiarMaximo: _valor('max') == null,
        );
      case TipoRegla.combinacionCondicionSigno:
        return p.copyWith(
          signos: [
            for (final signo in p.signos)
              UmbralSigno(
                codigo: signo.codigo,
                minimo: _valor('${signo.codigo}.min'),
                maximo: _valor('${signo.codigo}.max'),
              ),
          ],
        );
      case TipoRegla.requisitoDato:
        final edad = _valor('edad_max');
        return p.copyWith(
          edadMaximaAnios: edad,
          limpiarEdadMaxima: edad == null,
        );
      case TipoRegla.rangoImposible:
      case TipoRegla.relacionImposible:
        return p;
    }
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parametros = _parametrosEditados();

    // Una regla sin ningún límite no vigila nada. La base la rechaza; decirlo
    // aquí evita que el doctor crea que la ha dejado activa.
    final sinLimites = switch (widget.regla.tipo) {
      TipoRegla.valorCritico =>
        parametros.minimo == null && parametros.maximo == null,
      TipoRegla.combinacionCondicionSigno =>
        parametros.signos.every((s) => !s.tieneLimite),
      _ => false,
    };
    if (sinLimites) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La regla necesita al menos un límite; si no, no avisaría nunca.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop((
      regla: widget.regla.copyWith(
        parametros: parametros,
        severidad: _severidad,
        accion: _accion,
      ),
      nota: _nota.text.trim().isEmpty ? null : _nota.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = context.appColors;

    return AppDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.regla.nombre, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${widget.regla.codigo} · versión ${widget.regla.version}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.regla.descripcion != null) ...[
              Text(
                widget.regla.descripcion!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ..._camposDeUmbral(),
            const SizedBox(height: 20),
            Text(
              'Qué se le pide al doctor',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ac.primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            AppFormRow(
              children: [
                DropdownButtonFormField<SeveridadAlerta>(
                  initialValue: _severidad,
                  decoration: const InputDecoration(
                    labelText: 'Severidad',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in SeveridadAlerta.values)
                      DropdownMenuItem(value: s, child: Text(s.etiqueta)),
                  ],
                  onChanged: (v) => setState(() => _severidad = v ?? _severidad),
                ),
                DropdownButtonFormField<AccionAlerta>(
                  initialValue: _accion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Acción exigida',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final a in AccionAlerta.values)
                      DropdownMenuItem(value: a, child: Text(a.etiqueta)),
                  ],
                  onChanged: (v) => setState(() => _accion = v ?? _accion),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _accion.bloqueaCierre
                  ? 'La consulta no se podrá cerrar mientras esta alerta siga pendiente.'
                  : 'La alerta se mostrará, pero no impedirá cerrar la consulta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nota,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo del cambio (opcional)',
                helperText: 'Queda registrado junto a la versión publicada.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Publicar')),
      ],
    );
  }

  List<Widget> _camposDeUmbral() {
    final theme = Theme.of(context);
    final p = widget.regla.parametros;

    switch (widget.regla.tipo) {
      case TipoRegla.valorCritico:
        final signo = _signo(p.codigoSigno);
        return [
          _EtiquetaSigno(signo: signo, codigo: p.codigoSigno),
          const SizedBox(height: 10),
          AppFormRow(
            children: [
              _campoNumerico(
                clave: 'min',
                etiqueta: 'Avisar por debajo de',
                signo: signo,
              ),
              _campoNumerico(
                clave: 'max',
                etiqueta: 'Avisar por encima de',
                signo: signo,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Deja un campo vacío para no vigilar ese extremo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ];

      case TipoRegla.combinacionCondicionSigno:
        return [
          Text(
            'Se activa en pacientes con "${p.condicion ?? '—'}" registrada.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          for (final umbral in p.signos) ...[
            _EtiquetaSigno(signo: _signo(umbral.codigo), codigo: umbral.codigo),
            const SizedBox(height: 8),
            AppFormRow(
              children: [
                _campoNumerico(
                  clave: '${umbral.codigo}.min',
                  etiqueta: 'Por debajo de',
                  signo: _signo(umbral.codigo),
                ),
                _campoNumerico(
                  clave: '${umbral.codigo}.max',
                  etiqueta: 'Por encima de',
                  signo: _signo(umbral.codigo),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ];

      case TipoRegla.requisitoDato:
        final signo = _signo(p.codigoSigno);
        return [
          Text(
            'Exige registrar ${signo?.etiqueta.toLowerCase() ?? p.codigoSigno ?? 'el dato'} '
            'antes de cerrar la consulta.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _campoNumerico(
            clave: 'edad_max',
            etiqueta: 'Sólo en pacientes menores de (años)',
          ),
          const SizedBox(height: 6),
          Text(
            'Vacío significa que se exige a cualquier edad.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ];

      case TipoRegla.rangoImposible:
      case TipoRegla.relacionImposible:
        return [
          Text(
            'Esta regla no tiene umbral configurable: se apoya en el catálogo '
            'de signos vitales.',
            style: theme.textTheme.bodyMedium,
          ),
        ];
    }
  }

  Widget _campoNumerico({
    required String clave,
    required String etiqueta,
    SignoVitalCatalogo? signo,
  }) {
    final decimales = signo?.decimales ?? 0;
    return TextFormField(
      controller: _controlador(clave, null),
      keyboardType: TextInputType.numberWithOptions(decimal: decimales > 0),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimales > 0 ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      decoration: InputDecoration(
        labelText: etiqueta,
        suffixText: signo?.unidad,
        border: const OutlineInputBorder(),
      ),
      validator: (texto) {
        final valor = texto?.trim() ?? '';
        if (valor.isEmpty) return null;
        final numero = num.tryParse(valor);
        if (numero == null) return 'Número no válido';

        // Un umbral fuera de lo que el catálogo considera medible no se
        // alcanzaría jamás: la alerta existiría y no sonaría nunca.
        if (signo != null && !signo.contiene(numero)) {
          return 'Entre ${signo.minimoPosible} y ${signo.maximoPosible}';
        }
        return null;
      },
    );
  }
}

class _EtiquetaSigno extends StatelessWidget {
  const _EtiquetaSigno({required this.signo, required this.codigo});

  final SignoVitalCatalogo? signo;
  final String? codigo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = context.appColors;
    return Row(
      children: [
        Icon(Icons.monitor_heart_outlined, size: 15, color: ac.primaryGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            signo?.etiqueta ?? codigo ?? '—',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (signo != null)
          Text(
            'posible: ${signo!.minimoPosible}–${signo!.maximoPosible} ${signo!.unidad}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
