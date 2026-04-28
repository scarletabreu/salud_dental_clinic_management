import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

class MedicinaMemoryRepository implements IMedicinaRepository {
  final List<Medicina> _medicinas = [
    Medicina(
      id: 'med-001',
      nombre: 'Amoxicilina 500mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-001',
          condicionId: 'con-001',
          medicinaId: 'med-001',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion: 'Contraindicado en pacientes con alergia a penicilinas.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [
            EfectoAdverso.reaccionAlergica,
            EfectoAdverso.diarrea,
          ],
        ),
      ],
      efectosSecundarios: [EfectoSecundario.nausea, EfectoSecundario.diarrea],
    ),
    Medicina(
      id: 'med-002',
      nombre: 'Ibuprofeno 400mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-002',
          condicionId: 'con-001',
          medicinaId: 'med-002',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion: 'Contraindicado en pacientes con úlcera péptica activa.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [EfectoAdverso.nauseas, EfectoAdverso.dolorCabeza],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.nausea,
        EfectoSecundario.dolorCabeza,
      ],
    ),
  ];

  final Set<String> _deletedIds = {};

  @override
  Future<List<Medicina>> getCatalogoMedicinas() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return _medicinas.where((m) => !_deletedIds.contains(m.id)).toList();
  }

  @override
  Future<void> guardarMedicina(Medicina medicina) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _medicinas.indexWhere((m) => m.id == medicina.id);

    if (index >= 0) {
      _medicinas[index] = medicina;
      _deletedIds.remove(medicina.id);
    } else {
      _medicinas.add(medicina);
    }
  }

  @override
  Future<void> eliminarMedicina(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_medicinas.any((m) => m.id == id)) {
      _deletedIds.add(id);
    } else {
      throw Exception('Medicina no encontrada para eliminar');
    }
  }

  @override
  Future<void> agregarMedicina(Medicina medicina) async {
    if (_deletedIds.contains(medicina.id)) {
      _deletedIds.remove(medicina.id);
      final index = _medicinas.indexWhere((m) => m.id == medicina.id);
      if (index >= 0) _medicinas[index] = medicina;
    } else {
      _medicinas.add(medicina);
    }
  }
}
