import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiService {
  final String _apiKey = dotenv.get("OPENAI_API_KEY");

  Future<List<Map<String, String>>?> solveMathExpression(
      String latexExpression) async {
    final uri = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    final messages = [
      {
        "role": "system",
        "content":
            "Kao matematički asistent, generiraj KORAKS isključivo u JSON formatu:\n"
                "{\"steps\": [{\"step\": \"opis\", \"result\": \"LaTeX\"}]}\n"
                "Pravila:\n"
                "1. Za JEDNOSTAVNE IZRAZE (bez varijabli):\n"
                "   - Zadnji korak: samo konačni broj u obliku \\boxed{42}\n"
                "   - Koraci: prikaži sve međukorake\n"
                "2. Za SUSTAVE JEDNADŽBI:\n"
                "   - Zadnji korak: prikaži obje varijable u formatu \\boxed{x=2}, \\boxed{y=1}\n"
                "   - Koristi \\begin{cases} za sustave\n"
                "   - Prikaži sve korake supstitucije\n"
                "3. Za JEDNADŽBE S JEDNOM VARIJABLOM:\n"
                "   - Zadnji korak: \\boxed{x=5}\n"
                "4. Hrvatski jezik za sve opise\n"
                "5. Nikada ne koristi \$ znakove\n"
                "6. Izbjegavati tekst u result polju - samo matematički izrazi"
      },
      {
        "role": "user",
        "content": "Riješi: ${_preprocessLatex(latexExpression)}\n"
            "Postupi ovako:\n"
            "1. Analiziraj tip zadatka\n"
            "2. Za obične izraze - prikaži sve međukorake ali zadnji korak samo konačni broj\n"
            "3. Za jednadžbe s varijablama - prikaži sve varijable u konačnom rješenju\n"
            "4. Koristi ispravan LaTeX bez grešaka"
      }
    ];

    final body = {
      "model": "gpt-4",
      "messages": messages,
      "max_tokens": 2000,
      "temperature": 0.3,
    };

    try {
      final response =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      return _handleApiResponse(response);
    } catch (e) {
      print('Request failed: $e');
      return null;
    }
  }

  List<Map<String, String>>? _handleApiResponse(http.Response response) {
    print('API Response: ${response.body}');

    if (response.statusCode != 200) {
      print('API Error: ${response.statusCode}');
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseContent(content);
    } catch (e) {
      print('Response parsing error: $e');
      return null;
    }
  }

  List<Map<String, String>>? _parseContent(String content) {
    try {
      // Step 1: Extract clean JSON
      final jsonString = _extractPureJson(content);

      // Step 2: Fix encoding issues
      final fixedEncoding = _cleanStepDescription(jsonString);

      // Step 3: Parse JSON
      final jsonData = jsonDecode(fixedEncoding) as Map<String, dynamic>;

      // Step 4: Validate and process steps
      return _processSteps(jsonData['steps']);
    } catch (e) {
      print('Content processing failed: $e');
      print(
          'Problematic content: ${e is FormatException ? e.source : content}');
      return null;
    }
  }

  String _extractPureJson(String input) {
    // Match the outermost JSON object including nested structures
    final jsonPattern = RegExp(r'^\s*\{[\s\S]*\}\s*$');
    if (jsonPattern.hasMatch(input)) return input;

    // Extract first complete JSON object
    final jsonStart = input.indexOf('{');
    final jsonEnd = input.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw FormatException('No valid JSON found', input);
    }

    return input
        .substring(jsonStart, jsonEnd + 1)
        .replaceAll(RegExp(r'\\n'), '')
        .replaceAll(RegExp(r'^[^{]*'), '')
        .replaceAll(RegExp(r'[^}]*$'), '');
  }

  List<Map<String, String>>? _processSteps(dynamic steps) {
    if (steps is! List) {
      print('Invalid steps format - expected List');
      return null;
    }

    return steps.map<Map<String, String>>((step) {
      if (step is! Map<String, dynamic>) {
        print('Invalid step format - skipping');
        return {'step': 'Nevažeći korak', 'result': ''};
      }

      final description = _cleanStepDescription(step['step']?.toString() ?? '');
      final result = _fixLatexFormatting(step['result']?.toString() ?? '');

      return {
        'step': description,
        'result': _validateLatex(result),
      };
    }).toList();
  }

  String _validateLatex(String latex) {
    // Handle system of equations final answer
    if (latex.contains(r'\begin{cases}')) {
      return latex
          .replaceAll(RegExp(r'\\end{cases}'), r'\end{cases}')
          .replaceAll(RegExp(r'\\\s*'), r' \\ ');
    }

    // Handle multiple variables in final answer
    if (latex.contains(',')) {
      return latex
          .replaceAllMapped(RegExp(r'(\w+)\s*=\s*([\d.]+)'),
              (m) => '\\boxed{${m[1]} = ${m[2]}}')
          .replaceAll(',', ', ');
    }

    // Handle single-value results
    if (!latex.contains('=') && !latex.contains(r'\boxed')) {
      final value = latex.replaceAll(RegExp(r'[^\d.]'), '');
      return '\\boxed{$value}';
    }

    return latex;
  }

  String _cleanStepDescription(String desc) {
    return desc
        .replaceAll('Ä‡', 'č')
        .replaceAll('Å¡', 'š')
        .replaceAll('Å¾', 'ž')
        .replaceAll('–', '-')
        .replaceAll('â€', '-')
        .replaceAll('Ã¨', 'è')
        .replaceAll('Ã©', 'é');
  }

  String _fixLatexFormatting(String latex) {
    return latex
        .replaceAll(r'\$', '')
        .replaceAll('*', r'\times ')
        .replaceAllMapped(
            RegExp(r'(\d)([a-zA-Z])'), (m) => '${m[1]} \\cdot ${m[2]}')
        .replaceAll('=>', r'\Rightarrow');
  }

  String _preprocessLatex(String latex) {
    return latex
        .replaceAll(RegExp(r'\\begin{array}{.*?}'), '')
        .replaceAll(r'\end{array}', '')
        .replaceAll('\\\\', '\n')
        .replaceAll(RegExp(r'\\[()$]'), '')
        .trim();
  }
}
