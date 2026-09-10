import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/cliente_model.dart';
import '../data/cliente_repository.dart';

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ClienteRepository(ref.watch(supabaseClientProvider));
});

final clienteSearchProvider = StateProvider<String>((ref) => '');

final clientesListProvider = FutureProvider.autoDispose<List<Cliente>>((ref) async {
  final search = ref.watch(clienteSearchProvider);
  return ref.watch(clienteRepositoryProvider).list(search: search);
});
