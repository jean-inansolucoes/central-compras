import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta um Stream (ex.: mudanças de sessão do Supabase Auth) para o
/// `Listenable` que o `GoRouter.refreshListenable` espera, para que as
/// regras de `redirect` sejam reavaliadas a cada login/logout.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
