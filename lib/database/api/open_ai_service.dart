import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiService {
  // openai API ključ
  final String _apiKey = dotenv.get("OPENAI_API_KEY");

  // metoda za rješavanje matematičkog izraza
  Future<List<Map<String, String>>?> solveMathExpression(
      String latexExpression) async {
    final uri = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    // prompt za rješavanje matematičkog izraza
    final messages = [
      {
        "role": "system",
        "content":
            """Kao iscrpan matematički asistent, generiraj detaljne korake isključivo u JSON formatu:
      {
        "steps": [
          {
            "step": "Korak 1: Opis operacije na hrvatskom jeziku",
            "result": "Matematički izraz u LaTeX-u bez okvira",
            "explanation": "Detaljno objašnjenje matematičkog koncepta"
      },
        {...}
      ],
      "final_answer": "Konačno rješenje bez \\boxed{} formata"
      }

      Pravila:
      1. Za SVAKI matematički postupak:
         - Koristi tri polja: step, result, explanation
         - Objasni SVAKU operaciju (npr. "Primjenjujemo distributivno svojstvo")
         - Za jednadžbe: Objasni svaku algebarsku transformaciju
         - Za sustave: Koristi metode supstitucije/eliminacije s detaljnim koracima
      
      2. Formatiranje:
         - Nikada ne koristi \$ znakove
         - Koristi hrvatske matematičke izraze (npr. "nepoznanica" umjesto "varijabla")
         - LaTeX bez okvira u result polju
         - Konačan odgovor u final_answer bez \\boxed
      
      3. Primjeri:
         - Jednadžba: 
           {
             "step": "Oduzmimo 5 s obje strane za izolaciju x",
             "result": "2x = 10",
             "explanation": "Oduzimanje konstante s obje strane održava jednakost"
           }
         - Sustav:
           {
             "step": "Supstitucija y iz prve jednadžbe u drugu",
             "result": "3x + 2(2x-1) = 8",
             "explanation": "Zamjena izraza za y iz prve jednadžbe u drugu jednadžbu"
           }

      4. Objašnjenja:
         - Navedi koristena matematička svojstva (npr. distributivno, asocijativno)
         - Objasni logiku iza svake algebarske transformacije
         - Za geometriju: Objasni teoreme i formule
         - Za razlomke: Objasni postupke skraćivanja"""
      },
      {
        "role": "user",
        "content":
            """Riješi korak po korak: ${_preprocessLatex(latexExpression)}
      - Zahtjevi:
      1. Detaljna tekstualna objašnjenja za SVAKU operaciju
      2. Prikaži SVE međukorake prije konačnog rješenja
      3. Koristi ispravne matematičke termine na hrvatskom
      4. Objasni geometrijski smisao gdje je primjenjivo
      5. Za složene izraze koristi više manjih koraka"""
      }
    ];

    // tijelo zahtjeva
    final body = {
      "model": "gpt-4-turbo",
      "messages": messages,
      "max_tokens": 3000,
      "temperature": 0,
    };

    try {
      // slanje zahtjeva
      final response =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      debugPrint(response.body);
      return _handleApiResponse(response);
    } catch (e) {
      debugPrint('Request failed: $e');
      return null;
    }
  }

  // Nova metoda za generiranje sličnih zadataka
  Future<List<Map<String, String>>?> generateSimilarTasks(
      String originalLatexExpression) async {
    final uri = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    // prompt za generiranje sličnih zadataka
    final messages = [
      {
        "role": "system",
        "content":
            """Kao matematički asistent za učenike, generiraj slične matematičke zadatke u JSON formatu:
      {
        "similar_tasks": [
          {
            "difficulty": "lakši",
            "task": "Matematički izraz u LaTeX-u",
            "explanation": "Kako se razlikuje od originalnog zadatka"
          },
          {...}
        ]
      }

      Pravila generiranja:
      1. Generiraj ukupno 10 zadataka:
         - 5 lakših od originala
         - 2 iste težine (samo s različitim brojevima)
         - 3 teža od originala
      
      2. Formatiranje:
         - LaTeX format za matematičke izraze
         - Koristi isti tip zadatka kao original (ako je jednadžba, generiraj jednadžbe)
         - Odgovarajuće varijacije težine
         
      3. Objašnjenja:
         - Kratko objasni po čemu je zadatak lakši ili teži od originala
         - Za slične zadatke navedi koje vrijednosti su promijenjene"""
      },
      {
        "role": "user",
        "content":
            """Generiraj slične zadatke za: ${_preprocessLatex(originalLatexExpression)}
        
        Molim te 10 zadataka prema pravilima:
        - 5 lakših
        - 2 ista zadatka s različitim brojevima
        - 3 teža zadatka
        
        Svi zadaci trebaju biti u LaTeX formatu i s objašnjenjem kako se razlikuju od originala.
        
        Odgovori samo s čistim JSON-om bez Markdown oznaka poput ```json. Ne koristi oznake koda."""
      }
    ];

    // tijelo zahtjeva
    final body = {
      "model": "gpt-4-turbo",
      "messages": messages,
      "max_tokens": 3000,
      "temperature": 0.7, // malo veća temperatura za raznolikost zadataka
    };

    try {
      // slanje zahtjeva
      final response =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      debugPrint(response.body);
      return _handleSimilarTasksResponse(response);
    } catch (e) {
      debugPrint('Request failed: $e');
      return null;
    }
  }

  // metoda za obradu odgovora za slične zadatke
  List<Map<String, String>>? _handleSimilarTasksResponse(
      http.Response response) {
    if (response.statusCode != 200) {
      debugPrint('API Error: ${response.statusCode}');
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseSimilarTasksContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  // metoda za parsiranje sadržaja odgovora za slične zadatke
  List<Map<String, String>>? _parseSimilarTasksContent(String content) {
    try {
      // Remove Markdown code block markers if present
      String cleanedContent = content;
      if (content.startsWith('```')) {
        final firstLineEnd = content.indexOf('\n');
        if (firstLineEnd != -1) {
          cleanedContent = content.substring(firstLineEnd + 1);
          if (cleanedContent.endsWith('```')) {
            cleanedContent =
                cleanedContent.substring(0, cleanedContent.length - 3);
          }
        }
      }

      cleanedContent = cleanedContent.trim();
      debugPrint('Cleaned JSON: $cleanedContent');

      final jsonData = jsonDecode(cleanedContent) as Map<String, dynamic>;
      final tasks = jsonData['similar_tasks'] as List<dynamic>;

      return tasks.map<Map<String, String>>((task) {
        final taskData = task as Map<String, dynamic>;

        // Print the raw task for debugging
        final rawTask = taskData['task']?.toString() ?? '';
        debugPrint('Raw task from JSON: $rawTask');

        return {
          'difficulty': _cleanText(taskData['difficulty']?.toString() ?? ''),
          'task': rawTask, // Use the raw LaTeX string directly
          'explanation': _cleanText(taskData['explanation']?.toString() ?? ''),
        };
      }).toList();
    } catch (e) {
      debugPrint('Content processing failed: $e');
      debugPrint('Raw content: $content');
      return null;
    }
  }

  // metoda za obradu odgovora API-ja
  List<Map<String, String>>? _handleApiResponse(http.Response response) {
    if (response.statusCode != 200) {
      debugPrint('API Error: ${response.statusCode}');
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content']?.trim() ?? '';
      return _parseContent(content);
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return null;
    }
  }

  // metoda za parsiranje sadržaja odgovora
  List<Map<String, String>>? _parseContent(String content) {
    try {
      final jsonData =
          jsonDecode(_sanitizeJson(content)) as Map<String, dynamic>;
      final steps = jsonData['steps'] as List<dynamic>;
      final finalAnswer = jsonData['final_answer'] as String?;

      final processedSteps = _processSteps(steps);

      if (finalAnswer != null) {
        processedSteps.add({
          'step': 'Konačno rješenje',
          'result': finalAnswer,
          'explanation': 'Konačni rezultat zadatka'
        });
      }

      return processedSteps;
    } catch (e) {
      debugPrint('Content processing failed: $e');
      return null;
    }
  }

  // metoda za sanitizaciju JSON-a
  String _sanitizeJson(String input) {
    return input
        .replaceAll(RegExp(r'(?<!\\)\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})'), '')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\\n'), '');
  }

  // metoda za obradu koraka
  List<Map<String, String>> _processSteps(List<dynamic> steps) {
    return steps.map<Map<String, String>>((step) {
      final stepData = step as Map<String, dynamic>;
      return {
        'step': _cleanText(stepData['step']?.toString() ?? ''),
        'result': _formatLatex(stepData['result']?.toString() ?? ''),
        'explanation': _cleanText(stepData['explanation']?.toString() ?? ''),
      };
    }).toList();
  }

  // metoda za čišćenje teksta od nepoznatih utf-8 znakova
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\\[n"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('Ä‡', 'č')
        .replaceAll('Å¡', 'š')
        .replaceAll('Å¾', 'ž');
  }

  // metoda za formatiranje LaTeX-a
  String _formatLatex(String latex) {
    return latex
        .replaceAll(RegExp(r'\$(.*?)\$'), r'\1')
        .replaceAll('*', r'\times ')
        .replaceAllMapped(RegExp(r'\\boxed{(.*?)}'), (m) => m.group(1)!)
        .replaceAllMapped(
            RegExp(r'\\begin{cases}(.*?)\\end{cases}'),
            (match) =>
                '\\begin{cases}${match.group(1)!.replaceAll(' ', ' \\\\ ')}\end{cases}');
  }

  // metoda za predobradu LaTeX-a
  String _preprocessLatex(String latex) {
    return latex
        .replaceAll(RegExp(r'\\[(){}]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
