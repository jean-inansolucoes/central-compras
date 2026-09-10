import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_user_profile.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Emite a cada mudança de sessão (login, logout, refresh de token).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Perfil (papel, nome) do usuário autenticado — nulo enquanto deslogado.
final appUserProfileProvider = FutureProvider<AppUserProfile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  final userId = authState?.session?.user.id ??
      ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) {
    return null;
  }
  return ref.watch(authRepositoryProvider).fetchProfile(userId);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(appUserProfileProvider).valueOrNull?.isAdmin ?? false;
});
