import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_user_profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Cria a conta no Supabase Auth. O perfil correspondente em APP_USER é
  /// criado automaticamente por um trigger no banco (ver migration
  /// 004_handle_new_user_trigger.sql) — não fazemos esse insert aqui porque,
  /// se a confirmação de e-mail estiver ativa no projeto, `signUp` não
  /// retorna uma sessão ativa na hora, e um insert feito pelo cliente
  /// esbarraria na política de RLS de APP_USER (que exige auth.uid()).
  ///
  /// Novos cadastros entram sempre com papel "external" — a elevação para
  /// "admin" é feita manualmente pela equipe INAN (via painel do Supabase ou
  /// por um admin já existente), nunca pelo próprio fluxo de auto-cadastro.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    if (response.user == null) {
      throw const AuthException('Não foi possível criar o usuário.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUserProfile?> fetchProfile(String userId) async {
    final data = await _client
        .from('APP_USER')
        .select()
        .eq('ID', userId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return AppUserProfile.fromMap(data);
  }
}
