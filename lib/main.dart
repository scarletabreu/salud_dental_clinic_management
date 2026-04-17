import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/medicina/data/repositories/medicina_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicine_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xcuvywvltttephakzmwu.supabase.co',
    anonKey: 'sb_publishable_3VHcOI-RR6w4_E8GFSkj6A_w2qa5PBG',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final remoteDataSource = MedicineRemoteDatasource(supabaseClient);
    final repository = MedicinaRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return MaterialApp(
      title: 'Salud Dental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      home: MedicinaListPage(repository: repository),
    );
  }
}
