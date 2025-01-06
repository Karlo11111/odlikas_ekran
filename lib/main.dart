import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odlikas_ekran/pages/Grades/grades_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/firebase_options.dart';
import 'database/api/api_service.dart';
import 'viewmodels/home_page_viewmodel.dart';
import 'pages/HomePage/home_page.dart';
import 'pages/SetupPage/setup_page.dart';
import 'pages/QRCodePage/qr_code_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lock orientation to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable full-screen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Check SharedPreferences for setup state
  final prefs = await SharedPreferences.getInstance();
  final setupDone = prefs.getBool('setupDone') ?? false;
  final String screenId = prefs.getString('screenId') ?? '';
  final connectedOnce = prefs.getBool('connectedOnce') ?? false;

  runApp(MyApp(
    setupDone: setupDone,
    screenId: screenId,
    connectedOnce: connectedOnce,
  ));
}

class MyApp extends StatelessWidget {
  final bool setupDone;
  final String screenId;
  final bool connectedOnce;

  const MyApp({
    super.key,
    required this.setupDone,
    required this.screenId,
    required this.connectedOnce,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide ApiService instance
        Provider<ApiService>(
          create: (_) => ApiService(
              "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com"),
        ),
        // Provide HomePageViewModel and connect it to ApiService
        ChangeNotifierProxyProvider<ApiService, HomePageViewModel>(
          create: (context) => HomePageViewModel(context.read<ApiService>()),
          update: (_, apiService, previous) =>
              previous ?? HomePageViewModel(apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => _decideFirstScreen(context),
          '/setup': (context) => const SetupScreen(),
          '/qr': (context) => QRCodePage(screenId: screenId),
          '/home': (context) => HomePage(),
          '/grades': (context) => GradesPage(),
        },
      ),
    );
  }

  Widget _decideFirstScreen(BuildContext context) {
    if (!setupDone) {
      return const SetupScreen();
    }

    if (!connectedOnce) {
      return QRCodePage(screenId: screenId);
    }

    return HomePage();
  }
}
