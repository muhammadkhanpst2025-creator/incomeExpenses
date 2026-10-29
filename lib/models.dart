
class KhataAccount {
  final int? id;
  final String name;
  final String type;
  final String category;
  final String address;
  final String phone;
  final double balance;
  final bool active;
  final DateTime createdAt;

  const KhataAccount({
    this.id,
    required this.name,
    required this.type,
    this.category = '',
    this.address = '',
    this.phone = '',
    this.balance = 0,
    this.active = true,
    required this.createdAt,
  });

  bool get isWallet => type == 'wallet';
  bool get isPayable => type == 'payable';
  bool get isReceivable => type == 'receivable';

  factory KhataAccount.fromMap(Map<String, dynamic> map) {
    return KhataAccount(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'wallet',
      category: map['category']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      active: (map['active'] as num?)?.toInt() != 0,
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'category': category,
      'address': address,
      'phone': phone,
      'balance': balance,
      'active': active ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  KhataAccount copyWith({
    int? id,
    String? name,
    String? type,
    String? category,
    String? address,
    String? phone,
    double? balance,
    bool? active,
    DateTime? createdAt,
  }) {
    return KhataAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class KhataTransaction {
  final int? id;
  final String type;
  final int? accountId;
  final int? toAccountId;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  const KhataTransaction({
    this.id,
    required this.type,
    this.accountId,
    this.toAccountId,
    required this.amount,
    this.category = '',
    this.note = '',
    required this.date,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isPayment => type == 'payment';
  bool get isTransfer => type == 'transfer';

  factory KhataTransaction.fromMap(Map<String, dynamic> map) {
    return KhataTransaction(
      id: map['id'] as int?,
      type: map['type']?.toString() ?? 'expense',
      accountId: (map['accountId'] as num?)?.toInt(),
      toAccountId: (map['toAccountId'] as num?)?.toInt(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  KhataTransaction copyWith({
    int? id,
    String? type,
    int? accountId,
    int? toAccountId,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return KhataTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
