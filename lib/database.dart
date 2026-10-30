
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
      version: 4,
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
        openingBalance REAL NOT NULL DEFAULT 0,
        openingDate TEXT NOT NULL DEFAULT '',
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
    // Existing rows and transaction history are retained during upgrades.
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
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE accounts ADD COLUMN openingBalance REAL NOT NULL DEFAULT 0');
      await db.execute("ALTER TABLE accounts ADD COLUMN openingDate TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 4) {
      // Preserve each existing account's current balance as its opening amount
      // after subtracting the net effect of its already-saved transactions.
      final accounts = await db.query('accounts');
      final transactions = await db.query('transactions');
      for (final account in accounts) {
        final id = account['id'] as int;
        final accountType = account['type'];
        double movement = 0;
        for (final row in transactions) {
          final amount = (row['amount'] as num).toDouble();
          final type = row['type'];
          if (row['accountId'] == id) {
            if (type == 'expense') movement += accountType == 'payable' ? amount : -amount;
            if (type == 'payment') movement -= amount;
            if (type == 'income') movement -= amount;
            if (type == 'transfer') movement -= amount;
          }
          if (row['toAccountId'] == id) {
            if (type == 'income' || type == 'transfer') movement += amount;
            if (type == 'payment') movement -= amount;
          }
        }
        final oldBalance = (account['balance'] as num? ?? 0).toDouble();
        final targetBalance = accountType == 'payable' ? oldBalance.abs() : oldBalance;
        await db.update('accounts', {'openingBalance': targetBalance - movement}, where: 'id = ?', whereArgs: [id]);
      }
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
        data.remove('balance');
        await db.update('accounts', data, where: 'id = ?', whereArgs: [id]);
        await _recalculateAccountBalance(db, id as int);
        return id;
      }
    }

    data.putIfAbsent(
      'createdAt',
      () => DateTime.now().toIso8601String(),
    );
    data.putIfAbsent('balance', () => 0.0);
    data.putIfAbsent('openingBalance', () => 0.0);
    data.putIfAbsent('openingDate', () => DateTime.now().toIso8601String());
    data.putIfAbsent('active', () => 1);
    data.putIfAbsent('category', () => '');
    data.putIfAbsent('address', () => '');
    data.putIfAbsent('phone', () => '');

    final newId = await db.insert('accounts', data);
    await _recalculateAccountBalance(db, newId);
    return newId;
  }


  Future<void> _recalculateAccountBalance(DatabaseExecutor db, int accountId) async {
    final accountRows = await db.query('accounts', where: 'id = ?', whereArgs: [accountId], limit: 1);
    if (accountRows.isEmpty) return;
    final account = accountRows.first;
    final accountType = account['type'];
    double balance = (account['openingBalance'] as num? ?? 0).toDouble();
    final rows = await db.query('transactions', where: 'accountId = ? OR toAccountId = ?', whereArgs: [accountId, accountId]);
    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'];
      if (row['accountId'] == accountId) {
        if (type == 'expense') balance += accountType == 'payable' ? amount : -amount;
        if (type == 'payment' || type == 'income' || type == 'transfer') balance -= amount;
      }
      if (row['toAccountId'] == accountId) {
        if (type == 'income' || type == 'transfer') balance += amount;
        if (type == 'payment') balance -= amount;
      }
    }
    await db.update('accounts', {'balance': balance}, where: 'id = ?', whereArgs: [accountId]);
  }

  Future<void> recalculateAllBalances() async {
    final db = await database;
    final rows = await db.query('accounts');
    await db.transaction((txn) async {
      for (final row in rows) {
        await _recalculateAccountBalance(txn, row['id'] as int);
      }
    });
  }

  Future<Map<String, double>> getOutstandingTotals() async {
    final db = await database;
    final rows = await db.rawQuery("SELECT type, COALESCE(SUM(ABS(balance)),0) AS total FROM accounts WHERE active=1 AND type IN ('payable','receivable') GROUP BY type");
    double payable = 0, receivable = 0;
    for (final row in rows) {
      final total = (row['total'] as num).toDouble();
      if (row['type'] == 'payable') payable = total;
      if (row['type'] == 'receivable') receivable = total;
    }
    return {'payable': payable, 'receivable': receivable};
  }

  Future<Map<String, dynamic>> getAccountStatement(int accountId, DateTime from, DateTime to) async {
    final db = await database;
    final accountRows = await db.query('accounts', where: 'id = ?', whereArgs: [accountId], limit: 1);
    if (accountRows.isEmpty) throw Exception('Account not found');
    final accountType = accountRows.first['type'];
    final openingDate = DateTime.tryParse('${accountRows.first['openingDate'] ?? ''}');
    final fromDay = DateTime(from.year, from.month, from.day);
    final openingDay = openingDate == null ? null : DateTime(openingDate.year, openingDate.month, openingDate.day);
    final all = await db.query('transactions', where: openingDay == null
        ? 'date < ?'
        : 'date >= ? AND date < ?', whereArgs: openingDay == null
        ? [fromDay.toIso8601String()]
        : [openingDay.toIso8601String(), fromDay.toIso8601String()], orderBy: 'date ASC, id ASC');
    double opening = openingDay != null && openingDay.isAfter(fromDay)
        ? 0
        : (accountRows.first['openingBalance'] as num? ?? 0).toDouble();
    double deltaFor(Map<String, dynamic> row) {
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'];
      if (row['accountId'] == accountId) {
        if (type == 'expense') return accountType == 'payable' ? amount : -amount;
        if (type == 'payment' || type == 'income' || type == 'transfer') return -amount;
      }
      if (row['toAccountId'] == accountId && (type == 'income' || type == 'transfer')) return amount;
      if (row['toAccountId'] == accountId && type == 'payment') return -amount;
      return 0;
    }
    for (final row in all) { opening += deltaFor(row); }
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final rows = await db.query('transactions', where: '(accountId = ? OR toAccountId = ?) AND date >= ? AND date <= ?', whereArgs: [accountId, accountId, (openingDay != null && openingDay.isAfter(fromDay) ? openingDay : fromDay).toIso8601String(), end.toIso8601String()], orderBy: 'date ASC, id ASC');
    double running = opening;
    final details = <Map<String, dynamic>>[];
    for (final row in rows) {
      final delta = deltaFor(row);
      final cr = delta > 0 ? delta : 0.0;
      final dr = delta < 0 ? -delta : 0.0;
      running += delta;
      details.add({...row, 'cr': cr, 'dr': dr, 'runningBalance': running});
    }
    return {'account': accountRows.first, 'opening': opening, 'closing': running, 'transactions': details};
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
          final oldAccountId = oldRows.first['accountId'] as int?;
          final oldToAccountId = oldRows.first['toAccountId'] as int?;
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

          final ids = <int>{if (oldAccountId != null) oldAccountId, if (oldToAccountId != null) oldToAccountId, if (updatedRows.first['accountId'] != null) updatedRows.first['accountId'] as int, if (updatedRows.first['toAccountId'] != null) updatedRows.first['toAccountId'] as int};
          for (final accountId in ids) { await _recalculateAccountBalance(txn, accountId); }
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

      final ids = <int>{if (insertedRows.first['accountId'] != null) insertedRows.first['accountId'] as int, if (insertedRows.first['toAccountId'] != null) insertedRows.first['toAccountId'] as int};
      for (final accountId in ids) { await _recalculateAccountBalance(txn, accountId); }
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

      final affected = <int>{if (rows.first['accountId'] != null) rows.first['accountId'] as int, if (rows.first['toAccountId'] != null) rows.first['toAccountId'] as int};
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      for (final accountId in affected) { await _recalculateAccountBalance(txn, accountId); }
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