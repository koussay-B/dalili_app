import 'package:flutter/material.dart';
import 'openia_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final OpenAIService _openAIService = OpenAIService();
  bool _loading = false;
  String _resultTitle = '';
  String _resultDetails = '';
  bool _isSuccess = false;

  Future<void> _testApiConnection() async {
    setState(() {
      _loading = true;
      _resultTitle = 'Test en cours...';
      _resultDetails = '';
    });

    try {
      final result = await _openAIService.testApiKey();
      
      setState(() {
        _loading = false;
        _isSuccess = result['success'] == true;
        _resultTitle = result['message'];
        
        if (_isSuccess) {
          _resultDetails = '''
Clé API utilisée: ${result['maskedKey']}

Réponse d'OpenAI à "Hello": 
${result['response']}

✅ Votre configuration .env fonctionne correctement!
''';
        } else {
          _resultDetails = '''
Clé API: ${result['maskedKey'] ?? 'Non disponible'}

Erreur: ${result['response'] ?? 'Vérifiez votre fichier .env'}

❌ La configuration a échoué. Consultez lib/README_ENV_SETUP.md pour plus d'informations.
''';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _isSuccess = false;
        _resultTitle = 'Erreur inattendue';
        _resultDetails = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test API OpenAI'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ce test vérifie:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Si votre fichier .env est correctement chargé'),
                    const Text('2. Si la variable OPENAI_API_KEY est définie'),
                    const Text('3. Si la clé API peut se connecter à OpenAI'),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.api),
                        label: const Text('TESTER LA CONNEXION'),
                        onPressed: _loading ? null : _testApiConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Test en cours...'),
                  ],
                ),
              ),
            if (!_loading && _resultTitle.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 3,
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.error,
                              color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _resultTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_resultDetails),
                            ),
                          ),
                        ),
                      ],
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