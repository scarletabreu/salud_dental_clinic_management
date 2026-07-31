import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/consentimiento_plan.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

/// HFX-CLIN-003 · las barreras del lado del cliente.
///
/// La base es la autoridad y tiene su propia suite
/// (`supabase/tests/hfx_clin_003_barreras_clinicas_test.sql`). Lo que se prueba
/// aquí es que la pantalla aplique exactamente la misma regla antes de enviar:
/// si el cliente fuera más permisivo el doctor descubriría el problema como un
/// error de base de datos, y si fuera más estricto bloquearía algo que el
/// servidor sí acepta.
void main() {
  group('Signos vitales · lo imposible no llega al servidor', () {
    test('un valor fuera del rango físico se rechaza y nombra su rango', () {
      final sv = SignosVitales.valores(temperatura: 62);

      final problemas = sv.validar();

      expect(sv.esValida, isFalse);
      expect(problemas, hasLength(1));
      expect(problemas.single.tipo, TipoSignoVital.temperatura);
      expect(problemas.single.mensaje, contains('25.0–45.0 °C'));
    });

    test('la diastólica no puede igualar ni superar la sistólica', () {
      final iguales = SignosVitales.valores(
        presionSistolica: 110,
        presionDiastolica: 110,
      );
      final mayor = SignosVitales.valores(
        presionSistolica: 110,
        presionDiastolica: 115,
      );

      expect(iguales.esValida, isFalse);
      expect(mayor.esValida, isFalse);
      expect(mayor.validar().single.tipo, TipoSignoVital.presionDiastolica);
    });

    test('unos signos altos pero posibles pasan: el umbral no es del cliente', () {
      // Es el caso auditado —PA 165/105, pulso 108, 38.6 °C, SpO₂ 92, dolor 9—.
      // No es un dato inválido: es una alerta, y esa la emite el motor con una
      // regla aprobada. El formulario no debe inventarse el bloqueo.
      final sv = SignosVitales.valores(
        presionSistolica: 165,
        presionDiastolica: 105,
        pulso: 108,
        temperatura: 38.6,
        saturacionO2: 92,
        dolor: 9,
      );

      expect(sv.esValida, isTrue);
    });

    test('el peso viaja al servidor: sin él no hay dosificación pediátrica', () {
      final sv = SignosVitales.valores(peso: 26.5, talla: 128);

      final payload = sv.toPayloadMediciones();
      final peso = payload.firstWhere((m) => m['codigo'] == 'peso');

      expect(payload, hasLength(2));
      expect(peso['valor'], 26.5);
      expect(peso['unidad'], 'kg');
      expect(peso['origen'], 'medido');
      expect(sv.valor(TipoSignoVital.talla), 128);
    });

    test('cada medición conserva unidad, origen y momento', () {
      final momento = DateTime.utc(2026, 7, 31, 14, 30);
      final sv = SignosVitales.valores(
        pulso: 108,
        origen: OrigenSignoVital.dispositivo,
        medidoEn: momento,
        medidoPor: 'doc-1',
      );

      final payload = sv.toPayloadMediciones().single;

      expect(payload['codigo'], 'pulso');
      expect(payload['unidad'], 'lpm');
      expect(payload['origen'], 'dispositivo');
      expect(payload['medido_por'], 'doc-1');
      expect(payload['medido_en'], momento.toIso8601String());
    });

    test('lee tanto el resumen plano histórico como las mediciones completas', () {
      final plano = SignosVitales.fromJson({'pulso': 80, 'temperatura': 36.7});
      final completo = SignosVitales.fromJson({
        'mediciones': [
          {'codigo': 'pulso', 'valor': 80, 'unidad': 'lpm', 'origen': 'referido'},
        ],
      });

      expect(plano.pulso, 80);
      expect(plano.temperatura, 36.7);
      expect(completo.medicion(TipoSignoVital.pulso)!.origen,
          OrigenSignoVital.referido);
    });
  });

  group('Receta · el renglón estructurado y sus incoherencias', () {
    ItemReceta renglon({
      String nombre = 'Paracetamol',
      String? medicamentoId = 'med-1',
      String? principioActivo = 'paracetamol',
      double dosis = 1,
      double frecuencia = 8,
      int dias = 5,
      double? cantidad,
    }) => ItemReceta.estructurado(
      medicamentoId: medicamentoId,
      nombreMedicamento: nombre,
      principioActivo: principioActivo,
      dosisCantidad: dosis,
      dosisUnidad: 'tableta',
      viaAdministracion: 'oral',
      frecuenciaHoras: frecuencia,
      duracionDias: dias,
      cantidadTotal: cantidad ?? 15,
    );

    test('la cantidad que no alcanza para la pauta se detiene', () {
      // 1 tableta cada 8 h por 5 días son 15; despachar 6 no cubre nada.
      final item = renglon(cantidad: 6);

      expect(item.cantidadEsperada, 15);
      expect(item.cantidadEsCoherente, isFalse);
      expect(item.validar().single, contains('no cuadra'));
    });

    test('duplicar la pauta también es incoherente', () {
      expect(renglon(cantidad: 45).cantidadEsCoherente, isFalse);
      expect(renglon(cantidad: 15).cantidadEsCoherente, isTrue);
      expect(renglon(cantidad: 30).cantidadEsCoherente, isTrue);
    });

    test('un renglón incompleto dice exactamente qué le falta', () {
      const item = ItemReceta(
        nombreMedicamento: 'Amoxicilina',
        dosis: '',
        frecuencia: '',
        duracion: '',
        viaAdministracion: '',
      );

      final problemas = item.validar();

      expect(item.estaEstructurado, isFalse);
      expect(problemas, contains('Falta la dosis de Amoxicilina.'));
      expect(problemas, contains('Falta la unidad de la dosis de Amoxicilina.'));
      expect(
        problemas,
        contains('Falta la vía de administración de Amoxicilina.'),
      );
    });

    test('la frecuencia y la duración tienen límites propios', () {
      expect(
        renglon(frecuencia: 200).validar(),
        contains('La frecuencia de Paracetamol debe estar entre 1 y 168 horas.'),
      );
      expect(
        renglon(dias: 400).validar(),
        contains('La duración de Paracetamol debe estar entre 1 y 365 días.'),
      );
    });

    test('dos marcas del mismo principio activo son un duplicado', () {
      final items = [
        renglon(
          nombre: 'Naproxeno',
          medicamentoId: 'med-A',
          principioActivo: 'naproxeno',
        ),
        renglon(
          nombre: 'Naprox-Plus',
          medicamentoId: 'med-B',
          principioActivo: 'Naproxeno ',
        ),
      ];

      final repetidos = ItemReceta.duplicados(items);

      expect(repetidos, hasLength(1));
      expect(repetidos.single.nombreMedicamento, 'Naprox-Plus');
    });

    test('sin principio activo la duplicidad cae al medicamento, no al nombre', () {
      final items = [
        renglon(nombre: 'Marca X', medicamentoId: 'med-A', principioActivo: null),
        renglon(nombre: 'Marca Y', medicamentoId: 'med-A', principioActivo: null),
      ];

      expect(ItemReceta.duplicados(items), hasLength(1));
    });

    test('"no lo sabemos" no es "no hay riesgo"', () {
      expect(renglon(principioActivo: null).informacionInsuficiente, isTrue);
      expect(renglon(principioActivo: '  ').informacionInsuficiente, isTrue);
      expect(renglon(principioActivo: 'paracetamol').informacionInsuficiente,
          isFalse);
    });

    test('la cantidad sugerida es la de la pauta, y no se sugiere sin datos', () {
      expect(
        ItemReceta.sugerirCantidad(
          dosisCantidad: 1,
          frecuenciaHoras: 8,
          duracionDias: 7,
        ),
        21,
      );
      expect(
        ItemReceta.sugerirCantidad(dosisCantidad: 1, frecuenciaHoras: 8),
        isNull,
      );
      expect(
        ItemReceta.sugerirCantidad(
          dosisCantidad: 1,
          frecuenciaHoras: 0,
          duracionDias: 7,
        ),
        isNull,
      );
    });

    test('el texto impreso se redacta desde los valores, no aparte', () {
      final item = renglon(dosis: 2, frecuencia: 12, dias: 1, cantidad: 4);

      expect(item.dosis, '2 tableta');
      expect(item.frecuencia, 'cada 12 horas');
      expect(item.duracion, '1 día');
      expect(item.cantidadIndicada, '4 tableta');
    });
  });

  group('Alertas clínicas · qué detiene el cierre', () {
    AlertaClinica alerta(AccionAlerta accion, {EstadoAlerta? estado}) =>
        AlertaClinica(
          id: 'a1',
          reglaCodigo: 'SV_PULSO_CRITICO',
          severidad: SeveridadAlerta.critica,
          accion: accion,
          mensaje: 'Pulso = 108 lpm fuera del rango clínico aprobado.',
          estado: estado ?? EstadoAlerta.pendiente,
        );

    test('una advertencia informa pero no bloquea', () {
      expect(alerta(AccionAlerta.advertir).bloqueaCierre, isFalse);
    });

    test('confirmar, documentar, bloquear y referir sí bloquean', () {
      for (final accion in [
        AccionAlerta.confirmar,
        AccionAlerta.documentar,
        AccionAlerta.bloquearElectivo,
        AccionAlerta.referir,
      ]) {
        expect(alerta(accion).bloqueaCierre, isTrue, reason: accion.dbValue);
      }
    });

    test('resuelta deja de bloquear, sea confirmada o documentada', () {
      expect(
        alerta(AccionAlerta.documentar, estado: EstadoAlerta.documentada)
            .bloqueaCierre,
        isFalse,
      );
      expect(
        alerta(AccionAlerta.confirmar, estado: EstadoAlerta.confirmada)
            .bloqueaCierre,
        isFalse,
      );
    });

    test('solo documentar, bloquear y referir exigen justificación escrita', () {
      expect(AccionAlerta.advertir.exigeJustificacion, isFalse);
      expect(AccionAlerta.confirmar.exigeJustificacion, isFalse);
      expect(AccionAlerta.documentar.exigeJustificacion, isTrue);
      expect(AccionAlerta.bloquearElectivo.exigeJustificacion, isTrue);
      expect(AccionAlerta.referir.exigeJustificacion, isTrue);
    });

    test('la alerta del servidor conserva el dato que la disparó', () {
      final alertas = AlertaClinica.listaFromJson([
        {
          'id': 'al-1',
          'regla': 'PED_PESO_REQUERIDO',
          'severidad': 'critica',
          'accion': 'documentar',
          'mensaje': 'Falta registrar peso en esta consulta.',
          'estado': 'pendiente',
          'disparador': {'codigo': 'peso', 'faltante': true, 'edad_anios': 8},
        },
      ]);

      final alerta = alertas.single;
      expect(alerta.reglaCodigo, 'PED_PESO_REQUERIDO');
      expect(alerta.severidad, SeveridadAlerta.critica);
      expect(alerta.disparador['codigo'], 'peso');
      expect(alerta.disparador['edad_anios'], 8);
      expect(alerta.bloqueaCierre, isTrue);
    });

    test('un payload desconocido no se convierte en silencio peligroso', () {
      // Ante una acción o severidad que el cliente no conoce, degrada a
      // advertencia visible en vez de descartar la alerta.
      final alerta = AlertaClinica.fromJson({
        'id': 'al-2',
        'regla': 'FUTURA',
        'severidad': 'inventada',
        'accion': 'inventada',
        'mensaje': 'Regla nueva',
      });

      expect(alerta.severidad, SeveridadAlerta.advertencia);
      expect(alerta.accion, AccionAlerta.advertir);
      expect(AlertaClinica.listaFromJson(null), isEmpty);
    });
  });

  group('Condición detectada hoy · estructurada, no texto suelto', () {
    test('el payload lleva catálogo, severidad y si va al expediente', () {
      final detectada = CondicionDetectada(
        condicionId: 'cond-1',
        severidad: SeveridadCondicion.severa,
        notas: '  Refiere edema tras amoxicilina  ',
        detectadaEn: DateTime.utc(2026, 7, 31, 10),
        incorporarAlExpediente: true,
      );

      final payload = detectada.toPayload();

      expect(payload['condicion_id'], 'cond-1');
      expect(payload['severidad'], 'severa');
      expect(payload['notas'], 'Refiere edema tras amoxicilina');
      expect(payload['incorporar_al_expediente'], isTrue);
      expect(payload['detectada_en'], '2026-07-31T10:00:00.000Z');
    });

    test('sin confirmar no se incorpora al expediente', () {
      final detectada = CondicionDetectada(condicionId: 'cond-2');

      expect(detectada.incorporarAlExpediente, isFalse);
      expect(detectada.severidad, SeveridadCondicion.moderada);
      expect(
        detectada.copyWith(incorporarAlExpediente: true).incorporarAlExpediente,
        isTrue,
      );
    });

    test('las notas vacías no viajan como cadena en blanco', () {
      final payload = CondicionDetectada(
        condicionId: 'cond-3',
        notas: '   ',
      ).toPayload();

      expect(payload.containsKey('notas'), isFalse);
    });
  });

  group('Consentimiento · la decisión del paciente queda con su versión', () {
    test('la respuesta del servidor conserva versión, precio y quién aceptó', () {
      final consentimiento = ConsentimientoPlan.fromRpc({
        'consentimiento_id': 'cons-1',
        'plan_id': 'plan-1',
        'version_plan': 3,
        'decision': 'aceptado',
        'total_aceptado': 2500,
        'persona_acepta': 'Paula Gestante',
        'relacion_con_paciente': 'titular',
        'metodo': 'firma_fisica',
        'fecha': '2026-07-31T10:00:00.000Z',
      });

      expect(consentimiento.aceptado, isTrue);
      expect(consentimiento.versionPlan, 3);
      expect(consentimiento.totalAceptado, 2500);
      expect(consentimiento.personaAcepta, 'Paula Gestante');
      expect(consentimiento.metodo, MetodoConsentimiento.firmaFisica);
      expect(consentimiento.fecha, DateTime.utc(2026, 7, 31, 10));
    });

    test('un rechazo no se lee como aceptación', () {
      final consentimiento = ConsentimientoPlan.fromRpc({
        'plan_id': 'plan-1',
        'version_plan': 1,
        'decision': 'rechazado',
        'persona_acepta': 'Hilario Tenso',
        'motivo_rechazo': 'Prefiere consultar el costo',
      });

      expect(consentimiento.aceptado, isFalse);
      expect(consentimiento.motivoRechazo, 'Prefiere consultar el costo');
      expect(consentimiento.totalAceptado, 0);
    });

    test('un tercero que acepta queda identificado como tal', () {
      final consentimiento = ConsentimientoPlan.fromRpc({
        'plan_id': 'plan-1',
        'version_plan': 1,
        'decision': 'aceptado',
        'persona_acepta': 'Ana Pequeño',
        'relacion_con_paciente': 'madre',
        'metodo': 'verbal_presencial',
      });

      expect(consentimiento.relacionConPaciente, 'madre');
      expect(consentimiento.metodo, MetodoConsentimiento.verbalPresencial);
    });
  });
}
