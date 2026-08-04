import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/presentation/pages/receta_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

Paciente _paciente() => Paciente(
  id: 'p-1',
  nombre: 'Ana',
  apellido: 'Rodríguez',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: const [],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: '',
  referencia: '',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: 'p-1',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

/// El vocabulario de HFX-CLIN-005: cada estado se llama igual en el
/// odontograma, en la ficha de la pieza, en la receta y en la línea de tiempo.
void main() {
  group('terminología de la ejecución', () {
    test('lo ejecutado no se llama "terminado" ni "aplicado"', () {
      expect(EstadoTratamientoAplicado.enProceso.etiqueta, 'En proceso');
      expect(EstadoTratamientoAplicado.aplicado.etiqueta, 'Ejecutado');
      expect(
        EstadoTratamientoAplicado.completado.etiqueta,
        'Ejecutado y cerrado',
      );
    });

    test(
      'una ejecución abierta no se anuncia como realizada en esta consulta',
      () {
        // El defecto auditado: la ficha decía «Realizado en esta consulta»
        // encima de un chip que decía «En proceso».
        final procedencia = ProcedenciaMarca.ejecutado;
        expect(procedencia.descripcion, isNot(contains('Realizado')));
        expect(
          procedencia.descripcion,
          'Registrado como ejecución en esta consulta',
        );
      },
    );

    test('procedencia y estado no comparten rótulo', () {
      // Dos cosas distintas del mismo panel no pueden leerse igual.
      expect(ProcedenciaMarca.ejecutado.etiqueta, isNot(etiquetaEjecutado));
    });

    test('la marca sabe si su ejecución está cerrada sin comparar textos', () {
      final cerrada = marcaDeTratamiento(
        36,
        TratamientoAplicado(
          id: 'ta-1',
          tratamientoId: 't-1',
          esContinuo: false,
          estaTerminado: true,
          superficie: TipoSuperficie.oclusal,
          estado: EstadoTratamientoAplicado.completado,
        ),
        ProcedenciaMarca.ejecutado,
        null,
      );
      final abierta = marcaDeTratamiento(
        36,
        TratamientoAplicado(
          id: 'ta-2',
          tratamientoId: 't-1',
          esContinuo: true,
          estaTerminado: false,
          superficie: TipoSuperficie.oclusal,
          estado: EstadoTratamientoAplicado.enProceso,
        ),
        ProcedenciaMarca.ejecutado,
        null,
      );

      expect(cerrada.ejecucionCerrada, isTrue);
      expect(cerrada.estado, 'Ejecutado');
      expect(abierta.ejecucionCerrada, isFalse);
      expect(abierta.estado, 'En proceso');
    });
  });

  group('título de la receta', () {
    Future<void> abrir(WidgetTester tester, Receta? receta) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecetaFormDialog(
              paciente: _paciente(),
              consultaId: 'c-1',
              doctorId: 'd-1',
              recetaParaEditar: receta,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Receta recetaCon(EstadoReceta estado) => Receta(
      id: 'r-1',
      codigoReceta: 'RX-1',
      consultaId: 'c-1',
      pacienteId: 'p-1',
      doctorId: 'd-1',
      fechaEmision: DateTime(2026, 7, 31),
      estado: estado,
      items: const [
        ItemReceta(
          nombreMedicamento: 'Ibuprofeno',
          dosis: '400 mg',
          frecuencia: 'cada 8 horas',
          duracion: '3 días',
          viaAdministracion: 'oral',
        ),
      ],
    );

    testWidgets('la primera emisión no se anuncia como reemisión', (
      tester,
    ) async {
      await abrir(tester, null);
      expect(find.text('Emitir receta médica'), findsOneWidget);
      expect(find.textContaining('Reemitir'), findsNothing);
    });

    testWidgets('un borrador tampoco: todavía no se emitió nada', (
      tester,
    ) async {
      await abrir(tester, recetaCon(EstadoReceta.borrador));
      expect(find.text('Emitir receta médica'), findsOneWidget);
    });

    testWidgets('corregir una receta emitida sí es reemitir', (tester) async {
      await abrir(tester, recetaCon(EstadoReceta.emitida));
      expect(find.text('Reemitir / corregir receta'), findsOneWidget);
    });
  });
}
