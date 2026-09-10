import 'package:supabase_flutter/supabase_flutter.dart';

import 'produto_model.dart';

class ProdutoRepository {
  ProdutoRepository(this._client);

  final SupabaseClient _client;

  Future<List<Produto>> list() async {
    final data = await _client.from('PRODUCT').select().eq('DELETED', 'N').order('NAME');
    return (data as List).map((row) => Produto.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<Produto> create(Produto produto) async {
    final data = await _client.from('PRODUCT').insert(produto.toInsertMap()).select().single();
    return Produto.fromMap(data);
  }

  Future<Produto> update(Produto produto) async {
    final data = await _client
        .from('PRODUCT')
        .update(produto.toInsertMap())
        .eq('ID', produto.id!)
        .select()
        .single();
    return Produto.fromMap(data);
  }

  Future<void> softDelete(int id) async {
    await _client.from('PRODUCT').update({'DELETED': 'S'}).eq('ID', id);
  }

  /// Lista leve (id + nome), incluindo inativos, para seletores em outras
  /// telas (ex.: formulário de Contrato).
  Future<Map<int, String>> idNameMap() async {
    final data = await _client.from('PRODUCT').select('ID, NAME').order('NAME');
    return {
      for (final row in data as List)
        (row as Map<String, dynamic>)['ID'] as int: row['NAME'] as String? ?? '',
    };
  }
}
