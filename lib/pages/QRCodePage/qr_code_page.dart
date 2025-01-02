import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRCodePage extends StatefulWidget {
  final String screenId;
  const QRCodePage({super.key, required this.screenId});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  late String _screenId;

  /// Datum i vrijeme kada QR kôd ističe
  DateTime? _endTime;

  /// Povremeni mjerač vremena za ažuriranje korisničkog sučelja svake sekunde.
  Timer? _countdownTimer;

  /// stream firestore dokumenata
  late Stream<DocumentSnapshot> _screenDocStream;

  /// Jesmo li završili s učitavanjem prefs/endTime i pokrenuli mjerač vremena.
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _screenId = widget.screenId;

    _initializeScreenIdAndEndTime();
  }

  /// Ova funkcija upravlja aync ucitavanjem screenId-a i endTime-a.
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ako je screenId prazan, prikaži ekran koji je istekao
    if (_screenId.isEmpty) {
      // ako je endTime postavljen i ako je trenutno vrijeme nakon endTime-a
      if (_endTime != null && DateTime.now().isAfter(_endTime!)) {
        return _buildExpiredScreen();
      }
      // inace prikazi loading
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: _screenId,
                  version: QrVersions.auto,
                  size: 210.0,
                  gapless: true,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20, top: 5),
                child: Text(
                  '$formattedTime min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const Text(
                'SKENIRAJ ME PREKO ODLIKAŠA DA ZAPOČNEMO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                'UČITI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
