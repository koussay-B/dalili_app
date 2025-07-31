import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  // Récupérer la clé API depuis le fichier .env
  String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Méthode pour tester la clé API avec un simple prompt
  Future<Map<String, dynamic>> testApiKey() async {
    try {
      if (apiKey.isEmpty) {
        return {
          'success': false,
          'message': 'Clé API non définie dans le fichier .env'
        };
      }
      
      // Masquer la clé API pour l'affichage sécurisé
      final maskedKey = apiKey.length > 10 
          ? '${apiKey.substring(0, 5)}...${apiKey.substring(apiKey.length - 4)}'
          : 'Clé invalide';
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': 'Hello'
            }
          ],
          'max_tokens': 50,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return {
          'success': true,
          'message': 'Connexion à l\'API OpenAI réussie',
          'maskedKey': maskedKey,
          'response': content
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur API: ${response.statusCode}',
          'maskedKey': maskedKey,
          'response': response.body
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: ${e.toString()}',
      };
    }
  }

  // Méthode principale pour obtenir des conseils médicaux
  Future<String> getMedicalAdvice(String symptoms) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'user',
          'content':
              'Je ressens les symptômes suivants: $symptoms. Que devrais-je faire? Donne-moi des conseils médicaux généraux.'
        }
      ],
      'max_tokens': 300,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Erreur API OpenAI: ${response.statusCode}');
    }
  }
}