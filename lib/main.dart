import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/medicina/data/repositories/medicina_memory_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salud Dental',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: MedicinaListPage(repository: MedicinaMemoryRepository()),
    );
  }
}
