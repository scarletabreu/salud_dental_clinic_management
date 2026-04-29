enum EfectoSecundario {
  inflamacion('Inflamación / Edema'),
  sangradoLeve('Sangrado leve'),
  sensibilidadTermica('Sensibilidad térmica (frío/calor)'),
  bocaSeca('Boca seca (Xerostomía)'),
  adormecimientoProlongado('Parestesia (Adormecimiento)'),
  trismo('Trismo (Dificultad para abrir la boca)'),
  hematoma('Hematoma o equimosis'),
  alteracionGusto('Alteración del gusto / Sabor metálico'),
  alveolitis('Alveolitis post-extracción'),

  dolorCabeza('Dolor de cabeza'),
  mareos('Mareos / Vértigo'),
  fatiga('Fatiga'),
  nauseas('Náusea'),
  vomitos('Vómitos'),
  diarrea('Diarrea'),
  reaccionesAlergicas('Reacciones alérgicas'),
  cambiosAnimo('Cambios de ánimo'),
  visionBorrosa('Visión borrosa'),
  insomnio('Insomnio'),
  somnolencia('Somnolencia');

  final String label;
  const EfectoSecundario(this.label);
}
