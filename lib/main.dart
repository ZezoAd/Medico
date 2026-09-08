import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  await ThemeController.init();

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } else {
    debugPrint(
      'Supabase environment variables are missing; continuing without init.',
    );
  }

  await GoogleSignIn.instance.initialize(
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  await Firebase.initializeApp();

  runApp(const MedicoApp());
}

class MedicoApp extends StatelessWidget {
  const MedicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds only this [MaterialApp] when the preference changes, which is
    // the whole app but nothing above it — the theme swap is instant and needs
    // no per-screen participation.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        scrollBehavior: _NoStretchScrollBehavior(),
        debugShowCheckedModeBanner: false,
        title: 'Medico',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
