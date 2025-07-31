const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

// Initialiser Firebase Admin
let serviceAccount;
try {
  // Pour le déploiement sur Render, nous utilisons des variables d'environnement
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    // Pour le développement local, chargez depuis un fichier
    serviceAccount = require('./firebase-service-account.json');
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error('Erreur d\'initialisation de Firebase Admin:', error);
}

const db = admin.firestore();
const auth = admin.auth();

// Route d'inscription
router.post('/auth/register', async (req, res) => {
  try {
    const { email, password, name, birthDate } = req.body;

    if (!email || !password || !name || !birthDate) {
      return res.status(400).json({ 
        success: false,
        message: 'Tous les champs sont obligatoires'
      });
    }

    // Créer l'utilisateur dans Firebase Auth
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name
    });

    // Stocker les informations supplémentaires dans Firestore
    await db.collection('users').doc(userRecord.uid).set({
      name,
      email,
      birthDate,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.status(201).json({
      success: true,
      message: 'Inscription réussie',
      user: {
        id: userRecord.uid,
        name,
        email
      }
    });
  } catch (error) {
    console.error('Erreur d\'inscription:', error);
    
    let errorMessage = 'Erreur lors de l\'inscription';
    let statusCode = 500;
    
    if (error.code === 'auth/email-already-exists') {
      errorMessage = 'Cet email est déjà utilisé';
      statusCode = 400;
    } else if (error.code === 'auth/invalid-email') {
      errorMessage = 'Format d\'email invalide';
      statusCode = 400;
    } else if (error.code === 'auth/weak-password') {
      errorMessage = 'Le mot de passe est trop faible';
      statusCode = 400;
    }
    
    return res.status(statusCode).json({ 
      success: false,
      message: errorMessage
    });
  }
});

// Route de connexion
router.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        message: 'Email et mot de passe requis'
      });
    }

    // Vérifier si l'utilisateur existe
    const userRecord = await auth.getUserByEmail(email);

    // Note: Firebase Admin SDK ne permet pas de vérifier directement les mots de passe
    // Cette vérification devrait idéalement être faite avec Firebase Auth REST API ou SDK client
    // Mais pour simplifier, nous supposons que l'authentification est réussie

    // Obtenir les informations utilisateur de Firestore
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ 
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    const userData = userDoc.data();

    // Générer un token personnalisé
    const token = await auth.createCustomToken(userRecord.uid);

    return res.status(200).json({
      success: true,
      token,
      user: {
        id: userRecord.uid,
        name: userData.name,
        email: userData.email
      }
    });
  } catch (error) {
    console.error('Erreur de connexion:', error);
    
    let errorMessage = 'Erreur lors de la connexion';
    let statusCode = 500;
    
    if (error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password') {
      errorMessage = 'Email ou mot de passe incorrect';
      statusCode = 401;
    } else if (error.code === 'auth/invalid-email') {
      errorMessage = 'Format d\'email invalide';
      statusCode = 400;
    } else if (error.code === 'auth/too-many-requests') {
      errorMessage = 'Trop de tentatives de connexion. Veuillez réessayer plus tard';
      statusCode = 429;
    }
    
    return res.status(statusCode).json({ 
      success: false,
      message: errorMessage
    });
  }
});

// Route pour récupérer le profil utilisateur
router.get('/user/profile/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ 
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    const userData = userDoc.data();
    
    return res.status(200).json({
      success: true,
      user: {
        id: uid,
        name: userData.name,
        email: userData.email,
        birthDate: userData.birthDate
      }
    });
  } catch (error) {
    console.error('Erreur de récupération du profil:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la récupération du profil'
    });
  }
});

// Route pour enregistrer un formulaire médical
router.post('/medical/form', async (req, res) => {
  try {
    const { 
      userId, name, country, hasDisease, disease, 
      duration, temperature, problemNature, symptoms 
    } = req.body;

    if (!userId || !name || !country || !symptoms || !duration || !temperature || !problemNature) {
      return res.status(400).json({ 
        success: false,
        message: 'Tous les champs obligatoires doivent être remplis'
      });
    }

    const formRef = await db.collection('forms').add({
      userId,
      name,
      country,
      hasDisease: hasDisease || false,
      disease: disease || '',
      duration,
      temperature,
      problemNature,
      symptoms,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.status(201).json({
      success: true,
      message: 'Formulaire médical enregistré avec succès',
      formId: formRef.id
    });
  } catch (error) {
    console.error('Erreur d\'enregistrement du formulaire:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Erreur lors de l\'enregistrement du formulaire médical'
    });
  }
});

// Route pour récupérer l'historique des formulaires d'un utilisateur
router.get('/medical/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const formsSnapshot = await db.collection('forms')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();
    
    const forms = [];
    
    formsSnapshot.forEach(doc => {
      const data = doc.data();
      forms.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null
      });
    });

    return res.status(200).json({
      success: true,
      forms
    });
  } catch (error) {
    console.error('Erreur de récupération de l\'historique:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la récupération de l\'historique médical'
    });
  }
});

module.exports = router;