
import 'package:flutter/material.dart';

import 'database.dart';
import 'models.dart';
import 'widgets.dart';
import 'reports.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IncomeExpensesApp());
}

class IncomeExpensesApp extends StatelessWidget {
  const IncomeExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income & Expenses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          primary: purple,
          secondary: green,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedTab = 0;

  final pages = const [
    DashboardPage(),
    AccountsPage(),
    TransactionsPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[selectedTab]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: purple.withValues(alpha: 0.2)),
          ),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedTab,
          backgroundColor: Colors.white,
          indicatorColor: purple.withValues(alpha: 0.13),
          onDestinationSelected: (index) {
            setState(() => selectedTab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: purple),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet, color: green),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: neonBlue),
              label: 'Entries',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: red),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- DASHBOARD ----------------

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final db = KhataDatabase.instance;

  bool loading = true;
  List<KhataAccount> accounts = [];
  Map<String, double> totals = {};
  Map<String, double> monthlyTotals = {};
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    if (mounted) setState(() => loading = true);

    try {
      final rawAccounts = await db.getAccounts();
      final newTotals = await db.getDashboardTotals();

      final start = DateTime(selectedMonth.year, selectedMonth.month);
      final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      final newMonthlyTotals = await db.getIncomeExpenseTotals(
        from: start,
        to: end,
      );

      if (!mounted) return;

      setState(() {
        accounts = rawAccounts.map(KhataAccount.fromMap).toList();
        totals = newTotals;
        monthlyTotals = newMonthlyTotals;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data load nahi hua: $e')),
      );
    }
  }

  List<KhataAccount> get wallets =>
      accounts.where((a) => a.isWallet).toList();

  List<KhataAccount> get payables =>
      accounts.where((a) => a.isPayable).toList();

  List<KhataAccount> get receivables =>
      accounts.where((a) => a.isReceivable).toList();

  double sumBalances(List<KhataAccount> list) =>
      list.fold(0.0, (sum, a) => sum + a.balance);

  Future<void> changeMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Report ka month select karein',
    );

    if (picked == null) return;

    selectedMonth = DateTime(picked.year, picked.month);
    await refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final walletTotal = totals['wallet'] ?? 0.0;
    final netWorth = totals['netWorth'] ?? 0.0;
    final income = monthlyTotals['income'] ?? 0.0;
    final expense = monthlyTotals['expense'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, neonBlue],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income & Expenses',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your money, clearly managed',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshData,
                icon: const Icon(Icons.refresh_rounded, color: purple),
                tooltip: 'Refresh balances',
              ),
            ],
          ),
          const SizedBox(height: 22),

          GradientHeader(
            title: 'Net Balance',
            amount: money(netWorth),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _outlinedMetric(
                        'Income',
                        money(income),
                        green,
                        Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlinedMetric(
                        'Expenses',
                        money(expense),
                        red,
                        Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: changeMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: neonYellow,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          const SectionTitle(title: 'My Wallets'),
          const SizedBox(height: 12),

          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (wallets.isEmpty)
            _emptyMessage(
              'Bank ya Cash account add karein.',
              onTap: () => _openAccountForm(context),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 100,
              ),
              itemBuilder: (context, index) {
                final account = wallets[index];
                return AccountBalanceCard(
                  account: account,
                  compact: true,
                  onTap: () => _openAccountForm(context, account: account),
                );
              },
            ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Payable & Receivable'),
          const SizedBox(height: 12),

          _totalAccountCard(
            title: 'Payable',
            subtitle: 'Udhar / Dukandar Khata',
            amount: sumBalances(payables),
            color: const Color(0xFFFFB547),
            icon: Icons.call_made_rounded,
          ),
          const SizedBox(height: 10),
          _totalAccountCard(
            title: 'Receivable',
            subtitle: 'Salary / Rent / Amount to receive',
            amount: sumBalances(receivables),
            color: neonBlue,
            icon: Icons.call_received_rounded,
          ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Monthly Overview'),
          const SizedBox(height: 12),
          _monthlyChart(income, expense),

          const SizedBox(height: 26),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Developed by SAHIL JANWERY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlinedMetric(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color == red ? red : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalAccountCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return SurfaceCard(
      outlineColor: color.withValues(alpha: 0.7),
      gradientColors: [color.withValues(alpha: 0.17), Colors.white],
      child: Row(
        children: [
          NeonIconBadge(icon: icon, color: color),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              money(amount),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: amount < 0 ? red : ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyChart(double income, double expense) {
    final maximum = [income, expense, 1.0]
        .reduce((a, b) => a > b ? a : b);

    return SurfaceCard(
      outlineColor: purple.withValues(alpha: 0.45),
      child: Column(
        children: [
          _chartBar('Income', income, maximum, green),
          const SizedBox(height: 18),
          _chartBar('Expenses', expense, maximum, red),
          const SizedBox(height: 15),
          const Divider(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 9, color: green),
              SizedBox(width: 5),
              Text('Income', style: TextStyle(color: muted, fontSize: 12)),
              SizedBox(width: 20),
              Icon(Icons.circle, size: 9, color: red),
              SizedBox(width: 5),
              Text('Expenses', style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartBar(
    String label,
    double amount,
    double maximum,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              money(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: (amount / maximum).clamp(0.0, 1.0),
            minHeight: 13,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _emptyMessage(String message, {VoidCallback? onTap}) {
    return SurfaceCard(
      child: Column(
        children: [
          const NeonIconBadge(icon: Icons.add_card_rounded),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text('Add account'),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }
}

// ---------------- ACCOUNTS ----------------

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<KhataAccount> accounts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final rows = await KhataDatabase.instance.getAccounts(activeOnly: false);
    if (!mounted) return;
    setState(() {
      accounts = rows.map(KhataAccount.fromMap).toList();
      loading = false;
    });
  }

  Future<void> openForm([KhataAccount? account]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountForm(account: account),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Accounts',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => openForm(),
            icon: const Icon(Icons.add_circle_rounded, color: purple),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final type in ['wallet', 'payable', 'receivable']) ...[
                  SectionTitle(
                    title: type == 'wallet'
                        ? 'Bank & Cash'
                        : type == 'payable'
                            ? 'Payable Accounts'
                            : 'Receivable Accounts',
                  ),
                  const SizedBox(height: 10),
                  for (final account
                      in accounts.where((a) => a.type == type)) ...[
                    Opacity(
                      opacity: account.active ? 1 : 0.55,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AccountBalanceCard(
                          account: account,
                          onTap: () => openForm(account),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                ],
                FilledButton.icon(
                  onPressed: () => openForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Account'),
                ),
              ],
            ),
    );
  }
}

class AccountForm extends StatefulWidget {
  final KhataAccount? account;

  const AccountForm({super.key, this.account});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController phone;
  late final TextEditingController address;
  late final TextEditingController openingBalance;
  DateTime openingDate = DateTime.now();

  String type = 'wallet';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    name = TextEditingController(text: account?.name ?? '');
    category = TextEditingController(text: account?.category ?? '');
    phone = TextEditingController(text: account?.phone ?? '');
    address = TextEditingController(text: account?.address ?? '');
    openingBalance = TextEditingController(text: (account?.openingBalance ?? 0).toStringAsFixed(2));
    openingDate = DateTime.tryParse(account?.openingDate ?? '') ?? DateTime.now();
    type = account?.type ?? 'wallet';
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    phone.dispose();
    address.dispose();
    openingBalance.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await KhataDatabase.instance.saveAccount({
        if (widget.account?.id != null) 'id': widget.account!.id,
        'name': name.text.trim(),
        'type': type,
        'category': category.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        if (widget.account == null) 'openingBalance': double.tryParse(openingBalance.text) ?? 0.0,
        if (widget.account == null) 'balance': double.tryParse(openingBalance.text) ?? 0.0,
        if (widget.account == null) 'openingDate': openingDate.toIso8601String(),
        'createdAt': widget.account == null
            ? DateTime.now().toIso8601String()
            : (DateTime.tryParse(widget.account!.createdAt)?.toIso8601String()
                ?? DateTime.now().toIso8601String()),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account save nahi hua: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Account name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name likhein' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: const [
                DropdownMenuItem(value: 'wallet', child: Text('Bank / Cash')),
                DropdownMenuItem(value: 'payable', child: Text('Payable')),
                DropdownMenuItem(
                  value: 'receivable',
                  child: Text('Receivable'),
                ),
              ],
              onChanged: (v) => setState(() => type = v ?? 'wallet'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: category,
              decoration: const InputDecoration(
                labelText: 'Category (editable)',
                hintText: 'e.g. Shopkeeper, Salary, Rent',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
            ),
            if (widget.account == null) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: openingBalance,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Opening balance (Rs)', helperText: 'Purana udhar ya pehle se mojood raqam'),
                validator: (v) => v == null || (double.tryParse(v) == null) ? 'Sahi amount likhein' : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Opening balance date'),
                subtitle: Text(shortDate(openingDate)),
                trailing: const Icon(Icons.calendar_month, color: purple),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: openingDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => openingDate = picked);
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.save_rounded),
              label: Text(saving ? 'Saving...' : 'Save Account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- TRANSACTIONS ----------------

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final rows = await KhataDatabase.instance.getTransactions();
    if (!mounted) return;
    setState(() {
      transactions = rows;
      loading = false;
    });
  }

  Future<void> addEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionForm()),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: addEntry,
            icon: const Icon(Icons.add_circle_rounded, color: purple),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addEntry,
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text('Abhi koi transaction nahi hai.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final item = transactions[index];
                    final type = item['type']?.toString() ?? 'expense';
                    final amount = (item['amount'] as num).toDouble();
                    final isIncome = type == 'income';
                    final isExpense = type == 'expense';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        child: Row(
                          children: [
                            NeonIconBadge(
                              icon: isIncome
                                  ? Icons.south_west_rounded
                                  : isExpense
                                      ? Icons.north_east_rounded
                                      : Icons.swap_horiz_rounded,
                              color: isIncome ? green : isExpense ? red : purple,
                              size: 42,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['category']?.toString().isNotEmpty ==
                                            true
                                        ? item['category'].toString()
                                        : type.toUpperCase(),
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['note']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(item['date'].toString()),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  money(amount),
                                  style: TextStyle(
                                    color: isIncome ? green : isExpense ? red : ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit transaction',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.edit_outlined, color: purple, size: 20),
                                  onPressed: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionForm(transaction: item)));
                                    await load();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Delete transaction',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline, color: red, size: 20),
                                  onPressed: () async {
                                    final id = item['id'];
                                    if (id is! int) return;
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete entry?'),
                                        content: const Text('Entry delete hogi aur account balance reverse hoga.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await KhataDatabase.instance.deleteTransaction(id);
                                      await load();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    return date == null ? raw : shortDate(date);
  }
}

class TransactionForm extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  const TransactionForm({super.key, this.transaction});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  final category = TextEditingController();

  List<KhataAccount> accounts = [];
  String type = 'expense';
  int? accountId;
  int? toAccountId;
  DateTime date = DateTime.now();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.transaction;
    if (item != null) {
      type = '${item['type'] ?? 'expense'}';
      amount.text = '${item['amount'] ?? ''}';
      note.text = '${item['note'] ?? ''}';
      category.text = '${item['category'] ?? ''}';
      accountId = item['accountId'] as int?;
      toAccountId = item['toAccountId'] as int?;
      date = DateTime.tryParse('${item['date']}') ?? DateTime.now();
    }
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final rows = await KhataDatabase.instance.getAccounts();
    if (!mounted) return;

    setState(() {
      accounts = rows.map(KhataAccount.fromMap).toList();

      final wallets = accounts.where((a) => a.isWallet).toList();
      if (wallets.isNotEmpty) {
        accountId ??= wallets.first.id;
        toAccountId ??= wallets.first.id;
      }
    });
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    category.dispose();
    super.dispose();
  }

  List<KhataAccount> get sourceOptions {
    if (type == 'payment') {
      return accounts.where((a) => a.isPayable).toList();
    }
    if (type == 'income') {
      return accounts.where((a) => a.isReceivable).toList();
    }
    return accounts.where((a) => a.isWallet).toList();
  }

  List<KhataAccount> get targetOptions =>
      accounts.where((a) => a.isWallet).toList();

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final value = double.tryParse(amount.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount 0 se zyada likhein.')),
      );
      return;
    }

    if (type == 'income' && accountId == null) {
      _message('Income ke liye Receivable account select karein.');
      return;
    }

    if (type == 'payment' && accountId == null) {
      _message('Payment ke liye Payable account select karein.');
      return;
    }

    if ((type == 'income' || type == 'payment') && toAccountId == null) {
      _message('Jis wallet mein paisay jayenge woh select karein.');
      return;
    }

    setState(() => saving = true);

    try {
      await KhataDatabase.instance.saveTransaction({
        if (widget.transaction?['id'] != null) 'id': widget.transaction!['id'],
        'type': type,
        'accountId': accountId,
        'toAccountId':
            type == 'income' || type == 'payment' ? toAccountId : null,
        'amount': value,
        'category': category.text.trim().isEmpty
            ? (type == 'expense' ? 'General Expense' : type)
            : category.text.trim(),
        'note': note.text.trim(),
        'date': date.toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _message('Entry save nahi hui: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsSource = type != 'expense';
    final needsTarget = type == 'income' || type == 'payment';

    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Entry type'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'payment', child: Text('Payable Payment')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              ],
              onChanged: (v) {
                setState(() {
                  type = v ?? 'expense';
                  accountId = sourceOptions
                      .isNotEmpty ? sourceOptions.first.id : null;
                  toAccountId = targetOptions
                      .isNotEmpty ? targetOptions.first.id : null;
                });
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (Rs)',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (v) {
                if (v == null || double.tryParse(v) == null) {
                  return 'Sahi amount likhein';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Food, Salary, School Fees',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks / Note',
              ),
            ),
            const SizedBox(height: 14),
            if (needsSource)
              DropdownButtonFormField<int>(
                value: sourceOptions.any((a) => a.id == accountId)
                    ? accountId
                    : null,
                decoration: InputDecoration(
                  labelText: type == 'income'
                      ? 'Receivable account'
                      : type == 'payment'
                          ? 'Payable account'
                          : 'From wallet',
                ),
                items: sourceOptions
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => accountId = v),
              ),
            if (type == 'expense')
              DropdownButtonFormField<int>(
                value: sourceOptions.any((a) => a.id == accountId)
                    ? accountId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Pay from Bank / Cash',
                ),
                items: targetOptions
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => accountId = v),
              ),
            if (type == 'transfer')
              DropdownButtonFormField<int>(
                value: targetOptions.any((a) => a.id == accountId)
                    ? accountId
                    : null,
                decoration: const InputDecoration(labelText: 'From wallet'),
                items: targetOptions
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => accountId = v),
              ),
            if (needsTarget || type == 'transfer') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: targetOptions.any((a) => a.id == toAccountId)
                    ? toAccountId
                    : null,
                decoration: InputDecoration(
                  labelText: type == 'transfer'
                      ? 'To wallet'
                      : 'Deposit to wallet',
                ),
                items: targetOptions
                    .where((a) => type != 'transfer' || a.id != accountId)
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => toAccountId = v),
              ),
            ],
            const SizedBox(height: 14),
            SurfaceCard(
              child: Row(
                children: [
                  const NeonIconBadge(
                    icon: Icons.calendar_month_rounded,
                    color: neonBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Date: ${shortDate(date)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(saving ? 'Saving...' : 'Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- REPORTS PLACEHOLDER ----------------

class ReportsPlaceholderPage extends StatelessWidget {
  const ReportsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SurfaceCard(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonIconBadge(
                icon: Icons.picture_as_pdf_rounded,
                color: red,
                size: 58,
              ),
              SizedBox(height: 14),
              Text(
                'Payable & Receivable Reports',
                style: TextStyle(
                  fontSize: 18,
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'PDF export aur WhatsApp sharing aglay report module mein add honge.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openAccountForm(
  BuildContext context, {
  KhataAccount? account,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AccountForm(account: account),
    ),
  );
}