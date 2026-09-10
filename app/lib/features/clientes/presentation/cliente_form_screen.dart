import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../data/cliente_model.dart';
import '../providers/cliente_providers.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  const ClienteFormScreen({super.key, this.cliente});

  final Cliente? cliente;

  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _fantasy;
  late final TextEditingController _cgcCpf;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _neighborhood;
  late final TextEditingController _city;
  late final TextEditingController _state;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final cliente = widget.cliente;
    _name = TextEditingController(text: cliente?.name ?? '');
    _fantasy = TextEditingController(text: cliente?.fantasy ?? '');
    _cgcCpf = TextEditingController(text: cliente?.cgcCpf ?? '');
    _phone = TextEditingController(text: cliente?.phone ?? '');
    _address = TextEditingController(text: cliente?.address ?? '');
    _neighborhood = TextEditingController(text: cliente?.neighborhood ?? '');
    _city = TextEditingController(text: cliente?.city ?? '');
    _state = TextEditingController(text: cliente?.state ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _fantasy.dispose();
    _cgcCpf.dispose();
    _phone.dispose();
    _address.dispose();
    _neighborhood.dispose();
    _city.dispose();
    _state.dispose();
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
      final cliente = (widget.cliente ?? const Cliente(
        name: '',
        fantasy: '',
        address: '',
        city: '',
        state: '',
        neighborhood: '',
        phone: '',
        cgcCpf: '',
      )).copyWith(
        name: _name.text.trim(),
        fantasy: _fantasy.text.trim(),
        cgcCpf: _cgcCpf.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        neighborhood: _neighborhood.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim().toUpperCase(),
      );

      final repository = ref.read(clienteRepositoryProvider);
      if (_isEditing) {
        await repository.update(cliente);
      } else {
        await repository.create(cliente);
      }
      ref.invalidate(clientesListProvider);
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

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Alterar cliente' : 'Novo cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Razão social'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fantasy,
              decoration: const InputDecoration(labelText: 'Nome fantasia'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cgcCpf,
              decoration: const InputDecoration(labelText: 'CNPJ/CPF'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _neighborhood,
              decoration: const InputDecoration(labelText: 'Bairro'),
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    child: TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      controller: _state,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'UF', counterText: ''),
                    ),
                  ),
                ),
              ],
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
