import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/condicion_medica.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class MedicinaMemoryRepository implements IMedicinaRepository {
  final List<Medicina> _medicinas = [
    Medicina(
      id: 'med-001',
      nombre: 'Amoxicilina 500mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-001',
          condicion: CondicionMedica.alergiaAntibioticos,
          medicinaId: 'med-001',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Contraindicado en pacientes con alergia a penicilinas o cefalosporinas.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [
            EfectoAdverso.reaccionAlergica,
            EfectoAdverso.diarrea,
          ],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.nausea,
        EfectoSecundario.diarrea,
        EfectoSecundario.reaccionesAlergicas,
      ],
    ),
    Medicina(
      id: 'med-002',
      nombre: 'Ibuprofeno 400mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-002',
          condicion: CondicionMedica.ulceraPeptica,
          medicinaId: 'med-002',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Contraindicado en pacientes con úlcera péptica activa o insuficiencia renal grave.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [EfectoAdverso.nauseas, EfectoAdverso.dolorCabeza],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.nausea,
        EfectoSecundario.dolorCabeza,
        EfectoSecundario.mareos,
      ],
    ),
    Medicina(
      id: 'med-003',
      nombre: 'Lidocaína 2% (Anestésico)',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-003',
          condicion: CondicionMedica.arritmia,
          medicinaId: 'med-003',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Usar con precaución en pacientes con arritmias cardíacas o hipotensión.',
          tipoContraindicacion: TipoContraindicacion.relativa,
          efectosAdversos: [EfectoAdverso.fatiga, EfectoAdverso.nauseas],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.adormecimientoProlongado,
        EfectoSecundario.mareos,
        EfectoSecundario.somnolencia,
      ],
    ),
    Medicina(
      id: 'med-004',
      nombre: 'Metronidazol 500mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-004',
          condicion: CondicionMedica.embarazo,
          medicinaId: 'med-004',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion: 'Contraindicado en el primer trimestre del embarazo.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [EfectoAdverso.nauseas, EfectoAdverso.vomitos],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.nausea,
        EfectoSecundario.vomitos,
        EfectoSecundario.bocaSeca,
      ],
    ),
    Medicina(
      id: 'med-005',
      nombre: 'Clindamicina 300mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-005',
          condicion: CondicionMedica.colitis,
          medicinaId: 'med-005',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Contraindicado en pacientes con historial de colitis pseudomembranosa.',
          tipoContraindicacion: TipoContraindicacion.absoluta,
          efectosAdversos: [EfectoAdverso.diarrea, EfectoAdverso.nauseas],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.diarrea,
        EfectoSecundario.nausea,
        EfectoSecundario.reaccionesAlergicas,
      ],
    ),
    Medicina(
      id: 'med-006',
      nombre: 'Paracetamol 500mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-006',
          condicion: CondicionMedica.hepatitis,
          medicinaId: 'med-006',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Usar con precaución en pacientes con enfermedad hepática.',
          tipoContraindicacion: TipoContraindicacion.relativa,
          efectosAdversos: [EfectoAdverso.fatiga],
        ),
      ],
      efectosSecundarios: [EfectoSecundario.nausea, EfectoSecundario.fatiga],
    ),
    Medicina(
      id: 'med-007',
      nombre: 'Dexametasona 4mg',
      contraindicaciones: [
        Contraindicacion(
          id: 'cont-007',
          condicion: CondicionMedica.diabetes,
          medicinaId: 'med-007',
          contraindicacionId: '',
          tratamientoId: '',
          descripcion:
              'Precaución en diabéticos; puede elevar los niveles de glucosa.',
          tipoContraindicacion: TipoContraindicacion.relativa,
          efectosAdversos: [EfectoAdverso.fatiga, EfectoAdverso.nauseas],
        ),
      ],
      efectosSecundarios: [
        EfectoSecundario.insomnio,
        EfectoSecundario.cambiosAnimo,
        EfectoSecundario.inflamacion,
      ],
    ),
  ];

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
