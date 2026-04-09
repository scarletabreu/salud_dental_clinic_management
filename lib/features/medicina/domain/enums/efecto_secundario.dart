enum EfectoSecundario {
  dolorCabeza,
  mareos,
  fatiga,
  nausea,
  vomitos,
  diarrea,
  reaccionesAlergicas,
  cambiosAnimo,
  visionBorrosa,
  insomnio,
  inflamacion,
  sangradoLeve,
  sensibilidadTermica,
  bocaSeca,
  adormecimientoProlongado,
  somnolencia;

  String get nombre {
    switch (this) {
      case EfectoSecundario.dolorCabeza:
        return 'Dolor de cabeza';
      case EfectoSecundario.mareos:
        return 'Mareos';
      case EfectoSecundario.fatiga:
        return 'Fatiga';
      case EfectoSecundario.nausea:
        return 'Náusea';
      case EfectoSecundario.vomitos:
        return 'Vómitos';
      case EfectoSecundario.diarrea:
        return 'Diarrea';
      case EfectoSecundario.reaccionesAlergicas:
        return 'Reacciones alérgicas';
      case EfectoSecundario.cambiosAnimo:
        return 'Cambios de ánimo';
      case EfectoSecundario.visionBorrosa:
        return 'Visión borrosa';
      case EfectoSecundario.insomnio:
        return 'Insomnio';
      case EfectoSecundario.inflamacion:
        return 'Inflamación';
      case EfectoSecundario.sangradoLeve:
        return 'Sangrado leve';
      case EfectoSecundario.sensibilidadTermica:
        return 'Sensibilidad térmica';
      case EfectoSecundario.bocaSeca:
        return 'Boca seca';
      case EfectoSecundario.adormecimientoProlongado:
        return 'Adormecimiento prolongado';
      case EfectoSecundario.somnolencia:
        return 'Somnolencia';
    }
  }
}