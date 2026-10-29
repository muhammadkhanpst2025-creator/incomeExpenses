
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class KhataDatabase {
  KhataDatabase._();

  static final KhataDatabase instance = KhataDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sahil_khata.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    return _database!;
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        balance REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        accountId INTEGER,
        toAccountId INTEGER,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );

    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(accountId)',
    );

    final now = DateTime.now().toIso8601String();

    await db.insert('accounts', {
      'name': 'Cash',
      'type': 'wallet',
      'category': 'Cash',
      'balance': 0.0,
      'createdAt': now,
    });

    await db.insert('accounts', {
      'name': 'Bank',
      'type': 'wallet',
      'category': 'Bank',
      'balance': 0.0,
      'createdAt': now,
    });
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Version 1 se version 2 par aane par purane accounts
    // aur transactions ko delete nahi kiya jata.
    if (oldVersion < 2) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_date
        ON transactions(date)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_account
        ON transactions(accountId)
      ''');
    }
  }

  // ---------------- ACCOUNTS ----------------

  Future<int> saveAccount(Map<String, dynamic> account) async {
    final db = await database;
    final data = Map<String, dynamic>.from(account);

    final id = data.remove('id');

    if (id != null) {
      final existing = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Existing account ka balance edit karne se
        // transaction history ke balances kharab na hon.
        data.remove('balance');

        await db.update(
          'accounts',
          data,
          where: 'id = ?',
          whereArgs: [id],
        );

        return id as int;
      }
    }

    data.putIfAbsent(
      'createdAt',
      () => DateTime.now().toIso8601String(),
    );
    data.putIfAbsent('balance', () => 0.0);
    data.putIfAbsent('active', () => 1);
    data.putIfAbsent('category', () => '');
    data.putIfAbsent('address', () => '');
    data.putIfAbsent('phone', () => '');

    return db.insert('accounts', data);
  }

  Future<List<Map<String, dynamic>>> getAccounts({
    String? type,
    bool activeOnly = true,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }

    if (activeOnly) {
      conditions.add('active = 1');
    }

    return db.query(
      'accounts',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<Map<String, dynamic>?> getAccount(int id) async {
    final db = await database;
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setAccountActive(int id, bool active) async {
    final db = await database;

    await db.update(
      'accounts',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAccount(int id) async {
    // History wale account ko delete karne ke bajaye
    // inactive karte hain.
    final db = await database;

    final rows = await db.query(
      'transactions',
      where: 'accountId = ? OR toAccountId = ?',
      whereArgs: [id, id],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      await setAccountActive(id, false);
      return;
    }

    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- TRANSACTIONS ----------------

  Future<int> saveTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final db = await database;

    return db.transaction((txn) async {
      final data = Map<String, dynamic>.from(transaction);
      final rawId = data.remove('id');
      final int? id = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');

      if (id != null) {
        final oldRows = await txn.query(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (oldRows.isNotEmpty) {
          await _applyBalanceChange(txn, oldRows.first, reverse: true);

          await txn.update(
            'transactions',
            data,
            where: 'id = ?',
            whereArgs: [id],
          );

          final updatedRows = await txn.query(
            'transactions',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );

          await _applyBalanceChange(txn, updatedRows.first);
          return id;
        }
      }

      final newId = await txn.insert('transactions', data);

      final insertedRows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [newId],
        limit: 1,
      );

      await _applyBalanceChange(txn, insertedRows.first);
      return newId;
    });
  }

  Future<void> _applyBalanceChange(
    Transaction txn,
    Map<String, dynamic> item, {
    bool reverse = false,
  }) async {
    final amount = (item['amount'] as num).toDouble();
    final type = item['type'] as String;
    final accountId = item['accountId'] as int?;
    final toAccountId = item['toAccountId'] as int?;

    final direction = reverse ? -1.0 : 1.0;

    Future<void> change(int? id, double delta) async {
      if (id == null) return;

      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [delta * direction, id],
      );
    }

    if (type == 'income') {
      // Receivable account ka outstanding kam,
      // aur receive hone wali amount wallet mein add.
      await change(accountId, amount);
      await change(toAccountId, amount);
    } else if (type == 'expense') {
      if (accountId != null) {
        final rows = await txn.query(
          'accounts',
          columns: ['type'],
          where: 'id = ?',
          whereArgs: [accountId],
          limit: 1,
        );

        if (rows.isNotEmpty && rows.first['type'] == 'payable') {
          // Udhar expense se payable barhta hai.
          await change(accountId, -amount);
        } else {
          // Cash/Bank se direct expense.
          await change(accountId, -amount);
        }
      }
    } else if (type == 'payment') {
      // Payable ki payment se udhar kam,
      // wallet se paisay kam.
      await change(accountId, amount);
      await change(toAccountId, -amount);
    } else if (type == 'transfer') {
      await change(accountId, -amount);
      await change(toAccountId, amount);
    }
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return;

      await _applyBalanceChange(txn, rows.first, reverse: true);

      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int? accountId,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (accountId != null) {
      conditions.add('(accountId = ? OR toAccountId = ?)');
      args.add(accountId);
      args.add(accountId);
    }

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }

    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }

    if (to != null) {
      final endOfDay = DateTime(
        to.year,
        to.month,
        to.day,
        23,
        59,
        59,
      );

      conditions.add('date <= ?');
      args.add(endOfDay.toIso8601String());
    }

    return db.query(
      'transactions',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
  }

  // ---------------- DASHBOARD TOTALS ----------------

  Future<double> getTotalByType(String type) async {
    final db = await database;

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(balance), 0) AS total '
      'FROM accounts WHERE type = ? AND active = 1',
      [type],
    );

    return (rows.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getDashboardTotals() async {
    final cash = await getTotalByType('wallet');
    final payable = await getTotalByType('payable');
    final receivable = await getTotalByType('receivable');

    return {
      'wallet': cash,
      'payable': payable,
      'receivable': receivable,
      'netWorth': cash + receivable - payable,
    };
  }

  Future<Map<String, double>> getIncomeExpenseTotals({
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await getTransactions(from: from, to: to);

    double income = 0;
    double expense = 0;

    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();

      if (row['type'] == 'income') income += amount;
      if (row['type'] == 'expense') expense += amount;
    }

    return {
      'income': income,
      'expense': expense,
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
