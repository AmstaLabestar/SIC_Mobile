import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/widgets/sic_amount_display.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);

  runApp(const ProviderScope(child: SicMobileApp()));
}

class SicMobileApp extends StatelessWidget {
  const SicMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIC Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _ArchitecturePreviewScreen(),
    );
  }
}

class _ArchitecturePreviewScreen extends StatelessWidget {
  const _ArchitecturePreviewScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('SIC Mobile', style: textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Systeme Inter-Connexion pour agents Mobile Money',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              const Center(
                child: SicAmountDisplay(
                  amount: 485000,
                  size: SicAmountSize.large,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Fondation Clean Architecture prete.',
                  style: textTheme.bodyMedium,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
