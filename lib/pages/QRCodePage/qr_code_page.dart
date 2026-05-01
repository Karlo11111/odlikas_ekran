import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_ekran/responsive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class QRCodePage extends StatefulWidget {
  final String screenId;
  const QRCodePage({super.key, required this.screenId});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  Responsive res = new Responsive();

  late String _screenId;

  // Datum i vrijeme kada QR kôd ističe
  DateTime? _endTime;

  // Povremeni mjerač vremena za ažuriranje korisničkog sučelja svake sekunde.
  Timer? _countdownTimer;

  // stream firestore dokumenata
  late Stream<DocumentSnapshot> _screenDocStream;

  // Jesmo li završili s učitavanjem prefs/endTime i pokrenuli mjerač vremena.
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _screenId = widget.screenId;

    _initializeScreenIdAndEndTime();
  }

  // Ova funkcija upravlja aync ucitavanjem screenId-a i endTime-a.
  Future<void> _initializeScreenIdAndEndTime() async {
    // ako nismo dobili id iz konstruktora, pokusaj ga ucitati iz prefs-a
    if (_screenId.isEmpty) {
      await _loadScreenIdFromPrefs();
    }
    //sad kad mozda imamo screenId, inicijaliziraj firestore listener
    if (_screenId.isNotEmpty) {
      _initFirestoreListener(_screenId);
    }

    // inicializiraj endTime iz prefs-a
    await _loadEndTimeFromPrefs();

    // ako nema endTime-a, postavi ga na 5 minuta od sada
    if (_endTime == null) {
      await _setEndTimeToFiveMinutesFromNow();
    }

    // kreni s mjeračem vremena
    _startCountdown();

    // prikazi UI
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadScreenIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('screenId') ?? '';
    _screenId = storedId;
  }

  void _initFirestoreListener(String screenId) {
    _screenDocStream = FirebaseFirestore.instance
        .collection('CreatedScreens')
        .doc(screenId)
        .snapshots();

    _screenDocStream.listen((docSnapshot) async {
      if (!docSnapshot.exists) return;
      final data = docSnapshot.data() as Map<String, dynamic>;
      final connected = data['connected'] as bool? ?? false;

      if (connected) {
        final token = data['token'] as String?;
        final email = data['linkedUser'] as String?;
final box = await Hive.openBox('user_credentials');
        if (token != null) await box.put('token', token);
        if (email != null) await box.put('email', email);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('connectedOnce', true);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _loadEndTimeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeString = prefs.getString('qrEndTime');
    if (endTimeString != null && endTimeString.isNotEmpty) {
      _endTime = DateTime.tryParse(endTimeString);
    }
  }

  Future<void> _setEndTimeToFiveMinutesFromNow() async {
    _endTime = DateTime.now().add(const Duration(minutes: 5, seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qrEndTime', _endTime!.toIso8601String());
  }

  void _startCountdown() {
    _countdownTimer?.cancel(); // ako se vec vrti
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // ako je vrijeme gotovo ili ako je endTime null stavi screenId na prazan string
      if (_endTime == null || DateTime.now().isAfter(_endTime!)) {
        timer.cancel();
        await _deleteDocAndResetPrefs();
        if (!mounted) return;
        setState(() {
          _screenId = '';
        });
      } else {
        // rebuildaj UI
        setState(() {});
      }
    });
  }

  Future<void> _deleteDocAndResetPrefs() async {
    if (_screenId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(_screenId)
          .delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('screenId');
    await prefs.remove('qrEndTime');
    await prefs.remove('setupDone');
  }

  @override
  Widget build(BuildContext context) {
    // ako nije zavrsilo s inicijalizacijom prikazi loading
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/bird_animation.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // ako je screenId prazan, prikaži ekran koji je istekao
    if (_screenId.isEmpty) {
      // ako je endTime postavljen i ako je trenutno vrijeme nakon endTime-a
      if (_endTime != null && DateTime.now().isAfter(_endTime!)) {
        return _buildExpiredScreen();
      }
      // inace prikazi loading
      return Scaffold(
          body: Center(
        child: Lottie.asset(
          'assets/animations/bird_animation.json',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ));
    }

    // izračunaj preostalo vrijeme
    final now = DateTime.now();
    final totalSecondsLeft =
        _endTime != null ? _endTime!.difference(now).inSeconds : 0;
    final clampedSeconds = totalSecondsLeft < 0 ? 0 : totalSecondsLeft;
    final minutes = clampedSeconds ~/ 60;
    final seconds = clampedSeconds % 60;
    final formattedTime = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: res.scaleHeight(context, 150)),
              //qr kod i timer widget u jednom redu
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(res.scaleWidth(context, 6)),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: res.scaleWidth(context, 1.7),
                      ),
                    ),
                    child: QrImageView(
                      data: _screenId,
                      version: QrVersions.auto,
                      size: res.scaleWidth(context, 70),
                      gapless: true,
                    ),
                  ),
                  SizedBox(
                    width: res.scaleWidth(context, 20),
                  ),
                  //do isteka tekst and timer text in a column
                  Column(
                    children: [
                      Text('Do isteka QR koda:',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: res.scaleWidth(context, 12))),
                      Container(
                        margin: EdgeInsets.only(
                            bottom: res.scaleHeight(context, 20),
                            top: res.scaleHeight(context, 5)),
                        child: Text(
                          '$formattedTime min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: res.scaleWidth(context, 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: res.scaleHeight(context, 120)),

              Text(
                'SKENIRAJ ME PREKO ODLIKAŠA DA ZAPOČNEMO',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: res.scaleWidth(context, 8),
                ),
              ),
              Text(
                'UČITI',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: res.scaleWidth(context, 8),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExpiredScreen() {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior
            .translucent, // pobrine se da se klikovi prosljede ispod i da cijeli ekran bude klikabilan
        onTap: () => Navigator.pushReplacementNamed(context, "/setup"),
        child: const SizedBox.expand(
          //popuni cijeli ekran
          child: Center(
            child: Text(
              'QR kod je istekao. Pritisnite za ponovno postavljanje.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
