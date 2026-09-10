/// Espelha a tabela CONTRACT do Supabase — a assinatura SaaS de um Cliente
/// (CUSTOMERID) para um Produto (PRODUCTID). Mesma tabela usada pelo AdvPL
/// (`JSGLBPAR.prw` / `getContract`, `setLastAcc`) para liberar/bloquear o
/// SmartSupply em cada instalação; não renomear/remover campos.
class Contrato {
  const Contrato({
    this.id,
    required this.customerId,
    required this.productId,
    required this.date,
    required this.endDate,
    required this.monthlyValue,
    required this.trial,
    this.lastAccess,
    this.appVersion,
    this.deleted = 'N',
  });

  factory Contrato.fromMap(Map<String, dynamic> map) {
    return Contrato(
      id: map['ID'] as int?,
      customerId: map['CUSTOMERID'] as int,
      productId: map['PRODUCTID'] as int,
      date: DateTime.parse(map['DATE'] as String),
      endDate: DateTime.parse(map['ENDDATE'] as String),
      monthlyValue: (map['MONTHLYVALUE'] as num?)?.toDouble() ?? 0,
      trial: map['TRIAL'] as bool? ?? false,
      lastAccess: map['LASTACCESS'] as String?,
      appVersion: map['APPVERSION'] as String?,
      deleted: map['DELETED'] as String? ?? 'N',
    );
  }

  final int? id;
  final int customerId;
  final int productId;
  final DateTime date;
  final DateTime endDate;
  final double monthlyValue;
  final bool trial;
  final String? lastAccess;
  final String? appVersion;
  final String deleted;

  bool get isActive => deleted != 'S';

  String get _isoDate => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String get _isoEndDate => '${endDate.year.toString().padLeft(4, '0')}-'
      '${endDate.month.toString().padLeft(2, '0')}-'
      '${endDate.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toInsertMap() => {
        'CUSTOMERID': customerId,
        'PRODUCTID': productId,
        'DATE': _isoDate,
        'ENDDATE': _isoEndDate,
        'MONTHLYVALUE': monthlyValue,
        'TRIAL': trial,
        'DELETED': deleted,
      };

  Contrato copyWith({
    int? id,
    int? customerId,
    int? productId,
    DateTime? date,
    DateTime? endDate,
    double? monthlyValue,
    bool? trial,
    String? deleted,
  }) {
    return Contrato(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      monthlyValue: monthlyValue ?? this.monthlyValue,
      trial: trial ?? this.trial,
      lastAccess: lastAccess,
      appVersion: appVersion,
      deleted: deleted ?? this.deleted,
    );
  }
}
