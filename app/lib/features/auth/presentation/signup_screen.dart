import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _accountCreated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      await ref.read(authRepositoryProvider).signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      setState(() => _accountCreated = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _accountCreated
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          color: AppColors.sucesso, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Conta criada! Confirme seu e-mail para poder entrar.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Um administrador precisa liberar o acesso da sua empresa '
                        'antes que você consiga ver seus dados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textoSuave),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nome'),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Senha'),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Mínimo de 6 caracteres';
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
                          label: 'Criar conta',
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
