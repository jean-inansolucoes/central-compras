import 'package:supabase_flutter/supabase_flutter.dart';

import 'contrato_model.dart';

class ContratoRepository {
  ContratoRepository(this._client);

  final SupabaseClient _client;

  Future<List<Contrato>> list({int? customerId}) async {
    var query = _client.from('CONTRACT').select().eq('DELETED', 'N');
    if (customerId != null) {
      query = query.eq('CUSTOMERID', customerId);
    }
    final data = await query.order('DATE', ascending: false);
    return (data as List).map((row) => Contrato.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<Contrato> create(Contrato contrato) async {
    final data = await _client.from('CONTRACT').insert(contrato.toInsertMap()).select().single();
    return Contrato.fromMap(data);
  }

  Future<Contrato> update(Contrato contrato) async {
    final data = await _client
        .from('CONTRACT')
        .update(contrato.toInsertMap())
        .eq('ID', contrato.id!)
        .select()
        .single();
    return Contrato.fromMap(data);
  }

  Future<void> softDelete(int id) async {
    await _client.from('CONTRACT').update({'DELETED': 'S'}).eq('ID', id);
  }
}
