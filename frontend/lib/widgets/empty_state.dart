import 'package:flutter/material.dart';
import 'package:shedidthat/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onButtonPressed;
  final bool isLoading;

  const EmptyState({
    super.key,
    required this.onButtonPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No debriefs yet.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'What are you waiting for?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLoading ? AppColors.buttonSecondary : AppColors.accent,
            ),
            child: const Text('Start Debriefing'),
          ),
        ],
      ),
    );
  }
}
