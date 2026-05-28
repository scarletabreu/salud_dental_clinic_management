// ─────────────────────────────────────────────────────────────────────────────
// SD-19 · Registro de Pacientes – Campo de Cédula
// Fragmento listo para insertar en el widget del formulario existente.
// ─────────────────────────────────────────────────────────────────────────────
//
// IMPORTS NECESARIOS (agregar al inicio del archivo del formulario):
//
//   import 'package:<tu_app>/core/utils/validators.dart';
//   import 'package:flutter/services.dart'; // FilteringTextInputFormatter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salud_dental_clinic_management/core/util/validators.dart';

/// Ejemplo mínimo de uso del validador en el formulario SD-19.
/// Integra este campo dentro del [Form] existente de registro de pacientes.
class CedulaFormField extends StatelessWidget {
  const CedulaFormField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Cédula de Identidad',
        hintText: '000-0000000-0',
        prefixIcon: Icon(Icons.badge_outlined),
        // El error aparece automáticamente al llamar a Form.validate().
      ),

      // Solo permite dígitos y guiones para evitar entrada de letras.
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
        LengthLimitingTextInputFormatter(13), // 11 dígitos + 2 guiones
      ],

      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.telephoneNumber],

      // ← Aquí se conecta el validador de la utilidad.
      validator: cedulaValidator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFERENCIA: cómo disparar la validación al guardar el formulario
// ─────────────────────────────────────────────────────────────────────────────
//
//   final _formKey = GlobalKey<FormState>();
//
//   ElevatedButton(
//     onPressed: () {
//       if (_formKey.currentState!.validate()) {
//         // Todos los campos son válidos → continuar con el registro.
//         _guardarPaciente();
//       }
//     },
//     child: const Text('Guardar Paciente'),
//   )