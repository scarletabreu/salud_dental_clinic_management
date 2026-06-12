import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';

/// Carga los nombres del catálogo para los tratamientos aplicados que el
/// odontograma de la consulta referencia por id.
class ConsultaDetalleCubit extends Cubit<ConsultaDetalleState> {
  final ConsultaRepository _repository;

  ConsultaDetalleCubit(this._repository)
    : super(const ConsultaDetalleCargando());

  Future<void> cargar(Consulta consulta) async {
    final ids = <String>[
      for (final diente in consulta.odontograma?.dientes ?? const <Diente>[])
        ...diente.tratamientosAplicadosIds,
    ];

    if (ids.isEmpty) {
      emit(const ConsultaDetalleListo({}));
      return;
    }

    emit(const ConsultaDetalleCargando());
    try {
      final nombres = await _repository.getNombresTratamientosAplicados(ids);
      emit(ConsultaDetalleListo(nombres));
    } catch (_) {
      // Degrada sin nombres: el detalle se muestra igual con un genérico.
      emit(const ConsultaDetalleListo({}));
    }
  }
}

abstract class ConsultaDetalleState extends Equatable {
  const ConsultaDetalleState();

  @override
  List<Object?> get props => [];
}

class ConsultaDetalleCargando extends ConsultaDetalleState {
  const ConsultaDetalleCargando();
}

class ConsultaDetalleListo extends ConsultaDetalleState {
  /// id de tratamiento aplicado → nombre del tratamiento del catálogo.
  final Map<String, String> nombresTratamientos;

  const ConsultaDetalleListo(this.nombresTratamientos);

  String nombreDe(String tratamientoAplicadoId) =>
      nombresTratamientos[tratamientoAplicadoId] ?? 'Tratamiento';

  @override
  List<Object?> get props => [nombresTratamientos];
}
