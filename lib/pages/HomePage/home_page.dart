import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  String? _email;
  String? _password;

  @override
  void initState() {
    super.initState();

    // cekaj do nakon sto se builda page da loadas iz hivea
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredentialsFromHive();
    });
  }

  Future<void> _loadCredentialsFromHive() async {
    // 1) otvori ili kreiraj hive box
    final box = await Hive.openBox('user_credentials');

    // 2) pokusaj dohvatiti email i password iz hive boxa
    final storedEmail = box.get('email') as String?;
    final storedPassword = box.get('password') as String?;

    if (storedEmail != null && storedPassword != null) {
      // imamo ih lokalno, postavi ih u state
      setState(() {
        _email = storedEmail;
        _password = storedPassword;
      });

      // fetchaj ocjene iz API-a
      if (mounted) {
        context.read<HomePageViewModel>().fetchGrades(_email!, _password!);
      }
    } else {
      // nemamo ih lokalno, probaj dohvatiti iz Firebasea
      _fetchCredentialsFromFirebase();
    }
  }

  // funckija koja dohvaca ocjene i email / password od ucenika iz firebasea
  Future<void> _fetchCredentialsFromFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final screenId = prefs.getString('screenId');
    final viewModel = context.read<HomePageViewModel>();

    if (screenId == null) {
      debugPrint('No screen ID found');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(screenId)
          .get();

      if (doc.exists) {
        final fetchedEmail = doc.get('linkedUser') as String?;
        final fetchedPassword = doc.get('password') as String?;

        // ako postoje, updejtaj lokalni state
        if (fetchedEmail != null && fetchedPassword != null) {
          setState(() {
            _email = fetchedEmail;
            _password = fetchedPassword;
          });

          // spremi u hive za drugi put
          final box = await Hive.openBox('user_credentials');
          await box.put('email', fetchedEmail);
          await box.put('password', fetchedPassword);

          // sad fetchaj ocjene
          viewModel.fetchGrades(fetchedEmail, fetchedPassword);
        }
      }
    } catch (e) {
      debugPrint('Error fetching credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    if (viewModel.grades == null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCredentialsFromHive();
      });
    }

    return Scaffold(
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : viewModel.grades != null
              ? Center(
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // gornji lijevi container
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.02,
                      top: MediaQuery.of(context).size.height * 0.02,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/todo'),
                        child: _buildContainer(
                          label: "POPIS OBVEZA",
                          width: MediaQuery.of(context).size.width * 0.47,
                          height: MediaQuery.of(context).size.height * 0.463,
                        ),
                      ),
                    ),

                    // donji lijevi container
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.02,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/calendar'),
                        child: _buildContainer(
                          label: "KALENDAR",
                          width: MediaQuery.of(context).size.width * 0.47,
                          height: MediaQuery.of(context).size.height * 0.463,
                        ),
                      ),
                    ),

                    // gornji desni container
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.02,
                      top: MediaQuery.of(context).size.height * 0.02,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/pomodoro'),
                        child: _buildContainer(
                          label: "POMODORO \nMJERAČ VREMENA",
                          width: MediaQuery.of(context).size.width * 0.47,
                          height: MediaQuery.of(context).size.height * 0.463,
                        ),
                      ),
                    ),

                    // donji desni container
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.02,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/photomath'),
                        child: _buildContainer(
                          label: "ZNANSTVENE BILJEŠKE",
                          width: MediaQuery.of(context).size.width * 0.47,
                          height: MediaQuery.of(context).size.height * 0.463,
                        ),
                      ),
                    ),

                    // GradeWheel u sredini

                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/grades'),
                          child: Container(
                            width: MediaQuery.of(context).size.width *
                                0.25, // Adjust wheel size
                            height: MediaQuery.of(context).size.width * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor, // za skrivanje edge-va
                            ),
                            child: ClipOval(
                              child: GradeWheel(
                                  subjects: viewModel.grades?.subjects ?? []),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color.fromRGBO(113, 113, 113, 1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color.fromRGBO(113, 113, 113, 1),
            fontSize: 32, // font u containeru
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
