import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'openia_service.dart';
import 'history_screen.dart';
import 'database_service.dart';
import 'firebase_test.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';

int? currentUserId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(" Firebase connecté avec succès !");
  } catch (e) {
    print(" Erreur détaillée de connexion Firebase : ${e.toString()}");
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      path: 'assets/lang',
      fallbackLocale: const Locale('fr'),
      child: const DaliliApp(),
    ),
  );
}

class DaliliApp extends StatelessWidget {
  const DaliliApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DALILI',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.teal,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  
  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final birthDate = _birthDateController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || birthDate.isEmpty) {
      setState(() {
        _error = "Veuillez remplir tous les champs";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Utilisation de Firebase Auth pour l'inscription
      final firebaseService = FirebaseService();
      final userCredential = await firebaseService.registerUser(email, password);
      
              // Stocker l'ID de l'utilisateur
        final user = userCredential.user;
        if (user != null) {
          // Convertir string en int ou utiliser string comme ID
          currentUserId = int.tryParse(user.uid) ?? 0; // Utiliser 0 comme ID par défaut si la conversion échoue
        
        // Enregistrer les informations supplémentaires dans Firestore
        await firebaseService.storeUserData(user.uid, {
          'name': name,
          'email': email,
          'birthDate': birthDate,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Enregistrement de l'activité
        await DatabaseService().insertActivity({
          'userId': currentUserId,
          'action': 'register',
          'details': 'Inscription réussie via Firebase',
          'createdAt': DateTime.now().toIso8601String(),
        });

        setState(() {
          _loading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SymptomsScreen(isAuthenticated: true)),
        );
      } else {
        throw Exception("Erreur d'inscription: aucun utilisateur créé");
      }
    } catch (e) {
      setState(() {
        _loading = false;
        
        // Messages d'erreur spécifiques pour Firebase Auth
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              _error = "Cet email est déjà utilisé";
              break;
            case 'invalid-email':
              _error = "Format d'email invalide";
              break;
            case 'weak-password':
              _error = "Le mot de passe est trop faible";
              break;
            case 'operation-not-allowed':
              _error = "La création de compte est désactivée";
              break;
            default:
              _error = "Erreur d'inscription: ${e.message}";
          }
        } else {
          _error = "Erreur de connexion: ${e.toString()}";
        }
      });
    }
  }


  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = "Veuillez remplir tous les champs";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://dalili-backend.onrender.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['user']['id'];
        
        // Enregistrement de l'activité localement
        if (currentUserId != null) {
          await DatabaseService().insertActivity({
            'userId': currentUserId,
            'action': 'login',
            'details': 'Connexion réussie via API',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
        
        setState(() {
          _loading = false;
        });
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SymptomsScreen(isAuthenticated: true)),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          _loading = false;
          _error = "Email ou mot de passe incorrect";
        });
      } else {
        setState(() {
          _loading = false;
          _error = "Erreur lors de la connexion: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Erreur de connexion au serveur: ${e.toString()}";
      });
    }
  }



  void _enterAsVisitor() {
    currentUserId = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SymptomsScreen(isAuthenticated: false)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo et titre
                Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.teal.shade700,
                ),
                SizedBox(height: 16),
                Text(
                  'DALILI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                Text(
                  'Aide médicale intelligente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal.shade600,
                  ),
                ),
                SizedBox(height: 48),

                // Formulaire d'authentification
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isLogin ? 'Connexion' : 'Inscription',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      SizedBox(height: 24),

                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _birthDateController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Date de naissance',
                            prefixIcon: Icon(Icons.calendar_today),
                            hintText: 'JJ/MM/AAAA',
                          ),
                          keyboardType: TextInputType.datetime,
                          readOnly: true,
                          onTap: () async {
                            // Pour masquer le clavier
                            FocusScope.of(context).requestFocus(FocusNode());
                            
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(Duration(days: 365 * 18)), // 18 ans par défaut
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.teal.shade600,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            
                            if (picked != null) {
                              // Formatez la date comme vous le souhaitez
                              final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                              // Mettez à jour le champ
                              setState(() {
                                _birthDateController.text = formattedDate;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : (_isLogin ? _login : _register),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isLogin ? 'Se connecter' : 'S\'inscrire'),
                        ),
                      ),
                      SizedBox(height: 16),

                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          _isLogin 
                              ? 'Pas de compte ? S\'inscrire' 
                              : 'Déjà un compte ? Se connecter',
                          style: TextStyle(color: Colors.teal.shade600),
                        ),
                      ),

                      if (_error != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Option visiteur
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _enterAsVisitor,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.teal.shade600),
                    ),
                    child: Text(
                      'Continuer en mode visiteur',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Mode visiteur : Aucun enregistrement des données',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SymptomsScreen extends StatefulWidget {
  final bool isAuthenticated;

  const SymptomsScreen({required this.isAuthenticated, Key? key}) : super(key: key);

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();

  String? _advice;
  bool _loading = false;
  String? _error;
  bool _hasDisease = false;
  String? _selectedProblemNature;
  
  final List<String> _problemNatures = [
    'Interne',
    'Externe', 
    'Dermatologie',
    'Respiratoire',
    'Neurologique'
  ];

  void _sendSymptoms() async {
    final symptoms = _controller.text.trim();
    final name = _nameController.text.trim();
    final country = _countryController.text.trim();
    final duration = _durationController.text.trim();
    final temperature = _temperatureController.text.trim();
    
    if (name.isEmpty || country.isEmpty || symptoms.isEmpty || 
        duration.isEmpty || temperature.isEmpty || _selectedProblemNature == null) {
      setState(() {
        _error = "Veuillez remplir tous les champs obligatoires";
      });
      return;
    }

    setState(() {
      _loading = true;
      _advice = null;
      _error = null;
    });

    try {
      // Construire le message avec les informations du formulaire
      String fullMessage = "Nom: $name\nPays: $country\n";
      if (_hasDisease && _diseaseController.text.trim().isNotEmpty) {
        fullMessage += "Maladie: ${_diseaseController.text.trim()}\n";
      }
      fullMessage += "Durée des symptômes: $duration\n";
      fullMessage += "Température corporelle: $temperature°C\n";
      fullMessage += "Nature du problème: $_selectedProblemNature\n";
      fullMessage += "Symptômes: $symptoms";
      
      final result = await _openAIService.getMedicalAdvice(fullMessage);
      setState(() {
        _advice = result;
      });
      
      // Si l'utilisateur est authentifié, on sauvegarde les données dans la base locale
      if (widget.isAuthenticated && currentUserId != null) {
        await DatabaseService().insertForm({
          'userId': currentUserId,
          'name': name,
          'country': country,
          'hasDisease': _hasDisease ? 1 : 0,
          'disease': _diseaseController.text.trim(),
          'duration': duration,
          'temperature': temperature,
          'problemNature': _selectedProblemNature,
          'symptoms': symptoms,
          'aiResponse': result,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await DatabaseService().insertActivity({
          'userId': currentUserId,
          'action': 'submit_form',
          'details': 'Formulaire envoyé',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur lors de la récupération du conseil médical";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _countryController.dispose();
    _diseaseController.dispose();
    _durationController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Formulaire médical'),
        actions: [
          // Indicateur de statut d'authentification
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.isAuthenticated ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isAuthenticated ? Icons.verified_user : Icons.person_outline,
                  size: 16,
                  color: widget.isAuthenticated ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  widget.isAuthenticated ? 'Connecté' : 'Visiteur',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isAuthenticated ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Bouton historique (authentifié seulement)
                        if (widget.isAuthenticated)
            IconButton(
              icon: Icon(Icons.history),
              tooltip: 'Historique',
              onPressed: () async {
                if (currentUserId != null) {
                  await DatabaseService().insertActivity({
                    'userId': currentUserId,
                    'action': 'view_history',
                    'details': 'Consultation de l\'historique',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
            ),
            // Bouton de test Firebase
            IconButton(
              icon: Icon(Icons.verified_outlined),
              tooltip: 'Test Firebase',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FirebaseTestScreen()),
                );
              },
            ),
          // 🌐 Icône de changement de langue
          PopupMenuButton<Locale>(
            icon: Icon(Icons.language),
            onSelected: (Locale locale) {
              context.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem<Locale>(
                value: Locale('en'),
                child: Text('English'),
              ),
              PopupMenuItem<Locale>(
                value: Locale('fr'),
                child: Text('Français'),
              ),
              PopupMenuItem<Locale>(
                value: Locale('ar'),
                child: Text('العربية'),
              ),
            ],
          ),
          // Bouton de déconnexion
          if (widget.isAuthenticated)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                if (currentUserId != null) {
                  await DatabaseService().insertActivity({
                    'userId': currentUserId,
                    'action': 'logout',
                    'details': 'Déconnexion',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                }
                currentUserId = null;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
              tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Consultation Médicale",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                ),
              ),
              SizedBox(height: 24),
              
              // Avertissement pour les visiteurs
              if (!widget.isAuthenticated) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mode visiteur : Vos données ne seront pas sauvegardées",
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              Divider(thickness: 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.teal.shade700),
                        SizedBox(width: 8),
                        Text(
                          "Identité du Patient",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text("Nom et prénom", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Votre nom complet',
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Pays", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    TextField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Votre pays de résidence',
                        prefixIcon: Icon(Icons.location_on),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Divider(thickness: 2),
              Container(
                margin: EdgeInsets.only(top: 20),
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          "Antécédents Médicaux",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text("Avez-vous des maladies chroniques ?", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _hasDisease,
                            activeColor: Colors.blue.shade700,
                            onChanged: (bool? value) {
                              setState(() {
                                _hasDisease = value ?? false;
                              });
                            },
                          ),
                          Text('Oui', style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 40),
                          Radio<bool>(
                            value: false,
                            groupValue: _hasDisease,
                            activeColor: Colors.blue.shade700,
                            onChanged: (bool? value) {
                              setState(() {
                                _hasDisease = value ?? false;
                              });
                            },
                          ),
                          Text('Non', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (_hasDisease) ...[
                      SizedBox(height: 16),
                      Text("Détail des maladies chroniques", style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      TextField(
                        controller: _diseaseController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Diabète, hypertension, asthme...',
                          prefixIcon: Icon(Icons.health_and_safety),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),
              Divider(thickness: 2),
            Container(
                margin: EdgeInsets.only(top: 20),
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.healing, color: Colors.red.shade700),
                        SizedBox(width: 8),
                        Text(
                          "Symptômes Actuels",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Durée des symptômes", style: TextStyle(fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              TextField(
                                controller: _durationController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  hintText: '3 jours, 1 semaine...',
                                  prefixIcon: Icon(Icons.schedule),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Température (°C)", style: TextStyle(fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              TextField(
                                controller: _temperatureController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  hintText: '37.5',
                                  prefixIcon: Icon(Icons.thermostat),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text("Catégorie des symptômes", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProblemNature,
                          hint: Text('Choisissez une catégorie'),
                          isExpanded: true,
                          items: _problemNatures.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedProblemNature = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Description détaillée des symptômes", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    TextField(
                      controller: _controller,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Décrivez tous vos symptômes, leur intensité et leur évolution...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 30, bottom: 10),
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendSymptoms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: _loading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.medical_information, size: 22),
                              SizedBox(width: 10),
                              Text('Analyser mes symptômes'),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              if (_advice != null) ...[
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: Colors.green.shade800, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Analyse & Conseil Médical",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 25, thickness: 1, color: Colors.green.shade200),
                      Text(
                        _advice!,
                        style: TextStyle(
                          fontSize: 16, 
                          height: 1.4,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "⚠️ Ce conseil est fourni à titre informatif et ne remplace pas l'avis d'un médecin.",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            if (_error != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          ),
        ),
      ),
    );
  }
}
