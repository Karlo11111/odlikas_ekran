import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepseekService {
  // DeepSeek API key
  final String _apiKey = dotenv.get("DEEPSEEK_API_KEY");

  // DeepSeek API endpoint
  final String _apiEndpoint = "https://api.deepseek.com/v1/chat/completions";

  // Method for solving mathematical expressions and word problems
  Future<List<Map<String, String>>?> solveMathExpression(
      String expression) async {
    final uri = Uri.parse(_apiEndpoint);
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    // Preprocess the expression
    final preprocessedExpression = _preprocessExpression(expression);

    // Detect if this is a word problem or a formula
    final bool isWordProblem = _isWordProblem(preprocessedExpression);

    // Select the appropriate system prompt based on the type of problem
    final systemPrompt =
        isWordProblem ? _getWordProblemPrompt() : _getEquationPrompt();

    // Prepare the messages for the API
    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": """Riješi: $preprocessedExpression"""}
    ];

    // Request body with optimized parameters
    final body = {
      "model": "deepseek-chat",
      "messages": messages,
      "max_tokens": 2000,
      "temperature": 0.1,
      "top_p": 0.85,
    };

    try {
      // Send request with timeout
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

  // Method for generating similar tasks (unchanged)
  Future<List<Map<String, String>>?> generateSimilarTasks(
      String originalExpression) async {
    final uri = Uri.parse(_apiEndpoint);
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    // Prompt for generating similar tasks
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

    // Request body
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

  // Detect if the problem is a word problem or a formula
  bool _isWordProblem(String text) {
    // Count words (by spaces) and check for certain patterns
    final wordCount = text.split(' ').length;

    // Check for common word problem indicators
    final hasWordProblemIndicators = text.contains('koliko') ||
        text.contains('izračunaj') ||
        text.contains('riješi') ||
        text.contains('zadatak') ||
        text.contains('ako') ||
        text.contains('nađi');

    // Check for common equation indicators
    final hasEquationIndicators = text.contains('=') ||
        text.contains('+') ||
        text.contains('-') ||
        text.contains('*') ||
        text.contains('/') ||
        text.contains('^');

    // If it has many words OR word problem indicators WITHOUT equation indicators
    return (wordCount > 10) ||
        (hasWordProblemIndicators && !hasEquationIndicators);
  }

  // System prompt for word problems
  String _getWordProblemPrompt() {
    return """Kao matematički asistent, pretvori tekstualni zadatak u matematički problem i riješi ga. 
Odgovori u sljedećem JSON formatu:

{
  "steps": [
    {
      "step": "Korak 1: Postavljanje zadatka",
      "result": "Matematički zapis problema u LaTeX-u",
      "explanation": "Objašnjenje kako se tekstualni zadatak prevodi u matematički problem"
    },
    {
      "step": "Korak 2: Naziv sljedećeg koraka",
      "result": "LaTeX formula za taj korak",
      "explanation": "Objašnjenje tog koraka na hrvatskom jeziku"
    },
    ...daljnji koraci...
  ],
  "final_answer": "Konačni rezultat s mjernom jedinicom i objašnjenjem"
}

Ključna pravila:
1. Prvi korak UVIJEK treba biti postavljanje zadatka (pretvaranje teksta u formulu)
2. Koristi \\displaystyle za svaku jednadžbu da ne prelazi u novi red
3. Objasni svaki korak detaljno i na hrvatskom jeziku
4. Ako zadatak ima više koraka, razdvoji ih logički
5. U konačnom odgovoru navedi i mjernu jedinicu ako je primjenjivo
6. Za tekstualne zadatke detaljno objasni kako si postavio formulu iz teksta
7. Ako je potrebno nacrtati nešto, objasni to riječima""";
  }

  // System prompt for equation solving
  String _getEquationPrompt() {
    return """Kao matematički asistent, generiraj brzo i efikasno korake rješenja za matematičke izraze i jednadžbe.
Format odgovora:
{
  "steps": [
    {
      "step": "Kratak naziv koraka",
      "result": "LaTeX formula",
      "explanation": "Objašnjenje na hrvatskom jeziku"
    }
  ],
  "final_answer": "Konačni rezultat"
}

Ključna pravila:
1. Korak po korak rješavanje, bez preskakanja
2. Formatiraj svaku formulu kao jednu liniju (koristi \\displaystyle za svaku jednadžbu)
3. Za sustave koristi \\begin{cases} \\displaystyle jednadžba1 \\\\ \\displaystyle jednadžba2 \\end{cases}
4. Maksimalno 7-8 koraka
5. Izbjegavaj Unicode znakove u LaTeX dijelu
6. Koristi \\times umjesto * za množenje""";
  }

  // Method for processing the API response
  List<Map<String, String>>? _handleApiResponse(http.Response response) {
    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  // Enhanced method for parsing the response content
  List<Map<String, String>>? _parseContent(String content) {
    try {
      // Clean the content from markdown code blocks if present
      String cleanedContent = _removeMarkdownCodeBlocks(content);
      debugPrint('Cleaned JSON: $cleanedContent');

      // Sanitize JSON before parsing
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

      // Add final answer if present
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

  // Clean markdown code blocks
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

  // Fallback JSON parsing for malformed JSON
  Map<String, dynamic> _fallbackJsonParsing(String input) {
    // Simple fallback that extracts steps using regex
    final stepsRegex = RegExp(r'"steps"\s*:\s*\[(.*?)\]', dotAll: true);
    final finalAnswerRegex =
        RegExp(r'"final_answer"\s*:\s*"(.*?)"', dotAll: true);

    final stepsMatch = stepsRegex.firstMatch(input);
    final finalAnswerMatch = finalAnswerRegex.firstMatch(input);

    final stepsList = <Map<String, dynamic>>[];

    if (stepsMatch != null) {
      final stepsStr = stepsMatch.group(1);
      // Very simplistic parsing - would need to be more robust in production
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

  // Method for handling the similar tasks response
  List<Map<String, String>>? _handleSimilarTasksResponse(
      http.Response response) {
    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseSimilarTasksContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  // Method for parsing the similar tasks content
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

  // Advanced JSON sanitization
  String _sanitizeJson(String input) {
    String sanitized = input;

    // Remove unescaped backslashes except in valid escape sequences
    sanitized = sanitized.replaceAll(
        RegExp(r'(?<!\\)\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})'), '');

    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Normalize newlines
    sanitized = sanitized.replaceAll(RegExp(r'\\n'), ' ');

    // Fix common LaTeX rendering issues
    sanitized = sanitized.replaceAll(r'\{', '{').replaceAll(r'\}', '}');

    // Fix common JSON errors with LaTeX
    sanitized = sanitized.replaceAll(r'\\\\', r'\\');

    return sanitized;
  }

  // Improved steps processing with better error handling
  List<Map<String, String>> _processSteps(List<dynamic> steps) {
    final processedSteps = <Map<String, String>>[];

    for (final step in steps) {
      try {
        final stepData = step as Map<String, dynamic>;

        // Extract values safely with fallbacks
        String stepTitle = stepData['step']?.toString() ?? 'Korak';
        String result = stepData['result']?.toString() ?? '';
        String explanation = stepData['explanation']?.toString() ?? '';

        // Skip truly empty steps
        if (stepTitle.isEmpty && result.isEmpty && explanation.isEmpty) {
          continue;
        }

        // Clean and format
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

  // Comprehensive text cleaning for Croatian characters
  String _cleanText(String text) {
    if (text.isEmpty) return text;

    // Replace Croatian special characters - comprehensive approach
    Map<String, String> croatianCharMap = {
      'Ä‡': 'ć',
      'Ä\u0087': 'ć',
      'Ä\u0107': 'ć',
      'Ä†': 'Ć',
      'Ä\u0086': 'Ć',
      'Ä': 'č',
      'Ä\u008D': 'š',
      'Ä\u010D': 'č',
      'Ä\u008C': 'Č',
      'Ä\u010C': 'Č',
      'Ä\u0091': 'č',
      'Ä\u0111': 'č',
      'Ä\u0090': 'Č',
      'Ä\u0110': 'Č',
      'Å¡': 'š',
      'Å\u0161': 'š',
      'Å\u0160': 'Š',
      'Å¾': 'ž',
      'Å\u017E': 'ž',
      'Å\u017D': 'Ž',
    };

    String cleaned = text;

    // Apply all character replacements
    croatianCharMap.forEach((key, value) {
      cleaned = cleaned.replaceAll(key, value);
    });

    // Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  // Format LaTeX content properly with display style to prevent line breaks
  String _formatLatex(String latex) {
    if (latex.isEmpty) return latex;

    String formatted = latex;

    // Remove unnecessary dollar signs
    formatted = formatted.replaceAll(RegExp(r'\$(.*?)\$'), r'\1');

    // Fix multiplication signs
    formatted = formatted.replaceAll('*', r'\times ');

    // Remove boxed environments
    formatted = formatted.replaceAllMapped(
        RegExp(r'\\boxed{(.*?)}', dotAll: true), (m) => m.group(1) ?? '');

    // Fix equations that might break to next line by adding \displaystyle
    formatted = formatted.replaceAllMapped(
        RegExp(r'([0-9]+[a-z]\s*[-+]\s*[0-9]+[a-z]\s*=\s*[0-9]+)'),
        (m) => '\\displaystyle ${m.group(1)}');

    // Format the cases environment properly with displaystyle
    formatted = formatted.replaceAllMapped(
        RegExp(r'\\begin{cases}(.*?)\\end{cases}', dotAll: true), (match) {
      String content = match.group(1) ?? '';

      // Split the content properly for cases environment
      List<String> lines = [];

      if (content.contains(r'\\')) {
        // Use existing line breaks
        lines = content
            .split(r'\\')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else if (content.contains('\n')) {
        // Split by newlines
        lines = content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else {
        // Try to infer structure
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
          // If all else fails, use the content as is
          lines.add(content.trim());
        }
      }

      // Add \displaystyle to each line to prevent breaking
      lines = lines.map((line) => '\\displaystyle $line').toList();

      return '\\begin{cases} ${lines.join(' \\\\ ')} \\end{cases}';
    });

    // Add \displaystyle to regular equations to prevent line breaks
    if (formatted.contains('=') &&
        !formatted.contains('\\begin{cases}') &&
        !formatted.contains('\\displaystyle')) {
      formatted = '\\displaystyle $formatted';
    }

    return formatted;
  }

  // Preprocess expression for both equations and word problems
  String _preprocessExpression(String expression) {
    // Check if it's likely a word problem or an equation
    if (_isWordProblem(expression)) {
      // For word problems, minimal preprocessing
      return expression.replaceAll(RegExp(r'\s+'), ' ').trim();
    } else {
      // For equations, more aggressive preprocessing
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
