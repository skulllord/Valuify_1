import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets - ${Helpers.formatMonth(currentMonth)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(currentMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month - 1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(currentMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month + 1);
            },
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          return categoriesAsync.when(
            data: (categories) {
              final expenseCategories = categories.where((c) => c.type == 'expense').toList();

              if (expenseCategories.isEmpty) {
                return const Center(child: Text('No categories available'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                itemCount: expenseCategories.length,
                itemBuilder: (context, index) {
                  final category = expenseCategories[index];
                  final budget = budgets.where((b) => b.categoryId == category.id).firstOrNull;
                  final progress = ref.watch(budgetProgressProvider(category.id));

                  return _BudgetCard(
                    category: category,
                    budget: budget,
                    progress: progress,
                    currencySymbol: currencySymbol,
                    onTap: () {
                      _showSetBudgetDialog(context, ref, category, budget, currencySymbol);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading categories')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    category,
    BudgetModel? existingBudget,
    String currencySymbol,
  ) {
    final controller = TextEditingController(
      text: existingBudget?.amount.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '$currencySymbol ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              final currentMonth = ref.read(currentMonthProvider);
              
              if (user != null && controller.text.isNotEmpty) {
                final budget = BudgetModel(
                  id: existingBudget?.id ?? '',
                  userId: user.uid,
                  categoryId: category.id,
                  amount: double.parse(controller.text),
                  month: currentMonth.month,
                  year: currentMonth.year,
                  createdAt: existingBudget?.createdAt ?? DateTime.now(),
                );
                
                await FirestoreService().setBudget(user.uid, budget);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final category;
  final BudgetModel? budget;
  final double progress;
  final String currencySymbol;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.category,
    required this.budget,
    required this.progress,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasExceeded = progress > 1.0;
    final isNearLimit = progress > 0.8 && progress <= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: hasExceeded
                ? Colors.red
                : isNearLimit
                    ? Colors.orange
                    : isDark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Center(
                    child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (budget != null)
                        Text(
                          'Budget: ${Helpers.formatCurrency(budget!.amount, currencySymbol)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (budget != null)
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasExceeded
                          ? Colors.red
                          : isNearLimit
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
              ],
            ),
            if (budget != null) ...[
              const SizedBox(height: AppConstants.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                child: LinearProgressIndicator(
                  value: progress > 1.0 ? 1.0 : progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    hasExceeded
                        ? Colors.red
                        : isNearLimit
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to set budget',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
