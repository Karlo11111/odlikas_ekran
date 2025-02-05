import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MathpixAiSolving {
  Future<String?> sendImageToMathpix(Uint8List imageBytes) async {
    // Encode image to base64
    String base64Image = base64Encode(imageBytes);

    // Mathpix API endpoint
    String apiUrl = 'https://api.mathpix.com/v3/text';

    // Your Mathpix credentials
    String appId = dotenv.get("MATHPIX_APP_ID");
    String appKey = dotenv.get("MATHPIX_APP_KEY");

    // Request headers
    Map<String, String> headers = {
      'app_id': appId,
      'app_key': appKey,
      'Content-Type': 'application/json',
    };

    // Request body
    Map<String, dynamic> body = {
      'src': 'data:image/png;base64,$base64Image',
      'formats': ['text', 'data'],
      'data_options': {
        'include_latex': true,
      },
    };

    // Send POST request
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Parse the response
        final responseData = jsonDecode(response.body);
        String latex = responseData['text'];
        print('LaTeX: $latex');

        return latex;
        // Handle the LaTeX string as needed
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
