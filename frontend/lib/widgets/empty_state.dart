import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onButtonPressed;

  const EmptyState({super.key, required this.onButtonPressed});

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
            onPressed: onButtonPressed,
            child: const Text('Start Debriefing'),
          ),
        ],
      ),
    );
  }
}
