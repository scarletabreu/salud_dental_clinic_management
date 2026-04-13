import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class MedicinaMemoryRepository implements IMedicinaRepository {
  final List<Medicina> _medicinas = [];

  @override
  Future<Either<Failure, List<Medicina>>> getMedicinas() async {
    return Right(List.from(_medicinas));
  }

  @override
  Future<Either<Failure, void>> addMedicina(Medicina medicina) async {
    _medicinas.add(medicina);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateMedicina(Medicina medicina) async {
    final index = _medicinas.indexWhere((m) => m.id == medicina.id);
    if (index >= 0) _medicinas[index] = medicina;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteMedicina(String id) async {
    _medicinas.removeWhere((m) => m.id == id);
    return const Right(null);
  }
}
