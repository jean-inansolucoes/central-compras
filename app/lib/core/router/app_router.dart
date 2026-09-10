import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/clientes/presentation/clientes_list_screen.dart';
import '../../features/contratos/presentation/contratos_list_screen.dart';
import '../../features/produtos/presentation/produtos_list_screen.dart';
import 'go_router_refresh_stream.dart';

const _publicRoutes = {'/login', '/cadastro', '/esqueci-senha'};

final routerProvider = Provider<GoRouter>((ref) => buildAppRouter());

GoRouter buildAppRouter() {
  final auth = Supabase.instance.client.auth;

  return GoRouter(
    initialLocation: '/clientes',
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final isLoggedIn = auth.currentSession != null;
      final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }
      if (isLoggedIn && isPublicRoute) {
        return '/clientes';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/esqueci-senha',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/clientes', builder: (context, state) => const ClientesListScreen()),
      GoRoute(path: '/contratos', builder: (context, state) => const ContratosListScreen()),
      GoRoute(path: '/produtos', builder: (context, state) => const ProdutosListScreen()),
    ],
  );
}
