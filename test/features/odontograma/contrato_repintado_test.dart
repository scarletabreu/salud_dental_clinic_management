import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

const _glifo = GlifoPieza(
  fdi: 16,
  temporal: false,
  superior: true,
  mesialALaDerecha: true,
);

GlifoPiezaPainter _painter({
  GlifoPieza glifo = _glifo,
  List<HallazgoDental> hallazgos = const [],
  PaletaOdontodiagrama paleta = PaletaOdontodiagrama.impresion,
}) => GlifoPiezaPainter(
  glifo: glifo,
  hallazgos: hallazgos,
  paleta: paleta,
);

void main() {
  group('GlifoPiezaPainter · contrato de repintado (SD-132)', () {
    // `shouldRepaint` es lo que decide cuántas veces por segundo se redibuja
    // la boca. Si compara por identidad en lugar de por valor, cada frame
    // repinta las 52 piezas aunque no haya cambiado nada.

    test('no repinta cuando nada ha cambiado', () {
      expect(_painter().shouldRepaint(_painter()), isFalse);
    });

    test('no repinta ante listas de hallazgos iguales pero distintas', () {
      final unos = [
        HallazgoDental(
          estado: EstadoClinicoDental.values.first,
          superficies: const {TipoSuperficie.oclusal},
        ),
      ];
      final otros = [
        HallazgoDental(
          estado: EstadoClinicoDental.values.first,
          superficies: const {TipoSuperficie.oclusal},
        ),
      ];

      expect(
        _painter(hallazgos: unos).shouldRepaint(_painter(hallazgos: otros)),
        isFalse,
        reason:
            'reconstruir la lista en cada build no debe forzar un repintado',
      );
    });

    test('repinta cuando aparece un hallazgo', () {
      final con = [
        HallazgoDental(
          estado: EstadoClinicoDental.values.first,
          superficies: const {TipoSuperficie.oclusal},
        ),
      ];

      expect(
        _painter(hallazgos: con).shouldRepaint(_painter()),
        isTrue,
        reason: 'un hallazgo nuevo tiene que verse',
      );
    });

    test('repinta cuando cambia el resalte de la pieza', () {
      final resaltada = GlifoPiezaPainter(
        glifo: _glifo,
        hallazgos: const [],
        paleta: PaletaOdontodiagrama.impresion,
        resalte: PaletaOdontodiagrama.impresion.resalte,
      );

      expect(resaltada.shouldRepaint(_painter()), isTrue);
    });

    test('repinta al cambiar de tema', () {
      expect(
        _painter(paleta: PaletaOdontodiagrama.oscuro)
            .shouldRepaint(_painter(paleta: PaletaOdontodiagrama.impresion)),
        isTrue,
      );
    });

    test('repinta cuando la pieza dibujada es otra', () {
      const otraPieza = GlifoPieza(
        fdi: 26,
        temporal: false,
        superior: true,
        mesialALaDerecha: false,
      );

      expect(_painter(glifo: otraPieza).shouldRepaint(_painter()), isTrue);
    });

    test('no repinta ante mapas de superficies iguales pero distintos', () {
      final a = GlifoPiezaPainter(
        glifo: _glifo,
        hallazgos: const [],
        paleta: PaletaOdontodiagrama.impresion,
        superficies: const {},
      );
      final b = GlifoPiezaPainter(
        glifo: _glifo,
        hallazgos: const [],
        paleta: PaletaOdontodiagrama.impresion,
        superficies: {},
      );

      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
