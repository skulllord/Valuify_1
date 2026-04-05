import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/helpers.dart';

class PdfService {
  Future<Uint8List> generateMonthlyReport(
    DateTime month,
    List<TransactionModel> transactions,
    Map<String, CategoryModel> categories,
    String currencySymbol,
  ) async {
    final pdf = pw.Document();

    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final net = income - expense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Monthly Financial Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            Helpers.formatMonth(month),
            style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Income:'),
                    pw.Text(
                      Helpers.formatCurrency(income, currencySymbol),
                      style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Expense:'),
                    pw.Text(
                      Helpers.formatCurrency(expense, currencySymbol),
                      style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Net:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      Helpers.formatCurrency(net, currencySymbol),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: net >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Transactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Merchant', 'Amount'],
            data: transactions.map((t) {
              final category = categories[t.categoryId];
              return [
                Helpers.formatDateShort(t.date),
                category?.name ?? 'Unknown',
                t.merchant ?? '-',
                Helpers.formatCurrency(
                  t.type == 'expense' ? -t.amount : t.amount,
                  currencySymbol,
                ),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    return await pdf.save();
  }
}
