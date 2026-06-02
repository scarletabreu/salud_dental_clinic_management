import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

// ─────────────────────────────────────────────
//  DEMO DATA — borrar al conectar datos reales.
//  Odontograma de ejemplo con casos clínicos variados para previsualizar
//  el widget: diagnósticos por severidad, tratamientos (terminados y en
//  curso), superficies afectadas, dientes ausentes y observaciones.
//  Cubre ambas arcadas y ambas mitades (para probar paneles laterales).
// ─────────────────────────────────────────────

Odontograma buildSampleOdontograma() {
  final hoy = DateTime(2026, 5, 20);

  DiagnosticoAplicado dx(SeveridadDiagnosis sev, String notas) =>
      DiagnosticoAplicado(
        diagnosisId: 'demo-dx',
        severidad: sev,
        fechaAplicacion: hoy,
        notas: notas,
      );

  TratamientoAplicado tx({required bool continuo, required bool terminado}) =>
      TratamientoAplicado(
        tratamientoId: 'demo-tx',
        esContinuo: continuo,
        estaTerminado: terminado,
      );

  Superficie surf(
    int fdi,
    TipoSuperficie tipo, {
    bool diagnosticada = false,
    bool tratada = false,
  }) =>
      Superficie(
        dienteId: '$fdi',
        tipoSuperficie: tipo,
        diagnosisId: diagnosticada ? 'demo-dx' : null,
        tratamientos: tratada ? const ['demo-tx'] : const [],
      );

  Diente diente(
    int fdi, {
    List<Superficie> superficies = const [],
    List<DiagnosticoAplicado> diagnosis = const [],
    List<TratamientoAplicado> tratamientos = const [],
    String? observaciones,
    bool ausente = false,
  }) =>
      Diente(
        odontogramaId: 'demo',
        fdiCode: fdi,
        superficies: superficies,
        diagnosis: diagnosis,
        tratamientos: tratamientos,
        observaciones: observaciones,
        estaAusente: ausente,
      );

  return Odontograma(
    consultaId: 'demo',
    dientes: [
      // ── Mitad izquierda (cuadrantes 1 y 4) ──
      // Crítico: caries profunda + endodoncia en curso.
      diente(
        16,
        diagnosis: [dx(SeveridadDiagnosis.grave, 'Caries profunda con compromiso pulpar')],
        tratamientos: [tx(continuo: true, terminado: false)],
        superficies: [
          surf(16, TipoSuperficie.oclusal, diagnosticada: true),
          surf(16, TipoSuperficie.distal, diagnosticada: true),
        ],
        observaciones: 'Sensibilidad al frío. Pendiente endodoncia (1.ª sesión hecha).',
      ),
      // Crítico: fractura coronaria.
      diente(
        17,
        diagnosis: [dx(SeveridadDiagnosis.grave, 'Fractura coronaria')],
        superficies: [surf(17, TipoSuperficie.oclusal, diagnosticada: true)],
      ),
      // Leve: caries inicial solo en una superficie.
      diente(
        14,
        superficies: [surf(14, TipoSuperficie.distal, diagnosticada: true)],
      ),
      // Moderado: fractura de esmalte en incisivo.
      diente(
        11,
        diagnosis: [dx(SeveridadDiagnosis.moderada, 'Fractura de esmalte')],
        superficies: [surf(11, TipoSuperficie.incisal, diagnosticada: true)],
      ),
      // Tratado en curso: resina + tratamiento continuo no terminado.
      diente(
        46,
        tratamientos: [tx(continuo: true, terminado: false)],
        superficies: [surf(46, TipoSuperficie.oclusal, tratada: true)],
        observaciones: 'Restauración en proceso.',
      ),
      // Tratado terminado en una superficie.
      diente(
        47,
        tratamientos: [tx(continuo: false, terminado: true)],
        superficies: [surf(47, TipoSuperficie.oclusal, tratada: true)],
      ),
      // Solo superficie diagnosticada (vestibular).
      diente(
        41,
        superficies: [surf(41, TipoSuperficie.vestibular, diagnosticada: true)],
      ),
      // Ausente: cordal extraído.
      diente(48, ausente: true),

      // ── Mitad derecha (cuadrantes 2 y 3) ──
      // Tratado terminado: corona.
      diente(
        26,
        tratamientos: [tx(continuo: false, terminado: true)],
        superficies: [surf(26, TipoSuperficie.oclusal, tratada: true)],
        observaciones: 'Corona de porcelana colocada.',
      ),
      // Moderado con observación.
      diente(
        24,
        diagnosis: [dx(SeveridadDiagnosis.moderada, 'Caries interproximal')],
        superficies: [surf(24, TipoSuperficie.mesial, diagnosticada: true)],
        observaciones: 'Vigilar evolución en próxima cita.',
      ),
      // Leve: mancha blanca.
      diente(
        21,
        diagnosis: [dx(SeveridadDiagnosis.leve, 'Mancha blanca / caries incipiente')],
        superficies: [surf(21, TipoSuperficie.mesial, diagnosticada: true)],
      ),
      // Tratado terminado, sin superficies marcadas.
      diente(
        23,
        tratamientos: [tx(continuo: false, terminado: true)],
      ),
      // Leve: gingivitis localizada.
      diente(
        31,
        diagnosis: [dx(SeveridadDiagnosis.leve, 'Gingivitis localizada')],
      ),
      // Ausentes.
      diente(36, ausente: true),
      diente(38, ausente: true),
    ],
  );
}
