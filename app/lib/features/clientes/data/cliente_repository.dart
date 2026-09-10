import 'package:supabase_flutter/supabase_flutter.dart';

import 'cliente_model.dart';

class ClienteRepository {
  ClienteRepository(this._client);

  final SupabaseClient _client;

  Future<List<Cliente>> list({String? search}) async {
    var query = _client.from('CUSTOMER').select().eq('DELETED', 'N');
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('NAME', '%${search.trim()}%');
    }
    final data = await query.order('NAME');
    return (data as List).map((row) => Cliente.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<Cliente> create(Cliente cliente) async {
    final data =
        await _client.from('CUSTOMER').insert(cliente.toInsertMap()).select().single();
    return Cliente.fromMap(data);
  }

  Future<Cliente> update(Cliente cliente) async {
    final data = await _client
        .from('CUSTOMER')
        .update(cliente.toInsertMap())
        .eq('ID', cliente.id!)
        .select()
        .single();
    return Cliente.fromMap(data);
  }

  /// Exclusão lógica — mantém compatibilidade com a leitura por
  /// `DELETED=eq.N` que o AdvPL já faz em produção.
  Future<void> softDelete(int id) async {
    await _client.from('CUSTOMER').update({'DELETED': 'S'}).eq('ID', id);
  }

  /// Lista leve (id + nome) para popular seletores em outras telas (ex.:
  /// formulário de Contrato) — inclui inativos para que contratos antigos
  /// continuem resolvendo o nome do cliente vinculado.
  Future<Map<int, String>> idNameMap() async {
    final data = await _client.from('CUSTOMER').select('ID, NAME').order('NAME');
    return {
      for (final row in data as List)
        (row as Map<String, dynamic>)['ID'] as int: row['NAME'] as String? ?? '',
    };
  }
}
