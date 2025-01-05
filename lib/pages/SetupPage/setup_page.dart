import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/QRCodePage/qr_code_page.dart';
import 'package:odlikas_ekran/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // Generate a new doc in "CreatedScreens"
      final docRef =
          FirebaseFirestore.instance.collection('CreatedScreens').doc();
      final newId = docRef.id;

      /* KADA SE BUDE RADILA ALPIKACIJA NA MOBU TREBA UPDATEAT OVAJ CONNECTED FIELD: await FirebaseFirestore.instance
    .collection('CreatedScreens')
    .doc(scannedScreenId)
    .update({
      'connected': true,
    }); */
      await docRef.set({
        'screenId': newId,
        'createdAt': FieldValue.serverTimestamp(),
        'connected': false,
      });

      // Mark setup as done locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setupDone', true);

      //savve the screen id in prefs
      await prefs.setString('screenId', newId);

      //setup detection
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
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: EdgeInsets.all(res.scaleWidth(context, 16.0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Dobrodošli u Odlikaš!',
                      style:
                          TextStyle(fontSize: res.scaleWidth(context, 16), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: res.scaleHeight(context, 16)),
                    Text(
                      'Ovo je prvo pokretanje aplikacije.\n'
                      'Pritisnite "Nastavi" za postavljanje i povezivanje s mobilnim uređajem.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: res.scaleWidth(context, 6)),
                    ),
                    SizedBox(height: res.scaleHeight(context, 32)),
                    ElevatedButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.only(left: res.scaleWidth(context, 6), right:  res.scaleWidth(context, 6), top:  res.scaleWidth(context, 2), bottom:  res.scaleWidth(context, 2)))
                      ),
                      onPressed: _onContinuePressed,
                      child: Text('Nastavi', style: TextStyle(fontSize: res.scaleWidth(context, 8)),),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
