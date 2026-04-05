import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;

  void _initModel() {
    if (_model != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception('Gemini API key not found in .env file');
    }
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<List<String>> getSavingsTips(Map<String, double> categoryTotals, double netIncome) async {
    // We are using a robust offline rule-based engine instead of the API to ensure tips are always available.
    await Future.delayed(const Duration(seconds: 1)); // Simulate processing time
    
    List<String> tips = [];
    
    // 1. Analyze general cash flow
    if (netIncome < 0) {
      tips.add("You're currently spending more than your total income. Try to review your non-essential expenses this week.");
    } else if (netIncome > 0) {
      tips.add("Great job keeping a positive balance! Consider investing or saving the remaining \$${netIncome.toStringAsFixed(0)}.");
    }

    // 2. Find the highest spending category
    if (categoryTotals.isNotEmpty) {
      var topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topCategory.value > 0) {
        tips.add("Your highest expense is ${topCategory.key} (\$${topCategory.value.toStringAsFixed(0)}). Setting a strict budget for this category could yield the biggest savings.");
      }
    }

    // 3. Specific actionable category tips
    if (categoryTotals.containsKey('Food') || categoryTotals.containsKey('Dining')) {
       tips.add("Meal prepping at home can significantly cut down your Food & Dining expenses.");
    } else if (categoryTotals.containsKey('Shopping') || categoryTotals.containsKey('Entertainment')) {
       tips.add("Try using the '24-hour rule' for non-essential shopping to avoid impulse purchases.");
    }

    // 4. General fallback tip
    if (tips.length < 3) {
      tips.add("Track every small expense; small daily purchases can add up to a significant amount by the end of the month.");
    }
    
    if (tips.length < 3) {
      tips.add("Review your recurring subscriptions and cancel any services you haven't used in the past month.");
    }

    // Return the top 3-4 tips
    return tips.take(4).toList();
  }
}
