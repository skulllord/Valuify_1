import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isGenerating = false;

  Future<void> _exportCSV() async {
    setState(() => _isGenerating = true);

    try {
      final transactions = ref.read(transactionsProvider).value ?? [];
      final categories = ref.read(categoriesProvider).value ?? [];
      final categoryMap = {for (var c in categories) c.id: c};

      final monthTransactions = transactions.where((t) {
        return t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month;
      }).toList();

      List<List<dynamic>> rows = [
        ['Date', 'Type', 'Category', 'Merchant', 'Amount', 'Notes'],
      ];

      for (var t in monthTransactions) {
        final category = categoryMap[t.categoryId];
        rows.add([
          Helpers.formatDate(t.date),
          t.type,
          category?.name ?? 'Unknown',
          t.merchant ?? '',
          t.amount,
          t.notes ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final fileName = 'transactions_${_selectedMonth.year}_${_selectedMonth.month}.csv';

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV download started!')),
          );
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csv);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV exported to ${file.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isGenerating = true);

    try {
      final transactions = ref.read(transactionsProvider).value ?? [];
      final categories = ref.read(categoriesProvider).value ?? [];
      final categoryMap = {for (var c in categories) c.id: c};

      final monthTransactions = transactions.where((t) {
        return t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month;
      }).toList();

      final currencySymbol = ref.read(currencySymbolProvider);

      final Uint8List pdfBytes = await PdfService().generateMonthlyReport(
        _selectedMonth,
        monthTransactions,
        categoryMap,
        currencySymbol,
      );
      final fileName = 'report_${_selectedMonth.year}_${_selectedMonth.month}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF download started!')),
          );
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF exported to ${file.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(monthlyStatsProvider(_selectedMonth));
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Select Month',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        Helpers.formatMonth(_selectedMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  _SummaryRow(
                    label: 'Total Income',
                    amount: stats['income'] ?? 0.0,
                    currencySymbol: currencySymbol,
                    color: Colors.green,
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  _SummaryRow(
                    label: 'Total Expense',
                    amount: stats['expense'] ?? 0.0,
                    currencySymbol: currencySymbol,
                    color: Colors.red,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Net',
                    amount: stats['net'] ?? 0.0,
                    currencySymbol: currencySymbol,
                    color: (stats['net'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _exportCSV,
              icon: const Icon(Icons.table_chart),
              label: const Text('Export as CSV'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export as PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
            ),
            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.all(AppConstants.spacing16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currencySymbol;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.currencySymbol,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Helpers.formatCurrency(amount, currencySymbol),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
