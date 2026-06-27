import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_state.dart';
import 'core/providers/cart_state.dart';
import 'core/providers/connectivity_provider.dart';
import 'components/atoms/connectivity_banner.dart';
import 'pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Villa Eventos Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashPage(),
      builder: (context, child) {
        return Stack(
          children: [
            // ignore: use_null_aware_elements
            if (child != null) child,
            const ConnectivityBanner(),
          ],
        );
      },
    );
  }
}
