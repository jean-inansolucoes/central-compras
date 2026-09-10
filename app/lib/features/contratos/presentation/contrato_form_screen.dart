import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/contrato_model.dart';
import '../providers/contrato_providers.dart';

class ContratoFormScreen extends ConsumerStatefulWidget {
  const ContratoFormScreen({super.key, this.contrato});

  final Contrato? contrato;

  @override
  ConsumerState<ContratoFormScreen> createState() => _ContratoFormScreenState();
}

/// Tamanho máximo (em caracteres) de nome exibido nos seletores de
/// Cliente/Produto do formulário de Contrato — nomes maiores estouravam o
/// campo (razão social longa quebrava o layout do dropdown). Só afeta a
/// exibição; o valor selecionado/salvo continua sendo o nome completo.
const _kDropdownLabelMaxChars = 32;

String _ellipsize(String text, {int maxChars = _kDropdownLabelMaxChars}) {
  if (text.length <= maxChars) {
    return text;
  }
  return '${text.substring(0, maxChars).trimRight()}…';
}

class _ContratoFormScreenState extends ConsumerState<ContratoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthlyValue;
  int? _customerId;
  int? _productId;
  late DateTime _date;
  late DateTime _endDate;
  late bool _trial;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.contrato != null;

  @override
  void initState() {
    super.initState();
    final contrato = widget.contrato;
    _customerId = contrato?.customerId;
    _productId = contrato?.productId;
    _date = contrato?.date ?? DateTime.now();
    _endDate = contrato?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _trial = contrato?.trial ?? true;
    _monthlyValue = TextEditingController(
      text: contrato != null ? contrato.monthlyValue.toStringAsFixed(2) : '0.00',
    );
  }

  @override
  void dispose() {
    _monthlyValue.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _date : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _date = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_customerId == null || _productId == null) {
      setState(() => _errorMessage = 'Selecione o cliente e o produto.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final contrato = (widget.contrato ??
              Contrato(
                customerId: _customerId!,
                productId: _productId!,
                date: _date,
                endDate: _endDate,
                monthlyValue: 0,
                trial: _trial,
              ))
          .copyWith(
        customerId: _customerId,
        productId: _productId,
        date: _date,
        endDate: _endDate,
        monthlyValue: double.parse(_monthlyValue.text.replaceAll(',', '.')),
        trial: _trial,
      );

      final repository = ref.read(contratoRepositoryProvider);
      if (_isEditing) {
        await repository.update(contrato);
      } else {
        await repository.create(contrato);
      }
      ref.invalidate(contratosListProvider);
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
    final clienteNomesAsync = ref.watch(clienteNomesProvider);
    final produtoNomesAsync = ref.watch(produtoNomesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Alterar contrato' : 'Novo contrato')),
      body: clienteNomesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text('Erro ao carregar clientes: $error')),
        data: (clienteNomes) {
          return produtoNomesAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => Center(child: Text('Erro ao carregar produtos: $error')),
            data: (produtoNomes) {
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _customerId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: [
                        for (final entry in clienteNomes.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              _ellipsize(entry.value),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _customerId = value),
                      validator: (value) => value == null ? 'Selecione um cliente' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _productId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Produto'),
                      items: [
                        for (final entry in produtoNomes.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              _ellipsize(entry.value),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _productId = value),
                      validator: (value) => value == null ? 'Selecione um produto' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Início',
                            date: _date,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Vencimento',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _monthlyValue,
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Trial (período de teste)'),
                      value: _trial,
                      onChanged: (value) => setState(() => _trial = value),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.perigo)),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(label: 'Salvar', loading: _saving, onPressed: _save),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
      ),
    );
  }
}
