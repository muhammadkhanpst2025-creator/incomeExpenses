
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'database.dart';
import 'models.dart';
import 'widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _type = 'payable';
  int? _selectedAccountId;
  List<KhataAccount> _accounts = [];
  List<KhataTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    try {
      final accounts = await KhataDatabase.instance.getAccounts(
        type: _type,
      );

      int? accountId = _selectedAccountId;
      if (!accounts.any((a) => a.id == accountId)) {
        accountId = accounts.isNotEmpty ? accounts.first.id : null;
      }

      final transactions = accountId == null
          ? <KhataTransaction>[]
          : await KhataDatabase.instance.getTransactions(
              accountId: accountId,
            );

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _selectedAccountId = accountId;
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report load nahi hui: $e')),
      );
    }
  }

  KhataAccount? get _selectedAccount {
    for (final account in _accounts) {
      if (account.id == _selectedAccountId) return account;
    }
    return null;
  }

  String get _reportTitle =>
      _type == 'payable' ? 'Payable Report' : 'Receivable Report';

  String _dateText(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : DateFormat('dd-MM-yyyy').format(parsed);
  }

  Future<List<int>> _createPdf() async {
    final account = _selectedAccount;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Income & Expenses',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(_reportTitle),
          pw.SizedBox(height: 12),
          pw.Text('Account: ${account?.name ?? "No account"}'),
          pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Category / Note', 'Amount'],
            data: _transactions.map((t) {
              return [
                _dateText(t.date),
                t.type,
                (t.note ?? '').isEmpty ? (t.category ?? '-') : t.note!,
                t.amount.toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Current account balance: ${account?.balance.toStringAsFixed(2) ?? "0.00"}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _sharePdf() async {
    if (_selectedAccount == null) {
      _showMessage('Pehle account select karein.');
      return;
    }

    try {
      final bytes = await _createPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            '${_reportTitle.replaceAll(' ', '_')}_${_selectedAccount!.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      _showMessage('PDF share nahi hui: $e');
    }
  }

  Future<void> _shareWhatsAppMessage() async {
    final account = _selectedAccount;
    if (account == null) {
      _showMessage('Pehle account select karein.');
      return;
    }

    final phone = (account.phone ?? '').replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (phone.isEmpty) {
      _showMessage(
        'Is account ka phone number save nahi hai. '
        'Account edit karke phone number add karein.',
      );
      return;
    }

    String normalizedPhone = phone.replaceAll('+', '');
    if (normalizedPhone.startsWith('00')) {
      normalizedPhone = normalizedPhone.substring(2);
    } else if (normalizedPhone.startsWith('0')) {
      normalizedPhone = '92${normalizedPhone.substring(1)}';
    }

    final message = '''
$_reportTitle

Account: ${account.name}
Current Balance: ${account.balance.toStringAsFixed(2)}
Transactions: ${_transactions.length}

Report prepared by Income & Expenses app.
''';

    final uri = Uri.https(
      'wa.me',
      '/$normalizedPhone',
      {'text': message},
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        _showMessage('WhatsApp open nahi ho saka.');
      }
    } catch (_) {
      _showMessage('WhatsApp open nahi ho saka.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = _selectedAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'payable',
                  label: Text('Payable'),
                  icon: Icon(Icons.call_made),
                ),
                ButtonSegment(
                  value: 'receivable',
                  label: Text('Receivable'),
                  icon: Icon(Icons.call_received),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _selectedAccountId = null;
                });
                _loadReport();
              },
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_accounts.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Select account',
                    border: OutlineInputBorder(),
                  ),
                  items: _accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAccountId = value);
                    _loadReport();
                  },
                )
              else
                const Text(
                  'Is category mein abhi koi account nahi hai.',
                ),
              const SizedBox(height: 16),
              if (account != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(account.name),
                    subtitle: Text(_reportTitle),
                    trailing: Text(
                      account.balance.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: account.balance < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: account == null ? null : _sharePdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Share PDF'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          account == null ? null : _shareWhatsAppMessage,
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Transactions (${_transactions.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_transactions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Is account ki koi transaction nahi mili.'),
                  ),
                )
              else
                ..._transactions.map(
                  (t) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        (t.note ?? '').isEmpty
                            ? (t.category ?? t.type)
                            : t.note!,
                      ),
                      subtitle: Text(
                        '${t.type} • ${_dateText(t.date)}',
                      ),
                      trailing: Text(
                        t.amount.toStringAsFixed(2),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
