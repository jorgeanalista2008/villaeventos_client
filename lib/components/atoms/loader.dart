import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class Loader extends StatelessWidget {
  final String? message;

  const Loader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontFamily: 'Inter',
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
