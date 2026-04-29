import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/service_locator.dart' as di;
import 'package:salud_dental_clinic_management/shell/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xcuvywvltttephakzmwu.supabase.co',
    anonKey: 'sb_publishable_3VHcOI-RR6w4_E8GFSkj6A_w2qa5PBG',
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salud Dental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      home: const DashboardShell(),
    );
  }
}
