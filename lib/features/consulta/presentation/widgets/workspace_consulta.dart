import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_tratamiento_sheet.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Etapa 2 de "Efectuar consulta": odontograma interactivo, asignación de
/// tratamientos (con chequeo de contraindicaciones) y notas clínicas. Las
/// ediciones del odontograma son visuales (en memoria) en esta versión; la
/// consulta y su odontograma ya quedaron creados en la etapa 1.
class WorkspaceConsulta extends StatefulWidget {
  final String? citaId;

  const WorkspaceConsulta({super.key, this.citaId});

  @override
  State<WorkspaceConsulta> createState() => _WorkspaceConsultaState();
}

class _WorkspaceConsultaState extends State<WorkspaceConsulta> {
  late Odontograma _odontograma;
  final _notasController = TextEditingController();

  List<Tratamiento> _catalogo = const [];
  bool _cargandoCatalogo = true;

  @override
  void initState() {
    super.initState();
    _odontograma = _odontogramaInicial();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Odontograma _odontogramaInicial() {
    return Odontograma(
      consultaId: '',
      dientes: kFdiPermanentes.map((fdi) {
        return Diente(
          odontogramaId: '',
          fdiCode: fdi,
          superficies: superficiesParaFdi(fdi)
              .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
              .toList(),
        );
      }).toList(),
    );
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await sl<TratamientoRepository>().getCatalogoTratamientos();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _cargandoCatalogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoCatalogo = false);
    }
  }

  String _condicionesPaciente() {
    final state = context.read<PacienteCubit>().state;
    if (state is PacienteDetailLoaded) {
      return state.paciente.record.condiciones;
    }
    return '';
  }

  Future<void> _onAddTratamiento(Diente diente, TipoSuperficie? _) async {
    if (_cargandoCatalogo) return;
    final tratamiento = await seleccionarTratamiento(context, _catalogo);
    if (tratamiento == null || !mounted) return;

    final ok = await confirmarRiesgoContraindicaciones(
      context,
      tratamiento,
      _condicionesPaciente(),
    );
    if (!ok || !mounted) return;

    final aplicado = TratamientoAplicado(
      tratamientoId: tratamiento.id ?? '',
      esContinuo: false,
      estaTerminado: false,
    );
    setState(() {
      _odontograma = _odontograma.copyWith(
        dientes: _odontograma.dientes
            .map((d) => d.fdiCode == diente.fdiCode
                ? d.copyWith(tratamientos: [...d.tratamientos, aplicado])
                : d)
            .toList(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${tratamiento.nombre}" asignado al diente ${diente.fdiCode}.'),
      ),
    );
  }

  void _onToggleAusente(Diente diente, bool ausente) {
    setState(() {
      _odontograma = _odontograma.copyWith(
        dientes: _odontograma.dientes
            .map((d) => d.fdiCode == diente.fdiCode
                ? d.copyWith(estaAusente: ausente)
                : d)
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'Odontograma',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona un diente y pulsa "Tratamiento" para asignarlo. '
          'Se verifican contraindicaciones con las condiciones del paciente.',
          style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.3),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [c.cardShadow],
          ),
          child: OdontogramWidget(
            odontograma: _odontograma,
            editMode: true,
            onAddTratamiento: _onAddTratamiento,
            onToggleAusente: _onToggleAusente,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Notas clínicas',
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notasController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Observaciones de la consulta',
            filled: true,
            fillColor: c.searchFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ProximamenteCard(c),
        const SizedBox(height: 24),
        BlocBuilder<ConsultaCubit, ConsultaState>(
          builder: (context, state) {
            final cargando = state is ConsultaLoading;
            return SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: cargando
                    ? null
                    : () => context
                        .read<ConsultaCubit>()
                        .terminarConsulta(citaId: widget.citaId),
                style: FilledButton.styleFrom(backgroundColor: c.primaryBlue),
                icon: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Terminar consulta'),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Aviso de los pasos posteriores a la consulta aún no implementados.
class _ProximamenteCard extends StatelessWidget {
  final AppColors c;
  const _ProximamenteCard(this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: c.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Próximamente: recetas y facturación (pre-factura) al terminar '
              'la consulta.',
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
