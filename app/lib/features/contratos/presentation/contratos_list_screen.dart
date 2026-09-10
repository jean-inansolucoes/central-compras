import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/contrato_model.dart';
import '../providers/contrato_providers.dart';
import 'contrato_form_screen.dart';

class ContratosListScreen extends ConsumerWidget {
  const ContratosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratosAsync = ref.watch(contratosListProvider);
    final clienteNomesAsync = ref.watch(clienteNomesProvider);
    final produtoNomesAsync = ref.watch(produtoNomesProvider);
    // Inclusão de novo contrato é restrita a admin (RLS não libera INSERT
    // para o papel externo).
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contratos')),
      drawer: const AppDrawer(currentRoute: '/contratos'),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: contratosAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: 'Erro ao carregar contratos: $error',
          onRetry: () => ref.invalidate(contratosListProvider),
        ),
        data: (contratos) {
          if (contratos.isEmpty) {
            return const Center(child: Text('Nenhum contrato encontrado.'));
          }
          final clienteNomes = clienteNomesAsync.valueOrNull ?? const {};
          final produtoNomes = produtoNomesAsync.valueOrNull ?? const {};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(contratosListProvider);
              ref.invalidate(clienteNomesProvider);
              ref.invalidate(produtoNomesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: contratos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final contrato = contratos[index];
                final clienteNome = clienteNomes[contrato.customerId] ?? 'Cliente #${contrato.customerId}';
                final produtoNome = produtoNomes[contrato.productId] ?? 'Produto #${contrato.productId}';
                final vencido = contrato.endDate.isBefore(DateTime.now());

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: contrato.trial
                        ? AppColors.alerta
                        : (vencido ? AppColors.perigo : AppColors.sucesso),
                    child: const Icon(Icons.description_outlined, color: Colors.white),
                  ),
                  title: Text(clienteNome),
                  subtitle: Text(
                    '$produtoNome · ${contrato.trial ? "Trial" : "Ativo"} · '
                    'até ${_formatDate(contrato.endDate)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openForm(context, contrato: contrato),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _openForm(BuildContext context, {Contrato? contrato}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContratoFormScreen(contrato: contrato)),
    );
  }
}
