import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/produto_model.dart';
import '../providers/produto_providers.dart';
import 'produto_form_screen.dart';

class ProdutosListScreen extends ConsumerWidget {
  const ProdutosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produtosAsync = ref.watch(produtosListProvider);
    // Catálogo de produtos é somente leitura para usuário externo (RLS).
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const AppDrawer(currentRoute: '/produtos'),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: produtosAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: 'Erro ao carregar produtos: $error',
          onRetry: () => ref.invalidate(produtosListProvider),
        ),
        data: (produtos) {
          if (produtos.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(produtosListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: produtos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final produto = produtos[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.pink,
                    child: Icon(Icons.inventory_2_outlined, color: Colors.white),
                  ),
                  title: Text(produto.name),
                  subtitle: Text('R\$ ${produto.price.toStringAsFixed(2)}/mês'),
                  trailing: isAdmin ? const Icon(Icons.chevron_right) : null,
                  onTap: isAdmin ? () => _openForm(context, produto: produto) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Produto? produto}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProdutoFormScreen(produto: produto)),
    );
  }
}
