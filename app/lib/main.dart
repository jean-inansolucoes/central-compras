import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';

/// Tempo mínimo em que a splash nativa fica visível, mesmo que a
/// inicialização do Supabase seja instantânea — dá a impressão de app
/// carregando algo, em vez de piscar a splash por uma fração de segundo.
const _minSplashDuration = Duration(seconds: 3);

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final startedAt = DateTime.now();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: App()));

  final remaining = _minSplashDuration - DateTime.now().difference(startedAt);
  if (remaining > Duration.zero) {
    await Future.delayed(remaining);
  }
  FlutterNativeSplash.remove();
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SmartSupply Back-office',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
