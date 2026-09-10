import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../clientes/providers/cliente_providers.dart';
import '../../produtos/providers/produto_providers.dart';
import '../data/contrato_model.dart';
import '../data/contrato_repository.dart';

final contratoRepositoryProvider = Provider<ContratoRepository>((ref) {
  return ContratoRepository(ref.watch(supabaseClientProvider));
});

final contratosListProvider = FutureProvider.autoDispose<List<Contrato>>((ref) async {
  return ref.watch(contratoRepositoryProvider).list();
});

/// Mapas id -> nome usados para exibir/selecionar Cliente e Produto nas
/// telas de Contrato, sem depender de FK/embed do PostgREST.
final clienteNomesProvider = FutureProvider.autoDispose<Map<int, String>>((ref) async {
  return ref.watch(clienteRepositoryProvider).idNameMap();
});

final produtoNomesProvider = FutureProvider.autoDispose<Map<int, String>>((ref) async {
  return ref.watch(produtoRepositoryProvider).idNameMap();
});
