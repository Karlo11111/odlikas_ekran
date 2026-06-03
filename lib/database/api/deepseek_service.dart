import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepseekService {
  final String _apiKey = dotenv.get("DEEPSEEK_API_KEY");
  final String _apiEndpoint = "https://api.deepseek.com/v1/chat/completions";

  Future<List<Map<String, String>>?> solveMathExpression(
      String expression) async {
    final uri = Uri.parse(_apiEndpoint);
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    final preprocessedExpression = _preprocessExpression(expression);
    final bool isWordProblem = _isWordProblem(preprocessedExpression);
    final systemPrompt =
        isWordProblem ? _getWordProblemPrompt() : _getEquationPrompt();

    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": """Riješi: $preprocessedExpression"""}
    ];

    // temperature: 0.1 keeps math answers deterministic; higher values cause
    // the model to invent incorrect intermediate steps
    final body = {
      "model": "deepseek-chat",
      "messages": messages,
      "max_tokens": 4000,
      "temperature": 0.1,
      "top_p": 0.85,
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));

      debugPrint('DeepSeek API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _handleApiResponse(response);
      } else {
        debugPrint('API Error: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Request failed: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>?> generateSimilarTasks(
      String originalExpression) async {
    final uri = Uri.parse(_apiEndpoint);
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    final messages = [
      {
        "role": "system",
        "content":
            """Kao matematički asistent za učenike, generiraj slične matematičke zadatke u JSON formatu:
      {
        "similar_tasks": [
          {
            "difficulty": "lakši",
            "task": "Matematički izraz ili zadatak",
            "explanation": "Kako se razlikuje od originalnog zadatka"
          },
          {...}
        ]
      }

      Pravila generiranja:
      1. Generiraj ukupno 10 zadataka:
         - 5 lakših od originala
         - 2 iste težine (samo s različitim brojevima ili kontekstom)
         - 3 teža od originala

      2. Formatiranje:
         - LaTeX format za matematičke izraze
         - Za tekstualne zadatke zadrži isti format, ali promijeni kontekst ili brojeve
         - Odgovarajuće varijacije težine

      3. Objašnjenja:
         - Kratko objasni po čemu je zadatak lakši ili teži od originala
         - Za slične zadatke navedi koje vrijednosti ili kontekst su promijenjeni"""
      },
      {
        "role": "user",
        "content":
            """Generiraj slične zadatke za: ${_preprocessExpression(originalExpression)}

        Molim te 10 zadataka prema pravilima:
        - 5 lakših
        - 2 ista zadatka s različitim brojevima ili kontekstom
        - 3 teža zadatka"""
      }
    ];

    // Higher temperature than solveMathExpression — creative variation is
    // desirable here, exact correctness is less critical
    final body = {
      "model": "deepseek-chat",
      "messages": messages,
      "max_tokens": 3000,
      "temperature": 0.7,
    };

    try {
      final response =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      return _handleSimilarTasksResponse(response);
    } catch (e) {
      debugPrint('Request failed: $e');
      return null;
    }
  }

  bool _isWordProblem(String text) {
    final wordCount = text.split(' ').length;

    final hasWordProblemIndicators = text.contains('koliko') ||
        text.contains('izračunaj') ||
        text.contains('riješi') ||
        text.contains('zadatak') ||
        text.contains('ako') ||
        text.contains('nađi');

    final hasEquationIndicators = text.contains('=') ||
        text.contains('+') ||
        text.contains('-') ||
        text.contains('*') ||
        text.contains('/') ||
        text.contains('^');

    return (wordCount > 10) ||
        (hasWordProblemIndicators && !hasEquationIndicators);
  }

  String _getWordProblemPrompt() {
    return """Kao matematicki asistent za ucenike, pretvori tekstualni zadatak u matematicki problem i rijesi ga korak po korak.
Odgovori ISKLJUCIVO u sljedecem JSON formatu (bez teksta izvan JSON-a):

{
  "steps": [
    {
      "step": "Korak 1: Postavljanje zadatka",
      "result": "Matematicki zapis problema u LaTeX-u",
      "explanation": "Detaljno objasni sto zadatak trazi, koje velicine su poznate, koje trazimo, i zasto koristimo bas ovu formulu ili pristup."
    },
    {
      "step": "Korak 2: Naziv sljedeceg koraka",
      "result": "LaTeX formula za taj korak",
      "explanation": "Objasni ZASTO radimo ovaj korak (koji matematicki zakon ili pravilo primjenjujemo), a ne samo STO radimo. Navedite ime matematickog zakona ako postoji."
    }
  ],
  "final_answer": "Konacni rezultat s mjernom jedinicom"
}

Kljucna pravila:
1. Prvi korak UVIJEK postavlja zadatak (prevodi tekst u formulu) i objasnjava sve poznate velicine
2. Svaki korak mora imati detaljan 'explanation' koji objasnjava ZASTO se taj korak radi (koji zakon, teorem ili pravilo se primjenjuje)
3. Koristi \\displaystyle za svaku jednadžbu
4. Ne preskacu koraci - svaka transformacija je poseban korak
5. U 'explanation' navedi konkretno ime zakona/pravila (npr. 'Distributivni zakon', 'Pitagorin teorem', 'Pravilo znakova')
6. U konacnom odgovoru navedi i mjernu jedinicu
7. Nemoj koristiti dijakriticka slova c, c, d, s, z umjesto hrvatskih slova
VAZNO: Nemoj koristiti dijaktriticka slova c, c, d, s, z (niti velika inacica).""";
  }

  String _getEquationPrompt() {
    return """Kao matematicki asistent za ucenike, rijesi matematicki izraz ili jednadžbu korak po korak s dubinskim objasnjenjima.
Odgovori ISKLJUCIVO u sljedecem JSON formatu (bez teksta izvan JSON-a):

{
  "steps": [
    {
      "step": "Kratak naziv koraka",
      "result": "LaTeX formula",
      "explanation": "Objasni ZASTO radimo ovaj korak - koji matematicki zakon, pravilo ili teorem primjenjujemo, i zasto je to ispravno. Ne samo sto radimo, nego zasto."
    }
  ],
  "final_answer": "Konacni rezultat"
}

Kljucna pravila:
1. Korak po korak rjesavanje - svaka transformacija je poseban korak, bez preskakanja
2. Svaki 'explanation' mora navoditi konkretni zakon/pravilo (npr. 'Komutativni zakon zbrajanja', 'Kvadrat binoma', 'Zakon o ponistavanju suprotnih clanova')
3. Objasni zasto je svaki korak matematicki ispravan, ne samo sto radimo
4. Formatiraj svaku formulu kao jednu liniju (koristi \\displaystyle)
5. Za sustave koristi \\begin{cases} \\displaystyle jednadžba1 \\\\ \\displaystyle jednadžba2 \\end{cases}
6. Izbjegavaj Unicode znakove u LaTeX dijelu
7. Koristi \\times umjesto * za mnozenje
8. Ako postoje posebni slucajevi ili zamke (npr. dijeljenje s nulom, negativan korijen), upozori na njih u objasnjenju
VAZNO: Nemoj koristiti dijakriticka slova c, c, d, s, z umjesto c, c, d, s, z.""";
  }

  List<Map<String, String>>? _handleApiResponse(http.Response response) {
    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  List<Map<String, String>>? _parseContent(String content) {
    try {
      String cleanedContent = _removeMarkdownCodeBlocks(content);
      debugPrint('Cleaned JSON: $cleanedContent');

      // DeepSeek sometimes returns LaTeX backslashes unescaped inside JSON
      // strings, which breaks standard parsing — sanitize before decoding
      cleanedContent = _sanitizeJson(cleanedContent);

      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(cleanedContent) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON decode error: $e');
        jsonData = _fallbackJsonParsing(cleanedContent);
      }

      final steps = jsonData['steps'] as List<dynamic>;
      final finalAnswer = jsonData['final_answer'] as String?;

      final processedSteps = _processSteps(steps);

      if (finalAnswer != null && finalAnswer.isNotEmpty) {
        processedSteps.add({
          'step': 'Konačno rješenje',
          'result': _formatLatex(finalAnswer),
          'explanation': 'Konačni rezultat zadatka',
        });
      }

      return processedSteps;
    } catch (e) {
      debugPrint('Content processing failed: $e');
      debugPrint('Raw content: $content');
      return null;
    }
  }

  String _removeMarkdownCodeBlocks(String content) {
    if (content.startsWith('```')) {
      final firstLineEnd = content.indexOf('\n');
      if (firstLineEnd != -1) {
        String cleanedContent = content.substring(firstLineEnd + 1);
        if (cleanedContent.endsWith('```')) {
          cleanedContent =
              cleanedContent.substring(0, cleanedContent.length - 3);
        }
        return cleanedContent.trim();
      }
    }
    return content.trim();
  }

  Map<String, dynamic> _fallbackJsonParsing(String input) {
    final stepsRegex = RegExp(r'"steps"\s*:\s*\[(.*?)\]', dotAll: true);
    final finalAnswerRegex =
        RegExp(r'"final_answer"\s*:\s*"(.*?)"', dotAll: true);

    final stepsMatch = stepsRegex.firstMatch(input);
    final finalAnswerMatch = finalAnswerRegex.firstMatch(input);

    final stepsList = <Map<String, dynamic>>[];

    if (stepsMatch != null) {
      final stepsStr = stepsMatch.group(1);
      final stepRegex = RegExp(
          r'\{\s*"step"\s*:\s*"(.*?)"\s*,\s*"result"\s*:\s*"(.*?)"\s*,\s*"explanation"\s*:\s*"(.*?)"\s*\}',
          dotAll: true);
      final matches = stepRegex.allMatches(stepsStr!);

      for (final match in matches) {
        stepsList.add({
          'step': match.group(1) ?? '',
          'result': match.group(2) ?? '',
          'explanation': match.group(3) ?? '',
        });
      }
    }

    return {
      'steps': stepsList,
      'final_answer': finalAnswerMatch?.group(1) ?? '',
    };
  }

  List<Map<String, String>>? _handleSimilarTasksResponse(
      http.Response response) {
    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseSimilarTasksContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  List<Map<String, String>>? _parseSimilarTasksContent(String content) {
    try {
      String cleanedContent = _removeMarkdownCodeBlocks(content);
      final jsonData = jsonDecode(cleanedContent) as Map<String, dynamic>;
      final tasks = jsonData['similar_tasks'] as List<dynamic>;

      return tasks.map<Map<String, String>>((task) {
        final taskData = task as Map<String, dynamic>;
        return {
          'difficulty': _cleanText(taskData['difficulty']?.toString() ?? ''),
          'task': taskData['task']?.toString() ?? '',
          'explanation': _cleanText(taskData['explanation']?.toString() ?? ''),
        };
      }).toList();
    } catch (e) {
      debugPrint('Content processing failed: $e');
      return null;
    }
  }

  String _sanitizeJson(String input) {
    String sanitized = input;
    sanitized = sanitized.replaceAll(
        RegExp(r'(?<!\\)\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})'), '');
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\\n'), ' ');
    sanitized = sanitized.replaceAll(r'\{', '{').replaceAll(r'\}', '}');
    sanitized = sanitized.replaceAll(r'\\\\', r'\\');
    return sanitized;
  }

  List<Map<String, String>> _processSteps(List<dynamic> steps) {
    final processedSteps = <Map<String, String>>[];

    for (final step in steps) {
      try {
        final stepData = step as Map<String, dynamic>;

        String stepTitle = stepData['step']?.toString() ?? 'Korak';
        String result = stepData['result']?.toString() ?? '';
        String explanation = stepData['explanation']?.toString() ?? '';

        if (stepTitle.isEmpty && result.isEmpty && explanation.isEmpty) {
          continue;
        }

        stepTitle = _cleanText(stepTitle);
        result = _formatLatex(result);
        explanation = _cleanText(explanation);

        processedSteps.add({
          'step': stepTitle,
          'result': result,
          'explanation': explanation,
        });
      } catch (e) {
        debugPrint('Error processing step: $e');
      }
    }

    return processedSteps;
  }

  // DeepSeek occasionally returns Croatian characters as garbled multi-byte
  // sequences when the response isn't decoded as UTF-8 at the HTTP layer
  String _cleanText(String text) {
    if (text.isEmpty) return text;

    Map<String, String> croatianCharMap = {
      'Ä‡': 'ć',
      'Ä': 'ć',
      'Äć': 'ć',
      'Ä†': 'Ć',
      'Ä': 'Ć',
      'Ä': 'č',
      'Ä': 'š',
      'Äč': 'đ',
      'Ä': 'Č',
      'ÄČ': 'Č',
      'Ä': 'č',
      'Äđ': 'č',
      'Ä': 'Č',
      'ÄĐ': 'Č',
      'Å¡': 'š',
      'Åš': 'š',
      'ÅŠ': 'Š',
      'Å¾': 'ž',
      'Åž': 'ž',
      'ÅŽ': 'Ž',
    };

    String cleaned = text;
    croatianCharMap.forEach((key, value) {
      cleaned = cleaned.replaceAll(key, value);
    });
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  String _formatLatex(String latex) {
    if (latex.isEmpty) return latex;

    String formatted = latex;

    formatted = formatted.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true), (m) => m.group(1) ?? '');
    formatted = formatted.replaceAllMapped(RegExp(r'\$(.*?)\$', dotAll: true), (m) => m.group(1) ?? '');
    formatted = formatted.replaceAll('*', r'\times ');
    formatted = formatted.replaceAllMapped(
        RegExp(r'\\boxed{(.*?)}', dotAll: true), (m) => m.group(1) ?? '');

    formatted = formatted.replaceAllMapped(
        RegExp(r'([0-9]+[a-z]\s*[-+]\s*[0-9]+[a-z]\s*=\s*[0-9]+)'),
        (m) => '\\displaystyle ${m.group(1)}');

    // \displaystyle is required on every line inside \begin{cases} — without it
    // the flutter_math_fork renderer collapses equations onto a single line
    formatted = formatted.replaceAllMapped(
        RegExp(r'\\begin{cases}(.*?)\\end{cases}', dotAll: true), (match) {
      String content = match.group(1) ?? '';

      List<String> lines = [];

      if (content.contains(r'\\')) {
        lines = content
            .split(r'\\')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else if (content.contains('\n')) {
        lines = content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else {
        final equationPattern =
            RegExp(r'[0-9]+[a-z]\s*[-+]\s*[0-9]+[a-z]\s*=\s*[0-9]+');
        final matches = equationPattern.allMatches(content);

        if (matches.isNotEmpty) {
          int lastEnd = 0;
          for (final match in matches) {
            if (match.start > lastEnd) {
              lines.add(content.substring(lastEnd, match.start).trim());
            }
            lines.add(content.substring(match.start, match.end).trim());
            lastEnd = match.end;
          }
          if (lastEnd < content.length) {
            lines.add(content.substring(lastEnd).trim());
          }
        } else {
          lines.add(content.trim());
        }
      }

      lines = lines.map((line) => '\\displaystyle $line').toList();

      return '\\begin{cases} ${lines.join(' \\\\ ')} \\end{cases}';
    });

    if (formatted.contains('=') &&
        !formatted.contains('\\begin{cases}') &&
        !formatted.contains('\\displaystyle')) {
      formatted = '\\displaystyle $formatted';
    }

    return formatted;
  }

  String _preprocessExpression(String expression) {
    if (_isWordProblem(expression)) {
      return expression.replaceAll(RegExp(r'\s+'), ' ').trim();
    } else {
      return expression
          .replaceAll(RegExp(r'\\[(){}]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(r'\(', '')
          .replaceAll(r'\)', '')
          .replaceAll(r'$$', '')
          .replaceAll(r'$', '')
          .trim();
    }
  }
}
