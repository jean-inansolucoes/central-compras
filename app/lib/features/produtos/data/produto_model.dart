/// Espelha a tabela PRODUCT do Supabase (já existente). O `id=1` é usado
/// hoje como constante `APP_ID` pelo AdvPL para representar o SmartSupply —
/// não excluir esse registro.
class Produto {
  const Produto({
    this.id,
    required this.name,
    required this.price,
    this.deleted = 'N',
  });

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['ID'] as int?,
      name: map['NAME'] as String? ?? '',
      price: (map['PRICE'] as num?)?.toDouble() ?? 0,
      deleted: map['DELETED'] as String? ?? 'N',
    );
  }

  final int? id;
  final String name;
  final double price;
  final String deleted;

  bool get isActive => deleted != 'S';

  Map<String, dynamic> toInsertMap() => {
        'NAME': name,
        'PRICE': price,
        'DELETED': deleted,
      };

  Produto copyWith({int? id, String? name, double? price, String? deleted}) {
    return Produto(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      deleted: deleted ?? this.deleted,
    );
  }
}
