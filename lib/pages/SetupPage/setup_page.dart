import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/pages/QRCodePage/qr_code_page.dart';
import 'package:odlikas_ekran/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _loading = false;
  Responsive res = new Responsive();

  Future<void> _onContinuePressed() async {
    setState(() => _loading = true);

    try {
      // generiraj novi dokument u "CreatedScreens"
      final docRef =
          FirebaseFirestore.instance.collection('CreatedScreens').doc();
      final newId = docRef.id;

      await docRef.set({
        'screenId': newId,
        'createdAt': FieldValue.serverTimestamp(),
        'connected': false,
      });

      // označi da je setup gotov
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setupDone', true);

      // spremi screenId u SharedPreferences (lokalni storage)
      await prefs.setString('screenId', newId);

      // spremi setup done u SharedPreferences
      await prefs.setBool('setupDone', true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => QRCodePage(
                  screenId: newId,
                )),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: const Text(
          'Nema internetske veze ili nije moguće povezati se na Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _loading
            ? Center(
                child: Lottie.asset(
                  'assets/animations/bird_animation.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              )
            : Padding(
                padding: EdgeInsets.all(res.scaleWidth(context, 16.0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: res.scaleHeight(context, 200)),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Dobrodošli u ODLIKAŠ+!',
                            style: GoogleFonts.inter(
                                fontSize: res.scaleWidth(context, 17),
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: res.scaleHeight(context, 16)),
                          Text(
                            'Primjetili smo da je ovo prvo pokretanje ODLIKAŠ+ aplikacije.\n'
                            'Pritisnite "Nastavi" kako bi i ti postao ODLIKAŠ.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: Color.fromRGBO(113, 113, 113, 1),
                                fontSize: res.scaleWidth(context, 6.2),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: res.scaleHeight(context, 200)),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Color.fromRGBO(23, 148, 210, 1)),
                          padding: WidgetStateProperty.all(EdgeInsets.only(
                              left: res.scaleWidth(context, 50),
                              right: res.scaleWidth(context, 50),
                              top: res.scaleWidth(context, 5),
                              bottom: res.scaleWidth(context, 5)))),
                      onPressed: _onContinuePressed,
                      child: Text(
                        'Nastavi',
                        style: GoogleFonts.inter(
                          fontSize: res.scaleWidth(context, 8),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
