import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _result = '';
  bool _loading = false;

  Future<void> _testApiKey() async {
    setState(() {
      _loading = true;
      _result = 'Test en cours...';
    });

    try {
      // Récupérer la clé API depuis le fichier .env
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
        setState(() {
          _loading = false;
          _result = 'Erreur: Clé API OpenAI non définie dans le fichier .env';
        });
        return;
      }

      // Afficher la clé partiellement masquée pour vérification
      final maskedKey = apiKey.substring(0, 5) + '...' + apiKey.substring(apiKey.length - 4);
      
      // Faire une requête simple à l'API OpenAI
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
              'content': 'Hello, testing my API key. Please respond with "API key working correctly!"'
            }
          ],
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        setState(() {
          _loading = false;
          _result = 'Test réussi! ✅\n\n'
              'Clé API utilisée: $maskedKey\n\n'
              'Réponse d\'OpenAI: $content';
        });
      } else {
        setState(() {
          _loading = false;
          _result = 'Erreur API: ${response.statusCode}\n'
              'Clé API utilisée: $maskedKey\n\n'
              'Réponse: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _result = 'Exception: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de l\'API OpenAI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce test vérifie que votre application peut récupérer la clé API OpenAI depuis le fichier .env et effectuer une requête API.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : _testApiKey,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Tester la connexion à OpenAI API'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}