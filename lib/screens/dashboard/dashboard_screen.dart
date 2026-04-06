import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/chart_widgets.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../widgets/ai_insights_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final _now = DateTime.now();
    final currentMonth = DateTime(_now.year, _now.month);
    final stats = ref.watch(monthlyStatsProvider(currentMonth));

    return Scaffold(
      body: SafeArea(
        child: transactionsAsync.when(
          data: (transactions) {
            final recentTransactions = transactions.take(5).toList();
            final balance = stats['net'] ?? 0.0;

            // Calculate 3-month trend
            final months = List.generate(3, (i) {
              final month = DateTime(currentMonth.year, currentMonth.month - (2 - i));
              return month;
            });

            final trendData = months.map((month) {
              final monthStats = ref.watch(monthlyStatsProvider(month));
              return monthStats['net'] ?? 0.0;
            }).toList();

            final trendLabels = months.map((m) => Helpers.getMonthYear(m)).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Helpers.getGreeting(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          user?.displayName ?? user?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        BalanceCard(
                          balance: balance,
                          currencySymbol: currencySymbol,
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Income',
                                amount: stats['income'] ?? 0.0,
                                currencySymbol: currencySymbol,
                                isIncome: true,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacing12),
                            Expanded(
                              child: _StatCard(
                                title: 'Expense',
                                amount: stats['expense'] ?? 0.0,
                                currencySymbol: currencySymbol,
                                isIncome: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        const Text(
                          '3-Month Trend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing12),
                        TrendLineChart(
                          data: trendData,
                          labels: trendLabels,
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        // AI Advisor Button
                        InkWell(
                          onTap: () => showAiInsightsSheet(context),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE94057).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Get AI Savings Insights',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        const Text(
                          'Budget Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing12),
                        budgetsAsync.when(
                          data: (budgets) {
                            if (budgets.isEmpty) {
                              return const Text('No budgets set yet. Tap on the Budgets tab to set one!');
                            }
                            return categoriesAsync.when(
                              data: (categories) {
                                return Column(
                                  children: budgets.map((budget) {
                                    final category = categories.firstWhere(
                                      (c) => c.id == budget.categoryId,
                                      orElse: () => categories.first,
                                    );
                                    final progress = ref.watch(budgetProgressProvider(category.id));
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    final hasExceeded = progress > 1.0;
                                    final isNearLimit = progress > 0.8 && progress <= 1.0;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
                                      padding: const EdgeInsets.all(AppConstants.spacing12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[900] : Colors.white,
                                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                        border: Border.all(
                                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(category.icon, style: const TextStyle(fontSize: 18)),
                                                  const SizedBox(width: 8),
                                                  Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                              Text(
                                                '${(progress * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: hasExceeded ? Colors.red : (isNearLimit ? Colors.orange : Colors.green),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress > 1.0 ? 1.0 : progress,
                                              minHeight: 6,
                                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation(
                                                hasExceeded ? Colors.red : (isNearLimit ? Colors.orange : Colors.green),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Budget: ${Helpers.formatCurrency(budget.amount, currencySymbol)}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Text('Error loading categories'),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('Error loading budgets'),
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                                );
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                categoriesAsync.when(
                  data: (categories) {
                    final categoryMap = {for (var c in categories) c.id: c};
                    
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = recentTransactions[index];
                            return TransactionItem(
                              transaction: transaction,
                              category: categoryMap[transaction.categoryId],
                              currencySymbol: currencySymbol,
                            );
                          },
                          childCount: recentTransactions.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: Center(child: Text('Error loading categories')),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currencySymbol;
  final bool isIncome;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.currencySymbol,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(amount, currencySymbol),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
