import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shedidthat/theme/app_colors.dart';

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bankDetails = '''
Beneficiary
Janet Braswell-Jeffus

Account
218735908884

ACH routing number
101019644

Wire routing number
101019644

Bank name and address
Lead Bank
1801 Main Street, Kansas City, MO, 64108, United States
''';

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Bank Transfer'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.userBubbleBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SelectableText(
                  bankDetails,
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: bankDetails));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bank details copied to clipboard!')),
                  );
                },
                child: const Text('Copy Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
