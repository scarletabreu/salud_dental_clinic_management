enum EfectoAdverso {
  nauseas,
  vomitos,
  diarrea,
  dolor_cabeza,
  fatiga,
  reaccion_alergica;

  String get name {
    switch (this) {
      case EfectoAdverso.nauseas:
        return 'Náuseas';
      case EfectoAdverso.vomitos:
        return 'Vómitos';
      case EfectoAdverso.diarrea:
        return 'Diarrea';
      case EfectoAdverso.dolor_cabeza:
        return 'Dolor de cabeza';
      case EfectoAdverso.fatiga:
        return 'Fatiga';
      case EfectoAdverso.reaccion_alergica:
        return 'Reacción alérgica';
    }
  }
}