import 'package:flutter/material.dart';
import 'firebase_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = "En attente de test...";
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = "Test en cours...\n";
    });

    try {
      // Teste l'initialisation de Firebase
      try {
        await _firebaseService.initialize();
        setState(() {
          _status += "Firebase Core initialisé avec succès ✓\n";
        });
      } catch (e) {
        setState(() {
          _status += "Erreur d'initialisation Firebase Core: $e ✗\n";
          return;
        });
      }

      // Teste Firebase Auth
      final authSuccess = await _firebaseService.testAuthConnection();
      setState(() {
        if (authSuccess) {
          _status += "Firebase Auth fonctionne correctement ✓\n";
          _status += "\nConnexion Firebase réussie ✓";
        } else {
          _status += "Problème avec Firebase Auth ✗\n";
          _status += "\nLa connexion Firebase a échoué ✗";
        }
      });
    } catch (e) {
      setState(() {
        _status += "Erreur lors du test: $e ✗\n";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test de Connexion Firebase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Test de Connectivité Firebase',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _status.contains("✗") 
                        ? Colors.red.shade50 
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _status.contains("✗") 
                          ? Colors.red.shade300 
                          : Colors.green.shade300,
                    ),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: _status.contains("✗") 
                          ? Colors.red.shade800 
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _testFirebaseConnection,
                child: Text('Tester à nouveau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 