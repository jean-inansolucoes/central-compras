import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(
            _emailController.text.trim(),
          );
      setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível enviar o e-mail. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent
                ? const Text(
                    'Se o e-mail informado tiver uma conta, enviamos um link de '
                    'redefinição de senha.',
                    textAlign: TextAlign.center,
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-mail'),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.perigo)),
                        ],
                        const SizedBox(height: 20),
                        AppPrimaryButton(
                          label: 'Enviar link',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
