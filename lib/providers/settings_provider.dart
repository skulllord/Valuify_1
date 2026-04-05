import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

final userSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value({'currency': 'INR', 'currencySymbol': '₹'});
  }

  return ref.watch(firestoreServiceProvider).getSettings(user.uid);
});

final currencySymbolProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider).value;
  return settings?['currencySymbol'] ?? '₹';
});
