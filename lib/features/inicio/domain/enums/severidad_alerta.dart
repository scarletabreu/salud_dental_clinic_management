enum SeveridadAlerta {
  critica,
  alta,
  media,
  baja;

  int get prioridad => switch (this) {
    SeveridadAlerta.critica => 0,
    SeveridadAlerta.alta => 1,
    SeveridadAlerta.media => 2,
    SeveridadAlerta.baja => 3,
  };
}
