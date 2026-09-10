import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/cliente_model.dart';
import '../providers/cliente_providers.dart';
import 'cliente_form_screen.dart';

class ClientesListScreen extends ConsumerWidget {
  const ClientesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesListProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      drawer: const AppDrawer(currentRoute: '/clientes'),
      // Inclusão de novo cliente é restrita a admin — usuário externo só
      // enxerga/edita a(s) empresa(s) já vinculada(s) a ele (RLS).
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nome',
              ),
              onChanged: (value) => ref.read(clienteSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: clientesAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: 'Erro ao carregar clientes: $error',
                onRetry: () => ref.invalidate(clientesListProvider),
              ),
              data: (clientes) {
                if (clientes.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(clientesListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: clientes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.roxoClaro,
                          child: Icon(Icons.apartment, color: Colors.white),
                        ),
                        title: Text(cliente.name),
                        subtitle: Text('${cliente.fantasy} · ${cliente.cgcCpf}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openForm(context, cliente: cliente),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Cliente? cliente}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
    );
  }
}
