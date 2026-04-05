import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/transaction_item.dart';
import '../../utils/constants.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _filterType;
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _filterType = null;
                } else {
                  _filterType = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'income', child: Text('Income')),
              const PopupMenuItem(value: 'expense', child: Text('Expense')),
            ],
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          var filtered = transactions;
          if (_filterType != null) {
            filtered = filtered.where((t) => t.type == _filterType).toList();
          }
          if (_filterCategoryId != null) {
            filtered = filtered.where((t) => t.categoryId == _filterCategoryId).toList();
          }

          if (filtered.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }

          return categoriesAsync.when(
            data: (categories) {
              final categoryMap = {for (var c in categories) c.id: c};

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final transaction = filtered[index];
                  return TransactionItem(
                    transaction: transaction,
                    category: categoryMap[transaction.categoryId],
                    currencySymbol: currencySymbol,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(transaction: transaction),
                        ),
                      );
                    },
                    onDelete: () async {
                      if (user != null) {
                        await FirestoreService().deleteTransaction(user.uid, transaction.id);
                      }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
