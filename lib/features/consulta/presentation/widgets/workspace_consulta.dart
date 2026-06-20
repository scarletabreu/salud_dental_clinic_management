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
      final catalogo = await sl<TratamientoRepository>()
          .getCatalogoTratamientos();
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

  Future<void> _onAddTratamiento(
    Diente diente,
    TipoSuperficie? superficie,
  ) async {
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
      superficie: superficie,
      precioAplicado: tratamiento.costo,
    );
    setState(() {
      _odontograma = _odontograma.copyWith(
        dientes: _odontograma.dientes
            .map(
              (d) => d.fdiCode == diente.fdiCode
                  ? d.copyWith(tratamientos: [...d.tratamientos, aplicado])
                  : d,
            )
            .toList(),
      );
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${tratamiento.nombre}" asignado al diente ${diente.fdiCode}.',
        ),
        backgroundColor: context.appColors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onToggleAusente(Diente diente, bool ausente) {
    setState(() {
      _odontograma = _odontograma.copyWith(
        dientes: _odontograma.dientes
            .map(
              (d) => d.fdiCode == diente.fdiCode
                  ? d.copyWith(estaAusente: ausente)
                  : d,
            )
            .toList(),
      );
    });
  }

  int get _totalTratamientos =>
      _odontograma.dientes.fold(0, (sum, d) => sum + d.tratamientos.length);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ac.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '02',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consulta en curso',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ac.textPrimary,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Registra tratamientos en el odontograma y añade tus notas',
                    style: TextStyle(
                      fontSize: 12,
                      color: ac.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_totalTratamientos > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ac.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ac.teal.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.healing_rounded, size: 12, color: ac.teal),
                    const SizedBox(width: 5),
                    Text(
                      '$_totalTratamientos tratamiento${_totalTratamientos > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ac.teal,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.divider.withValues(alpha: 0.6)),
            boxShadow: [ac.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ac.teal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 17,
                      color: ac.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Odontograma',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ac.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toca un diente para asignar tratamientos',
                          style: TextStyle(fontSize: 11, color: ac.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_cargandoCatalogo)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ac.teal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              OdontogramWidget(
                odontograma: _odontograma,
                editMode: true,
                onAddTratamiento: _onAddTratamiento,
                onToggleAusente: _onToggleAusente,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.divider.withValues(alpha: 0.6)),
            boxShadow: [ac.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ac.indigo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      size: 17,
                      color: ac.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas clínicas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ac.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Observaciones para el expediente',
                        style: TextStyle(fontSize: 11, color: ac.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _notasController,
                minLines: 4,
                maxLines: 7,
                style: TextStyle(
                  fontSize: 14,
                  color: ac.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Observaciones, hallazgos adicionales, indicaciones…',
                  hintStyle: TextStyle(
                    color: ac.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: ac.bgPage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
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
                    borderSide: BorderSide(color: ac.indigo, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _ProximamenteCard(ac),
        const SizedBox(height: 28),

        BlocBuilder<ConsultaCubit, ConsultaState>(
          builder: (context, state) {
            final cargando = state is ConsultaLoading;
            return _TerminarButton(
              cargando: cargando,
              onTap: cargando
                  ? null
                  : () => context.read<ConsultaCubit>().terminarConsulta(
                      citaId: widget.citaId,
                      odontograma: _odontograma,
                      notas: _notasController.text,
                    ),
              ac: ac,
            );
          },
        ),
      ],
    );
  }
}

class _ProximamenteCard extends StatelessWidget {
  const _ProximamenteCard(this.ac);
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ac.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.amber.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ac.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule_rounded, size: 15, color: ac.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Próximamente: recetas y facturación al terminar la consulta.',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminarButton extends StatelessWidget {
  const _TerminarButton({
    required this.cargando,
    required this.onTap,
    required this.ac,
  });
  final bool cargando;
  final VoidCallback? onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: ac.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        icon: cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(cargando ? 'Finalizando…' : 'Terminar consulta'),
      ),
    );
  }
}
