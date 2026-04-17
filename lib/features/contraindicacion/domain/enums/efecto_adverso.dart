enum EfectoAdverso {
  // Gastrointestinales
  nauseas,
  vomitos,
  diarrea,

  // Sistémicos
  dolorCabeza,
  fatiga,
  mareo,
  somnolencia,

  // Alérgicos y Dermatológicos
  reaccionAlergica,
  erupcionCutanea,
  anafilaxia,

  // Específicos Orales
  xerostomia,
  hiperplasiaGingival,
  saborMetalico,
  parestesia,
  sangradoAumentado;

  String get label {
    return switch (this) {
      EfectoAdverso.nauseas => 'Náuseas',
      EfectoAdverso.vomitos => 'Vómitos',
      EfectoAdverso.diarrea => 'Diarrea',
      EfectoAdverso.dolorCabeza => 'Cefalea (Dolor de cabeza)',
      EfectoAdverso.fatiga => 'Fatiga / Astenia',
      EfectoAdverso.mareo => 'Mareo o Síncope',
      EfectoAdverso.somnolencia => 'Somnolencia',
      EfectoAdverso.reaccionAlergica => 'Reacción alérgica leve',
      EfectoAdverso.erupcionCutanea => 'Erupción o Urticaria',
      EfectoAdverso.anafilaxia => 'Shock Anafiláctico',
      EfectoAdverso.xerostomia => 'Xerostomía (Boca seca)',
      EfectoAdverso.hiperplasiaGingival => 'Hiperplasia Gingival',
      EfectoAdverso.saborMetalico => 'Alteración del gusto (Sabor metálico)',
      EfectoAdverso.parestesia => 'Parestesia (Adormecimiento)',
      EfectoAdverso.sangradoAumentado => 'Sangrado persistente',
    };
  }
}
