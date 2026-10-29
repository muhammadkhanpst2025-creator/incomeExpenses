class KhataAccount {
  final int? id;
  final String name, type, category, address, phone, createdAt, openingDate;
  final double balance, openingBalance;
  final bool active;
  const KhataAccount({this.id, required this.name, required this.type, this.category='', this.address='', this.phone='', this.balance=0, this.openingBalance=0, this.openingDate='', this.active=true, this.createdAt=''});
  factory KhataAccount.fromMap(Map<String,dynamic> m) => KhataAccount(id: m['id'] as int?, name: '${m['name'] ?? ''}', type: '${m['type'] ?? 'wallet'}', category: '${m['category'] ?? ''}', address: '${m['address'] ?? ''}', phone: '${m['phone'] ?? ''}', balance: (m['balance'] as num? ?? 0).toDouble(), openingBalance: (m['openingBalance'] as num? ?? 0).toDouble(), openingDate: '${m['openingDate'] ?? ''}', active: (m['active'] as num? ?? 1) == 1, createdAt: '${m['createdAt'] ?? ''}');
  bool get isWallet => type == 'wallet';
  bool get isPayable => type == 'payable';
  bool get isReceivable => type == 'receivable';
}
class KhataTransaction {
  final int? id;
  final String type, category, note, date;
  final int? accountId, toAccountId;
  final double amount;
  const KhataTransaction({this.id, required this.type, this.accountId, this.toAccountId, required this.amount, this.category='', this.note='', required this.date});
  factory KhataTransaction.fromMap(Map<String,dynamic> m) => KhataTransaction(id:m['id'] as int?, type:'${m['type']}', accountId:m['accountId'] as int?, toAccountId:m['toAccountId'] as int?, amount:(m['amount'] as num).toDouble(), category:'${m['category']??''}', note:'${m['note']??''}', date:'${m['date']}');
}
extension FirstOrNullExtension<T> on List<T> { T? get firstOrNull => isEmpty ? null : first; }
