import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  bool _initialized = false;
  
  /// Initialise Firebase
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('Firebase initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de Firebase: $e');
      rethrow;
    }
  }
  
  /// Vérifie si Firebase est initialisé
  bool get isInitialized => _initialized;
  
  /// Obtient l'instance de FirebaseAuth
  FirebaseAuth get auth => FirebaseAuth.instance;
  
  /// Test de connexion anonyme pour vérifier l'accès à Auth
  Future<bool> testAuthConnection() async {
    try {
      if (!_initialized) await initialize();
      
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (userCredential.user != null) {
        await FirebaseAuth.instance.signOut();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors du test de connexion Auth: $e');
      return false;
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<UserCredential> registerUser(String email, String password) async {
    try {
      if (!_initialized) await initialize();
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Connexion d'un utilisateur existant
  Future<UserCredential> loginUser(String email, String password) async {
    try {
      if (!_initialized) await initialize();
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  /// Stockage des informations supplémentaires de l'utilisateur dans Firestore
  Future<void> storeUserData(String uid, Map<String, dynamic> userData) async {
    try {
      if (!_initialized) await initialize();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erreur lors du stockage des données: $e');
      rethrow;
    }
  }

  /// Récupération des informations d'un utilisateur
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      if (!_initialized) await initialize();
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données: $e');
      rethrow;
    }
  }
}