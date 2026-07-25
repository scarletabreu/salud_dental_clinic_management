import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';

/// Superficie sobre la que se dibuja el odontodiagrama y las tintas con las que
/// se anota.
///
/// El dato clínico es *qué* tinta usa cada clave —la roja, la azul, la negra—,
/// no su valor RGB. Sobre papel blanco valen los colores impresos; sobre el
/// papel oscuro del tema hay que subir la luminancia o la tinta roja se hunde
/// en el fondo. Por eso el diagrama no fija colores: pide una paleta.
///
/// [PaletaOdontodiagrama.impresion] es la única que nunca cambia, porque es la
/// que se rasteriza al PDF y tiene que salir igual por la impresora.
@immutable
class PaletaOdontodiagrama {
  /// Fondo del diagrama y de la tabla de tejidos blandos.
  final Color papel;

  /// Trazo del glifo, la línea media y las reglas rotuladas.
  final Color trazo;

  /// Filetes de la tabla y borde del panel.
  final Color regla;

  final Color textoFuerte;
  final Color textoSuave;

  /// Texto de un campo sin anotar.
  final Color textoVacio;

  final Color tintaRoja;
  final Color tintaAzul;
  final Color tintaNegra;

  /// Realce de la pieza bajo el cursor o el dedo.
  final Color resalte;

  /// La paleta se dibuja sobre fondo oscuro: los rellenos necesitan más alfa
  /// para separarse del papel y los trazos no pueden ser negros.
  final bool esOscura;

  const PaletaOdontodiagrama({
    required this.papel,
    required this.trazo,
    required this.regla,
    required this.textoFuerte,
    required this.textoSuave,
    required this.textoVacio,
    required this.tintaRoja,
    required this.tintaAzul,
    required this.tintaNegra,
    required this.resalte,
    required this.esOscura,
  });

  /// Papel blanco y tintas impresas. Es la vista de expediente y la que se
  /// captura para el PDF, así que es intencionadamente insensible al tema.
  static const impresion = PaletaOdontodiagrama(
    papel: Color(0xFFFDFDFC),
    trazo: Color(0xFF334155),
    regla: Color(0xFFB6BFCC),
    textoFuerte: Color(0xFF1F2937),
    textoSuave: Color(0xFF475569),
    textoVacio: Color(0xFF9AA4B2),
    tintaRoja: kTintaRoja,
    tintaAzul: kTintaAzul,
    tintaNegra: kTintaNegra,
    resalte: Color(0x1F3385FF),
    esOscura: false,
  );

  /// El mismo papel claro, pero con los textos de apoyo del tema: el diagrama
  /// vive dentro de una tarjeta y los rótulos deben leerse como el resto.
  static const claro = impresion;

  /// Papel oscuro. Las tintas suben de luminancia para conservar el contraste
  /// sin dejar de leerse como «la roja» y «la azul» del formulario.
  static const oscuro = PaletaOdontodiagrama(
    papel: Color(0xFF111A2B),
    trazo: Color(0xFF93A6C0),
    regla: Color(0xFF2C3A54),
    textoFuerte: Color(0xFFE2E8F0),
    textoSuave: Color(0xFFB0BECC),
    textoVacio: Color(0xFF64748B),
    tintaRoja: Color(0xFFFF7A7A),
    tintaAzul: Color(0xFF7FB2FF),
    tintaNegra: Color(0xFFCBD5E1),
    resalte: Color(0x335BA3FF),
    esOscura: true,
  );

  /// Resuelve la paleta del tema activo. [impresion] fuerza el papel blanco
  /// para las vistas que se archivan o se imprimen.
  factory PaletaOdontodiagrama.de(BuildContext context, {bool imprimir = false}) {
    if (imprimir) return PaletaOdontodiagrama.impresion;
    return Theme.of(context).brightness == Brightness.dark
        ? PaletaOdontodiagrama.oscuro
        : PaletaOdontodiagrama.claro;
  }

  /// Color con el que se anota una clave sobre este papel.
  Color tintaDe(EstadoClinicoDental estado) => switch (estado.tintaClinica) {
    TintaClinica.roja => tintaRoja,
    TintaClinica.azul => tintaAzul,
    TintaClinica.negra => tintaNegra,
  };

  /// Alfa del relleno de una superficie anotada en esta consulta.
  double get alfaRelleno => esOscura ? 0.62 : 0.72;

  /// Texto de un rótulo del diagrama, ya sea sobre papel o sobre la tarjeta.
  Color tituloSobreTarjeta(BuildContext context) =>
      esOscura ? context.appColors.textPrimary : textoFuerte;

  Color apoyoSobreTarjeta(BuildContext context) =>
      esOscura ? context.appColors.textMuted : textoSuave;

  @override
  bool operator ==(Object other) =>
      other is PaletaOdontodiagrama &&
      other.papel == papel &&
      other.trazo == trazo &&
      other.regla == regla &&
      other.textoFuerte == textoFuerte &&
      other.textoSuave == textoSuave &&
      other.textoVacio == textoVacio &&
      other.tintaRoja == tintaRoja &&
      other.tintaAzul == tintaAzul &&
      other.tintaNegra == tintaNegra &&
      other.resalte == resalte &&
      other.esOscura == esOscura;

  @override
  int get hashCode => Object.hash(
    papel,
    trazo,
    regla,
    textoFuerte,
    textoSuave,
    textoVacio,
    tintaRoja,
    tintaAzul,
    tintaNegra,
    resalte,
    esOscura,
  );
}
