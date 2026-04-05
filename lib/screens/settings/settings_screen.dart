import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  String _selectedCurrency = 'INR';
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final settingsStream = FirestoreService().getSettings(user.uid);
      settingsStream.listen((settings) {
        if (mounted) {
          setState(() {
            _biometricEnabled = settings['biometricEnabled'] ?? false;
            _selectedCurrency = settings['currency'] ?? 'INR';
            _currencySymbol = settings['currencySymbol'] ?? '₹';
          });
        }
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await FirestoreService().updateSettings(user.uid, {key: value});
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometric authentication not available')),
          );
        }
        return;
      }

      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (authenticated) {
          setState(() => _biometricEnabled = true);
          await _updateSetting('biometricEnabled', true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } else {
      setState(() => _biometricEnabled = false);
      await _updateSetting('biometricEnabled', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
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
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (user?.displayName?.substring(0, 1) ??
                            user?.email?.substring(0, 1) ??
                            'U')
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppConstants.spacing12),
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacing12),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeProvider.notifier).setTheme(mode);
                }
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.attach_money,
            title: 'Currency',
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              underline: const SizedBox(),
              items: AppConstants.currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency['code'],
                  child: Text('${currency['symbol']} ${currency['code']}'),
                );
              }).toList(),
              onChanged: (code) async {
                if (code != null) {
                  final currency = AppConstants.currencies.firstWhere(
                    (c) => c['code'] == code,
                  );
                  setState(() {
                    _selectedCurrency = code;
                    _currencySymbol = currency['symbol']!;
                  });
                  await _updateSetting('currency', code);
                  await _updateSetting('currencySymbol', currency['symbol']);
                }
              },
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          const Text(
            'Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacing12),
          _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          const Text(
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacing12),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                try {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Sign out
                  await AuthService().signOut();

                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  // Force refresh by invalidating auth state
                  ref.invalidate(authStateProvider);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
