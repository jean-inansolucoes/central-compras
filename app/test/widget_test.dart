// Smoke test da tela de login — não depende de Supabase.initialize() porque
// LoginScreen só toca o client Supabase ao submeter o formulário, não no
// build inicial.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inan_backoffice/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen exibe campos de e-mail e senha', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });
}
