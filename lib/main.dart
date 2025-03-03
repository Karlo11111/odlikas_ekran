import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odlikas_ekran/pages/Calendar/calendar_page.dart';
import 'package:odlikas_ekran/pages/Grades/grades_page.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_galery.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/pomodoro_timer_page.dart';
import 'package:odlikas_ekran/pages/ToDoList/todo_list.dart';
import 'package:odlikas_ekran/viewmodels/test_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/firebase_options.dart';
import 'database/api/api_service.dart';
import 'viewmodels/viewmodel.dart';
import 'pages/HomePage/home_page.dart';
import 'pages/SetupPage/setup_page.dart';
import 'pages/QRCodePage/qr_code_page.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  // inicijalizacija firebasea
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // inicijalizacija hive-a (local storage)
  await Hive.initFlutter();
  Hive.registerAdapter(WhiteboardDataAdapter());
  await Hive.openBox<WhiteboardData>('whiteboards');

  // varijabla za znanstevene biljeske
  final whiteboardsBox = Hive.box<WhiteboardData>('whiteboards');
  whiteboardsBox.values.forEach((wb) {
    whiteboardsBox.get(wb.key);
  });

  // vodoravna orijentacija na mobitelu
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // full-screen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // provjeri shared preferences 
  final prefs = await SharedPreferences.getInstance();
  final setupDone = prefs.getBool('setupDone') ?? false;
  final String screenId = prefs.getString('screenId') ?? '';
  final connectedOnce = prefs.getBool('connectedOnce') ?? false;

  await dotenv.load(fileName: ".env");

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
        // api service provider
        Provider<ApiService>(
          create: (_) => ApiService(
              "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com"),
        ),
        // konekcija homepage viewmodela s api sericom
        ChangeNotifierProxyProvider<ApiService, HomePageViewModel>(
          create: (context) => HomePageViewModel(context.read<ApiService>()),
          update: (_, apiService, previous) => HomePageViewModel(apiService),
        ),

        // konekcija test viewmodela s api sericom
        ChangeNotifierProxyProvider<ApiService, TestViewmodel>(
          create: (context) => TestViewmodel(context.read<ApiService>()),
          update: (_, apiService, previous) => TestViewmodel(apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // rute za sve pageove
        routes: {
          '/': (context) => _decideFirstScreen(context),
          '/setup': (context) => const SetupScreen(),
          '/qr': (context) => QRCodePage(screenId: screenId),
          '/home': (context) => HomePage(),
          '/grades': (context) => const GradesPage(),
          '/calendar': (context) => const CalendarPage(),
          '/pomodoro': (context) => const PomodoroTimerPage(),
          '/photomath': (context) => const WhiteboardGalleryPage(),
          '/todo': (context) => const TodoList(),
        },
      ),
    );
  }

  // funkcija koja odabire prvi page koji ti se prikaze (ako si vec spojen onda odma homepage, ako si prosao prvi page onda odmna qr kod page)
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
