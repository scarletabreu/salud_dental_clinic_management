import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final SupabaseClient supabase;

  UsuarioRemoteDataSourceImpl(this.supabase);

  @override
  User? getCurrentSupabaseUser() => supabase.auth.currentUser;

  @override
  String? getCurrentUserId() => supabase.auth.currentUser?.id;

  @override
  Future<void> signOut() async => await supabase.auth.signOut();

  @override
  bool isSessionActive() => supabase.auth.currentSession != null;

  @override
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
