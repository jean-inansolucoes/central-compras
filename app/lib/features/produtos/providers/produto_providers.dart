import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/produto_model.dart';
import '../data/produto_repository.dart';

final produtoRepositoryProvider = Provider<ProdutoRepository>((ref) {
  return ProdutoRepository(ref.watch(supabaseClientProvider));
});

final produtosListProvider = FutureProvider.autoDispose<List<Produto>>((ref) async {
  return ref.watch(produtoRepositoryProvider).list();
});
