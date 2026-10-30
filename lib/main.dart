import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/auth/lock_screen.dart';
import 'package:offline_vault/features/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: OfflineVaultApp(),
    ),
  );
}

class OfflineVaultApp extends ConsumerWidget {
  const OfflineVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionKey = ref.watch(sessionKeyProvider);

    return MaterialApp(
      title: 'Offline Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: sessionKey == null ? const LockScreen() : const DashboardScreen(),
    );
  }
}
