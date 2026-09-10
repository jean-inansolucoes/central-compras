import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../data/produto_model.dart';
import '../providers/produto_providers.dart';

class ProdutoFormScreen extends ConsumerStatefulWidget {
  const ProdutoFormScreen({super.key, this.produto});

  final Produto? produto;

  @override
  ConsumerState<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends ConsumerState<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late bool _active;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final produto = widget.produto;
    _name = TextEditingController(text: produto?.name ?? '');
    _price = TextEditingController(
      text: produto != null ? produto.price.toStringAsFixed(2) : '',
    );
    _active = produto?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final produto = (widget.produto ?? const Produto(name: '', price: 0)).copyWith(
        name: _name.text.trim(),
        price: double.parse(_price.text.replaceAll(',', '.')),
        deleted: _active ? 'N' : 'S',
      );

      final repository = ref.read(produtoRepositoryProvider);
      if (_isEditing) {
        await repository.update(produto);
      } else {
        await repository.create(produto);
      }
      ref.invalidate(produtosListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Não foi possível salvar: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Alterar produto' : 'Novo produto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do produto'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal (R\$)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                if (double.tryParse(value.replaceAll(',', '.')) == null) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.perigo)),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(label: 'Salvar', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
