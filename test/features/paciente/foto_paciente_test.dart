import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/paciente_avatar.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/recorte_foto_dialog.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _pacienteId = '11111111-1111-1111-1111-111111111111';

void main() {
  // El servicio no toca la red en estas rutas: el cliente se construye con
  // datos ficticios porque solo se ejercita el procesamiento local.
  final storage = PacienteFotoStorage(
    SupabaseClient('http://localhost:54321', 'clave-de-prueba'),
  );

  group('procesamiento de la fotografía', () {
    test('rechaza bytes que no son una imagen', () {
      expect(
        () => storage.decodificar(Uint8List.fromList(List.filled(64, 0x41))),
        throwsA(isA<FormatoFotoInvalido>()),
      );
    });

    test('rechaza originales de más de 10 MB antes de decodificar', () {
      final enorme = Uint8List(PacienteFotoStorage.maxOriginalBytes + 1);
      // Cabecera PNG válida: el rechazo debe venir del tamaño, no del formato.
      enorme.setAll(0, [0x89, 0x50, 0x4e, 0x47]);
      expect(
        () => storage.decodificar(enorme),
        throwsA(isA<FormatoFotoInvalido>()),
      );
    });

    test('comprime a JPEG con el lado mayor acotado', () {
      final grande = img.Image(width: 2400, height: 1800);
      final bytes = storage.comprimir(grande);

      expect(bytes[0], 0xff);
      expect(bytes[1], 0xd8, reason: 'debe ser JPEG');
      final decodificada = img.decodeImage(bytes)!;
      expect(decodificada.width, PacienteFotoStorage.ladoMaximo);
      expect(
        bytes.lengthInBytes,
        lessThan(PacienteFotoStorage.maxCompressedBytes),
      );
    });

    test('preparar acepta un PNG real y lo deja en JPEG', () {
      final png = Uint8List.fromList(
        img.encodePng(img.Image(width: 300, height: 300)),
      );
      final bytes = storage.preparar(png);
      expect(bytes[0], 0xff);
      expect(bytes[1], 0xd8);
    });

    test('el recorte se sanea contra los bordes de la imagen', () {
      final fuente = img.Image(width: 400, height: 300);
      final recorte = storage.recortarCuadrado(
        fuente,
        x: -50,
        y: 280,
        lado: 900,
      );

      expect(recorte.width, 300);
      expect(recorte.height, 300);
    });
  });

  group('persistencia de las columnas foto_*', () {
    test('toJson no las incluye: solo PacienteFotoStorage las escribe', () {
      final model = PacienteModel.fromEntity(
        _paciente(fotoRuta: '$_pacienteId/perfil.jpg'),
      );

      expect(
        model.toJson().keys.where((k) => k.startsWith('foto_')),
        isEmpty,
        reason: 'incluirlas borraba la foto al editar cualquier otro dato',
      );
    });

    test('fromJson sí las lee para poder mostrar el avatar', () {
      final model = PacienteModel.fromJson({
        'id': _pacienteId,
        'genero': 'femenino',
        'tipo_paciente': 'integrado',
        'foto_ruta': '$_pacienteId/perfil.jpg',
        'foto_mime_type': 'image/jpeg',
        'foto_tamano_bytes': 1234,
        'foto_actualizada_en': '2026-07-27T12:00:00.000Z',
        'personas': {
          'nombre': 'Ana',
          'apellido': 'Rodríguez',
          'fecha_nacimiento': '1990-05-12',
          'cedula': '001-1234567-8',
          'estatus': 'activo',
        },
      });

      expect(model.fotoRuta, '$_pacienteId/perfil.jpg');
      expect(model.fotoTamanoBytes, 1234);
      expect(model.fotoActualizadaEn, isNotNull);
    });
  });

  group('RecorteFotoDialog', () {
    testWidgets('devuelve un JPEG cuadrado listo para subir', (tester) async {
      Uint8List? resultado;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  resultado = await RecorteFotoDialog.mostrar(
                    context,
                    imagen: img.Image(width: 1600, height: 900),
                    storage: storage,
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar esta foto'));
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      final recortada = img.decodeImage(resultado!)!;
      expect(recortada.width, recortada.height, reason: 'debe ser cuadrada');
      expect(resultado![0], 0xff);
      expect(resultado![1], 0xd8);
    });
  });

  group('PacienteAvatar', () {
    testWidgets('sin foto muestra las iniciales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: PacienteAvatar(paciente: _paciente())),
        ),
      );

      expect(find.text('AR'), findsOneWidget);
    });

    testWidgets('con eliminación pendiente no pide la URL firmada', (
      tester,
    ) async {
      // Si intentara firmar la URL fallaría al resolver el service locator,
      // que en esta prueba no está registrado.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PacienteAvatar(
              paciente: _paciente(fotoRuta: '$_pacienteId/perfil.jpg'),
              forzarIniciales: true,
            ),
          ),
        ),
      );

      expect(find.text('AR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Paciente _paciente({String? fotoRuta}) => Paciente(
  id: _pacienteId,
  nombre: 'Ana',
  apellido: 'Rodríguez',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'ana@correo.com.do',
      direccion: 'Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: 'Docente',
  referencia: '',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  fotoRuta: fotoRuta,
  fotoMimeType: fotoRuta == null ? null : 'image/jpeg',
  fotoTamanoBytes: fotoRuta == null ? null : 2048,
  fotoActualizadaEn: fotoRuta == null ? null : DateTime(2026, 7, 27),
  record: Record(
    pacienteId: _pacienteId,
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);
