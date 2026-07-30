import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/entidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/tipo_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/services/alerta_operativa_generator.dart';

void main() {
  Equipo equipo({required DateTime ultimoMantenimiento, int periodo = 30}) =>
      Equipo(
        id: '11111111-1111-1111-1111-111111111111',
        nombre: 'Autoclave',
        descripcion: 'Esterilización',
        ultimoMantenimiento: ultimoMantenimiento,
        tiempoParaMantenimiento: periodo,
      );

  group('vencimiento de mantenimiento', () {
    test('vence de forma inclusiva al completar el periodo', () {
      final item = equipo(ultimoMantenimiento: DateTime(2026, 6, 26, 18, 30));

      expect(item.mantenimientoVencidoEn(DateTime(2026, 7, 26, 8)), isTrue);
      expect(item.diasParaMantenimiento(DateTime(2026, 7, 26, 8)), 0);
    });

    test('no depende de la hora y no vence un día antes', () {
      final item = equipo(ultimoMantenimiento: DateTime(2026, 6, 26, 1));

      expect(
        item.mantenimientoVencidoEn(DateTime(2026, 7, 25, 23, 59)),
        isFalse,
      );
      expect(item.diasParaMantenimiento(DateTime(2026, 7, 25, 23, 59)), 1);
    });
  });

  test('Inicio genera una alerta operativa por cada equipo vencido', () {
    final alertas = const AlertaOperativaGenerator().generar(
      citasDeHoy: const [],
      equipos: [
        equipo(ultimoMantenimiento: DateTime(2026, 6, 1)),
        equipo(ultimoMantenimiento: DateTime(2026, 7, 20)),
      ],
      ahora: DateTime(2026, 7, 26),
    );

    expect(alertas, hasLength(1));
    expect(alertas.single.tipo, TipoAlerta.mantenimientoVencido);
    expect(alertas.single.entidadTipo, EntidadAlerta.equipo);
    expect(alertas.single.rolesAutorizados, contains(RolUsuario.asistente));
    expect(alertas.single.titulo, contains('mantenimiento vencido'));
  });
}
