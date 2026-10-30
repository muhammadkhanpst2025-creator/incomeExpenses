import 'dart:typed_data';

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
  List<KhataAccount> accounts = [];
  int? accountId;
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();
  Map<String, dynamic>? statement;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final rows = await KhataDatabase.instance.getAccounts(activeOnly: false);
      final list = rows.map(KhataAccount.fromMap).toList();
      final selected = list.any((a) => a.id == accountId) ? accountId : (list.isEmpty ? null : list.first.id);
      Map<String, dynamic>? result;
      if (selected != null) result = await KhataDatabase.instance.getAccountStatement(selected, from, to);
      if (!mounted) return;
      setState(() { accounts = list; accountId = selected; statement = result; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Statement load nahi hui: $e');
    }
  }

  void _message(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
  String _date(DateTime d) => DateFormat('dd-MM-yyyy').format(d);
  String _dateValue(String raw) { final d = DateTime.tryParse(raw); return d == null ? raw : _date(d); }
  double _n(dynamic v) => (v as num? ?? 0).toDouble();

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(context: context, initialDate: isFrom ? from : to, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked == null) return;
    setState(() { if (isFrom) { from = picked; if (to.isBefore(from)) to = from; } else { to = picked; if (to.isBefore(from)) from = to; } });
    await _load();
  }

  Future<Uint8List> _pdfBytes() async {
    final data = statement!;
    final account = KhataAccount.fromMap(Map<String, dynamic>.from(data['account'] as Map));
    final rows = (data['transactions'] as List).cast<Map<String, dynamic>>();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(build: (_) => [
      pw.Text('INCOME & EXPENSES', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.Text('Account Statement', style: pw.TextStyle(fontSize: 15)),
      pw.SizedBox(height: 8),
      pw.Text('Account: ${account.name}   Category: ${account.category}'),
      pw.Text('Period: ${_date(from)} to ${_date(to)}'),
      pw.SizedBox(height: 12),
      pw.Text('Opening Balance: Rs ${_n(data['opening']).toStringAsFixed(2)}'),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Category', 'Remarks', 'CR (Rs)', 'DR (Rs)', 'Balance (Rs)'],
        data: rows.map((r) => [
          _dateValue('${r['date']}'), '${r['category'] ?? '-'}', '${r['note'] ?? '-'}',
          _n(r['cr']).toStringAsFixed(2), _n(r['dr']).toStringAsFixed(2), _n(r['runningBalance']).toStringAsFixed(2),
        ]).toList(),
      ),
      pw.SizedBox(height: 12),
      pw.Text('Closing Balance: Rs ${_n(data['closing']).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 18),
      pw.Text('Developed by SAHIL JANWERY', style: const pw.TextStyle(fontSize: 9)),
    ]));
    return doc.save();
  }

  Future<void> _sharePdf() async {
    if (statement == null) return;
    try { await Printing.sharePdf(bytes: await _pdfBytes(), filename: 'Account_Statement_${accountId}_${_date(from)}_${_date(to)}.pdf'); }
    catch (e) { _message('PDF share nahi hui: $e'); }
  }

  Future<void> _shareWhatsApp() async {
    if (statement == null) return;
    final a = KhataAccount.fromMap(Map<String, dynamic>.from(statement!['account'] as Map));
    final text = 'Account Statement\nAccount: ${a.name}\nPeriod: ${_date(from)} to ${_date(to)}\nOpening: Rs ${_n(statement!['opening']).toStringAsFixed(2)}\nClosing: Rs ${_n(statement!['closing']).toStringAsFixed(2)}';
    final uri = Uri.https('wa.me', '/', {'text': text});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) _message('WhatsApp open nahi ho saka.');
  }

  @override
  Widget build(BuildContext context) {
    final selected = accounts.where((a) => a.id == accountId).firstOrNull;
    final rows = (statement?['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Account Statement'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int>(initialValue: accountId, decoration: const InputDecoration(labelText: 'Select account'), items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.category})'))).toList(), onChanged: (v) async { accountId = v; await _load(); }),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _pickDate(true), icon: const Icon(Icons.calendar_month), label: Text('From: ${_date(from)}'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _pickDate(false), icon: const Icon(Icons.calendar_month), label: Text('To: ${_date(to)}')))]),
        const SizedBox(height: 12),
        if (selected != null && statement != null) SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(selected.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('Category: ${selected.category}'), const SizedBox(height: 12), Text('Opening Balance: ${money(_n(statement!['opening']))}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('Closing Balance: ${money(_n(statement!['closing']))}', style: const TextStyle(fontWeight: FontWeight.w900, color: purple))])),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: FilledButton.icon(onPressed: statement == null ? null : _sharePdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: statement == null ? null : _shareWhatsApp, icon: const Icon(Icons.share), label: const Text('WhatsApp')))]),
        const SizedBox(height: 16),
        const Text('Statement Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (rows.isEmpty) const SurfaceCard(child: Text('Is date range mein koi transaction nahi hai.')) else ...rows.map((r) => SurfaceCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_dateValue('${r['date']}'), style: const TextStyle(fontWeight: FontWeight.w800)), Text('Balance: ${money(_n(r['runningBalance']))}', style: const TextStyle(fontWeight: FontWeight.w800))]), Text('Category: ${r['category'] ?? '-'}'), Text('Remarks: ${r['note'] ?? '-'}'), Row(children: [Expanded(child: Text('CR: ${money(_n(r['cr']))}', style: const TextStyle(color: green))), Expanded(child: Text('DR: ${money(_n(r['dr']))}', style: const TextStyle(color: red)))] )])))),
      ]),
    );
  }
}
