import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

final aiSavingsTipsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final transactionsAsync = ref.watch(transactionsProvider);
  final categoryMapMap = ref.watch(categoryMapProvider);
  
  if (transactionsAsync.value == null) {
    return [];
  }

  final transactions = transactionsAsync.value!;
  
  // Get last 30 days of transactions
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final recentTransactions = transactions.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();
  
  // Aggregate expenses
  Map<String, double> categoryTotals = {};
  double totalIncome = 0;
  double totalExpense = 0;

  for (var t in recentTransactions) {
    if (t.type == 'expense') {
      final categoryName = categoryMapMap[t.categoryId]?.name ?? 'Other';
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + t.amount;
      totalExpense += t.amount;
    } else {
      totalIncome += t.amount;
    }
  }

  // If there are no expenses, return a default positive message
  if (totalExpense == 0) {
    return ["You haven't had any expenses in the last 30 days! Keep up the great work!"];
  }

  final aiService = ref.watch(aiServiceProvider);
  return await aiService.getSavingsTips(categoryTotals, totalIncome - totalExpense);
});
