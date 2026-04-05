import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class AiInsightsSheet extends ConsumerWidget {
  const AiInsightsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiTipsAsync = ref.watch(aiSavingsTipsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 28),
                  const SizedBox(width: AppConstants.spacing12),
                  Text(
                    'AI Savings Advisor',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Personalized tips based on your last 30 days of spending.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: AppConstants.spacing24),
          aiTipsAsync.when(
            data: (tips) {
              if (tips.isEmpty) {
                return const Center(child: Text("We don't have enough data to generate tips yet."));
              }
              return Column(
                children: tips.map((tip) => _buildTipCard(tip, context)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryLight),
                    SizedBox(height: 16),
                    Text('Analyzing your expenses...'),
                  ],
                ),
              ),
            ),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Could not generate tips: ${err.toString().replaceAll("Exception: ", "")}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing32),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing16),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

void showAiInsightsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AiInsightsSheet(),
  );
}
