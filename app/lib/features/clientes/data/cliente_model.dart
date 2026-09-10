/// Espelha a tabela CUSTOMER do Supabase — mesma tabela que o AdvPL
/// (`JSGLBPAR.prw` / `getCustomer`) já lê/escreve em produção para
/// identificar a empresa-tenant pelo CNPJ. Não renomear/remover campos
/// sem checar o impacto no addon AdvPL.
class Cliente {
  const Cliente({
    this.id,
    required this.name,
    required this.fantasy,
    required this.address,
    required this.city,
    required this.state,
    required this.neighborhood,
    required this.phone,
    required this.cgcCpf,
    this.deleted = 'N',
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['ID'] as int?,
      name: map['NAME'] as String? ?? '',
      fantasy: map['FANTASY'] as String? ?? '',
      address: map['ADDRESS'] as String? ?? '',
      city: map['CITY'] as String? ?? '',
      state: map['STATE'] as String? ?? '',
      neighborhood: map['NEIGHBORHOOD'] as String? ?? '',
      phone: map['PHONE'] as String? ?? '',
      cgcCpf: map['CGCCPF'] as String? ?? '',
      deleted: map['DELETED'] as String? ?? 'N',
    );
  }

  final int? id;
  final String name;
  final String fantasy;
  final String address;
  final String city;
  final String state;
  final String neighborhood;
  final String phone;
  final String cgcCpf;
  final String deleted;

  bool get isActive => deleted != 'S';

  Map<String, dynamic> toInsertMap() => {
        'NAME': name,
        'FANTASY': fantasy,
        'ADDRESS': address,
        'CITY': city,
        'STATE': state,
        'NEIGHBORHOOD': neighborhood,
        'PHONE': phone,
        'CGCCPF': cgcCpf,
        'DELETED': deleted,
      };

  Cliente copyWith({
    int? id,
    String? name,
    String? fantasy,
    String? address,
    String? city,
    String? state,
    String? neighborhood,
    String? phone,
    String? cgcCpf,
    String? deleted,
  }) {
    return Cliente(
      id: id ?? this.id,
      name: name ?? this.name,
      fantasy: fantasy ?? this.fantasy,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      neighborhood: neighborhood ?? this.neighborhood,
      phone: phone ?? this.phone,
      cgcCpf: cgcCpf ?? this.cgcCpf,
      deleted: deleted ?? this.deleted,
    );
  }
}
