import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MathpixAiSolving {
  Future<String?> sendImageToMathpix(Uint8List imageBytes) async {
    // enkodiraj sliku u base64
    String base64Image = base64Encode(imageBytes);

    // Mathpix API endpoint
    String apiUrl = 'https://api.mathpix.com/v3/text';

    // mathpix API ključevi
    String appId = dotenv.get("MATHPIX_APP_ID");
    String appKey = dotenv.get("MATHPIX_APP_KEY");

    // zaglavlja zahtjeva
    Map<String, String> headers = {
      'app_id': appId,
      'app_key': appKey,
      'Content-Type': 'application/json',
    };

    // tijelo zahtjeva
    Map<String, dynamic> body = {
      'src': 'data:image/png;base64,$base64Image',
      'formats': ['text', 'data'],
      'data_options': {
        'include_latex': true,
      },
    };

    // slanje zahtjeva
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // raščlanjivanje odgovora
        final responseData = jsonDecode(response.body);
        String latex = responseData['text'];
        debugPrint('LaTeX: $latex');

        return latex;
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}
