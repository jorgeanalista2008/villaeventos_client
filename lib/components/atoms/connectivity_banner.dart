import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/theme/app_theme.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final isConnected = connectivity.isConnected;
    final showRestored = connectivity.showRestoredBanner;

    final showBanner = !isConnected || showRestored;

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double targetTop = showBanner ? (statusBarHeight + 12.0) : -80.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      top: targetTop,
      left: 16.0,
      right: 16.0,
      child: IgnorePointer(
        ignoring: !showBanner,
        child: Material(
          type: MaterialType.transparency,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isConnected ? AppTheme.successGreen : AppTheme.alertRed,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected
                      ? "Conexión restablecida"
                      : "Sin conexión a Internet",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isConnected) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
