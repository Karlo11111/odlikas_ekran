import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_ekran/constants/app_colors.dart';
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';
import 'package:odlikas_ekran/pages/HomePage/widgets/grade_wheel.dart';
import 'package:odlikas_ekran/responsive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/viewmodel.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Responsive res = Responsive();
  String? _token;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTokenFromHive();
    });
  }

  Future<void> _loadTokenFromHive() async {
    final box = await Hive.openBox('user_credentials');
    final storedToken = box.get('token') as String?;
    if (storedToken != null) {
      setState(() => _token = storedToken);
      if (mounted) {
        _fetchGrades(storedToken);
      }
    } else {
      _fetchTokenFromFirebase();
    }
  }

  Future<void> _fetchTokenFromFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final screenId = prefs.getString('screenId');
    if (screenId == null || !mounted) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(screenId)
          .get();

      if (doc.exists) {
        final fetchedToken = doc.get('token') as String?;
        if (fetchedToken != null) {
          setState(() => _token = fetchedToken);
          final box = await Hive.openBox('user_credentials');
          await box.put('token', fetchedToken);
          final email = doc.data()?['linkedUser'] as String?;
          if (email != null) await box.put('email', email);
          if (mounted) _fetchGrades(fetchedToken);
        }
      }
    } catch (e) {
      debugPrint('Error fetching token: $e');
    }
  }

  Future<void> _fetchGrades(String token) async {
    setState(() => _error = null);
    try {
      await context.read<HomePageViewModel>().fetchGrades(token);
    } catch (e) {
      debugPrint('[Home] fetchGrades error: $e');
      if (e is ApiException && e.statusCode == 401) {
        await _handleExpiredSession();
      } else {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _handleExpiredSession() async {
    final box = await Hive.openBox('user_credentials');
    await box.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Session expired. Scan a new QR code from the Odlikas app.')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/setup', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Greška: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            _token != null ? _fetchGrades(_token!) : null,
                        child: const Text('Pokušaj ponovno'),
                      ),
                    ],
                  ),
                )
              : viewModel.grades != null
                  ? Center(
                      child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.02,
                          top: MediaQuery.of(context).size.height * 0.02,
                          child: InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/leaderboard'),
                            child: _buildContainer(
                              label: "LJESTVICA",
                              width: MediaQuery.of(context).size.width * 0.47,
                              height:
                                  MediaQuery.of(context).size.height * 0.463,
                            ),
                          ),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.02,
                          bottom: MediaQuery.of(context).size.height * 0.02,
                          child: InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/calendar'),
                            child: _buildContainer(
                              label: "KALENDAR",
                              width: MediaQuery.of(context).size.width * 0.47,
                              height:
                                  MediaQuery.of(context).size.height * 0.463,
                            ),
                          ),
                        ),
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.02,
                          top: MediaQuery.of(context).size.height * 0.02,
                          child: InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/pomodoro'),
                            child: _buildContainer(
                              label: "POMODORO \nMJERAČ VREMENA",
                              width: MediaQuery.of(context).size.width * 0.47,
                              height:
                                  MediaQuery.of(context).size.height * 0.463,
                            ),
                          ),
                        ),
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.02,
                          bottom: MediaQuery.of(context).size.height * 0.02,
                          child: InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/photomath'),
                            child: _buildContainer(
                              label: "BILJEŠKE",
                              width: MediaQuery.of(context).size.width * 0.47,
                              height:
                                  MediaQuery.of(context).size.height * 0.463,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/grades'),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.width * 0.25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                                child: ClipOval(
                                  child: GradeWheel(
                                      subjects:
                                          viewModel.grades?.subjects ?? []),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))
                  : const Center(),
    );
  }

  Widget _buildContainer({
    required String label,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color.fromRGBO(113, 113, 113, 1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.secondary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
