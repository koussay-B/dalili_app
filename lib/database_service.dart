import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dalili_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE forms(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            name TEXT,
            age TEXT,
            country TEXT,
            hasDisease INTEGER,
            disease TEXT,
            duration TEXT,
            temperature TEXT,
            problemNature TEXT,
            symptoms TEXT,
            aiResponse TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            action TEXT,
            details TEXT,
            createdAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              email TEXT UNIQUE,
              password TEXT,
              createdAt TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activities(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              action TEXT,
              details TEXT,
              createdAt TEXT
            )
          ''');
          await db.execute('''
            ALTER TABLE forms ADD COLUMN userId INTEGER
          ''');
        }
      },
    );
  }

  // USERS
  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // FORMS
  Future<int> insertForm(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('forms', data);
  }

  Future<List<Map<String, dynamic>>> getForms({int? userId}) async {
    final db = await database;
    if (userId != null) {
      return await db.query('forms', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    }
    return await db.query('forms', orderBy: 'createdAt DESC');
  }

  Future<void> clearForms() async {
    final db = await database;
    await db.delete('forms');
  }

  // ACTIVITIES
  Future<int> insertActivity(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('activities', data);
  }

  Future<List<Map<String, dynamic>>> getActivities({int? userId}) async {
    final db = await database;
    if (userId != null) {
      return await db.query('activities', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    }
    return await db.query('activities', orderBy: 'createdAt DESC');
  }
} 