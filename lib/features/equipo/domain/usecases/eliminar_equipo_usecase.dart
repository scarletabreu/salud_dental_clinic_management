import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';

class EliminarEquipoUseCase {
  final EquipoRepository repository;

  EliminarEquipoUseCase({required this.repository});

  Future<void> call(String id) => repository.eliminarEquipo(id);
}
