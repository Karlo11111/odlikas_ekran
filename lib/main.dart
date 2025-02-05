import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odlikas_ekran/pages/Calendar/calendar_page.dart';
import 'package:odlikas_ekran/pages/Grades/grades_page.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_galery.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/pomodoro_timer_page.dart';
import 'package:odlikas_ekran/viewmodels/test_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database/firebase_options.dart';
import 'database/api/api_service.dart';
import 'viewmodels/viewmodel.dart';
import 'pages/HomePage/home_page.dart';
import 'pages/SetupPage/setup_page.dart';
import 'pages/QRCodePage/qr_code_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapter(WhiteboardDataAdapter());
  await Hive.openBox<WhiteboardData>('whiteboards');

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
          update: (_, apiService, previous) => HomePageViewModel(apiService),
        ),

        ChangeNotifierProxyProvider<ApiService, TestViewmodel>(
          create: (context) => TestViewmodel(context.read<ApiService>()),
          update: (_, apiService, previous) => TestViewmodel(apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => _decideFirstScreen(context),
          '/setup': (context) => const SetupScreen(),
          '/qr': (context) => QRCodePage(screenId: screenId),
          '/home': (context) => HomePage(),
          '/grades': (context) => const GradesPage(),
          '/calendar': (context) => const CalendarPage(),
          '/pomodoro': (context) => const PomodoroTimerPage(),
          '/photomath': (context) => const WhiteboardGalleryPage(),
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
