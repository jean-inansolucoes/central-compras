import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Menu lateral reaproveitado pelas telas de Clientes/Contratos/Produtos —
/// cada uma delas mantém sua própria Scaffold/AppBar, então o Drawer
/// precisa ser incluído em cada uma (não dá para "compartilhar" um único
/// Drawer entre Scaffolds aninhadas: o AppBar só abre o Drawer da Scaffold
/// mais próxima).
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  static const _items = [
    (route: '/clientes', title: 'Clientes', icon: Icons.apartment),
    (route: '/contratos', title: 'Contratos', icon: Icons.description_outlined),
    (route: '/produtos', title: 'Produtos', icon: Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appUserProfileProvider).valueOrNull;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: AppColors.gradientePrincipal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    profile != null && profile.name.isNotEmpty ? profile.name : 'SmartSupply',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    profile?.isAdmin == true ? 'Administrador' : 'Usuário externo',
                    style: const TextStyle(color: AppColors.roxoClaro, fontSize: 12),
                  ),
                ],
              ),
            ),
            for (final item in _items)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                selected: currentRoute == item.route,
                selectedColor: AppColors.roxo,
                onTap: () {
                  Navigator.of(context).pop();
                  if (currentRoute != item.route) {
                    context.go(item.route);
                  }
                },
              ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.perigo),
              title: const Text('Sair', style: TextStyle(color: AppColors.perigo)),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
