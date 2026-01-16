import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appointment.dart';

class DBHelper {
  static Database? _database;
  static const int _databaseVersion = 3;

  static const String _petTableName = 'pets';
  static const String _vaccinationTableName = 'vaccinations';
  static const String _reminderTableName = 'reminders';
  static const String _weightTableName = 'weight_history';
  static const String _stockTableName = 'food_stocks';

  static final DBHelper instance = DBHelper._privateConstructor();
  DBHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'pet_tracker.db');

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _createDB,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {}
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_petTableName ADD COLUMN targetWeight REAL DEFAULT 0.0',
          );
          print("Veritabanı yükseltildi: targetWeight sütunu eklendi.");
        }
      },
    );
  }

  void _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_petTableName(
        id TEXT PRIMARY KEY,
        name TEXT,
        species TEXT,
        birthDate TEXT,
        gender TEXT,
        photoPath TEXT,
        foodStockKg REAL,
        isSterilized INTEGER,
        weight REAL,
        targetWeight REAL DEFAULT 0.0 -- 📍 BURAYI EKLEDİK
      )
    ''');

    await db.execute('''
  CREATE TABLE $_vaccinationTableName(
    id TEXT PRIMARY KEY,
    petId TEXT,
    name TEXT,
    date TEXT,
    isPeriodic INTEGER,
    periodMonths INTEGER,
    lastDoneDate TEXT, -- 📍 BURAYI EKLEDİĞİNİZDEN EMİN OLUN
    isArchived INTEGER DEFAULT 0,
    isCompleted INTEGER DEFAULT 0,
    notes TEXT
  )
''');

    await db.execute('''
      CREATE TABLE $_reminderTableName(
        id TEXT PRIMARY KEY,
        petId TEXT,
        title TEXT,
        date TEXT,
        type TEXT,
        isCompleted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_weightTableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId TEXT, -- String/UUID uyumu için TEXT
        weight REAL,
        date TEXT,
        note TEXT,
        FOREIGN KEY (petId) REFERENCES $_petTableName (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $_stockTableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId TEXT, -- BURASI ÖNEMLİ: INTEGER'dan TEXT'e çekildi
        currentStock REAL,
        lastUpdateDate TEXT,
        packageSize REAL,
        updatedAt TEXT,
        FOREIGN KEY (petId) REFERENCES $_petTableName (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
  CREATE TABLE appointments(
    id TEXT PRIMARY KEY,
    petId TEXT,
    title TEXT,
    date TEXT,
    type TEXT, -- 'vet', 'grooming', 'other'
    notes TEXT,
    FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
  )
''');
  }

  Future<Map<String, dynamic>?> getPetById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      _petTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertPet(Map<String, dynamic> petMap) async {
    final db = await database;

    return await db.insert(
      _petTableName,
      petMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPetsMapList() async {
    final db = await database;
    return await db.query(_petTableName, orderBy: 'id DESC');
  }

  Future<int> updatePet(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(
      _petTableName,
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deletePet(dynamic id) async {
    final db = await database;

    return await db.delete(
      _petTableName,
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> getWeightHistory(String petId) async {
    final db = await instance.database;
    return await db.query(
      _weightTableName,
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date ASC',
    );
  }

  Future<void> insertWeight(String petId, double weight) async {
    final db = await instance.database;
    await db.insert(_weightTableName, {
      'petId': petId,
      'weight': weight,
      'date': DateTime.now().toIso8601String(),
    });

    await db.update(
      _petTableName,
      {'weight': weight},
      where: 'id = ?',
      whereArgs: [petId],
    );
  }

  Future<int> deleteWeight(String id) async {
    final db = await instance.database;
    return await db.delete('weight_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePetWeight(String petId, double? weight) async {
    final db = await instance.database;
    return await db.update(
      'pets',
      {'weight': weight},
      where: 'id = ?',
      whereArgs: [petId],
    );
  }

  Future<Map<String, dynamic>?> getFoodStock(String petId) async {
    final db = await instance.database;
    final results = await db.query(
      _stockTableName,
      where: 'petId = ?',
      whereArgs: [petId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateFoodStock(
    String petId,
    double newAmount,
    double packageSize,
  ) async {
    final db = await instance.database;

    final existing = await getFoodStock(petId);

    final Map<String, dynamic> data = {
      'petId': petId,
      'currentStock': newAmount,
      'packageSize': packageSize,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existing == null) {
      await db.insert('food_stocks', data);
    } else {
      await db.update(
        'food_stocks',
        data,
        where: 'petId = ?',
        whereArgs: [petId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getVaccinationsByPet(String petId) async {
    Database db = await instance.database;
    return await db.query(
      _vaccinationTableName,
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllVaccinations() async {
    final db = await instance.database;

    return await db.query('vaccinations');
  }

  Future<int> insertVaccination(Map<String, dynamic> vaccinationMap) async {
    final db = await database;
    return await db.insert(
      _vaccinationTableName,
      vaccinationMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteVaccination(String id) async {
    final db = await instance.database;
    return await db.delete(
      _vaccinationTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateVaccination(Map<String, dynamic> vaccinationMap) async {
    final db = await database;
    return await db.update(
      _vaccinationTableName,
      vaccinationMap,
      where: 'id = ?',
      whereArgs: [vaccinationMap['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getRemindersByPet(String petId) async {
    final db = await database;
    return await db.query(
      _reminderTableName,
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'isCompleted ASC, date ASC',
    );
  }

  Future<int> insertReminder(Map<String, dynamic> reminderMap) async {
    final db = await database;
    return await db.insert(
      _reminderTableName,
      reminderMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> toggleVaccinationCompletion(
    String vaccinationId,
    bool isDone,
  ) async {
    final db = await database;
    return await db.update(
      _vaccinationTableName,
      {'isCompleted': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [vaccinationId],
    );
  }

  Future<int> toggleReminderCompletion(
    String reminderId,
    bool isCompleted,
  ) async {
    final db = await database;
    return await db.update(
      _reminderTableName,
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await instance.database;
    final result = await db.query('appointments', orderBy: 'date ASC');

    return result.map((json) => Appointment.fromMap(json)).toList();
  }

  Future<void> insertAppointment(Appointment appointment) async {
    final db = await instance.database;
    await db.insert('appointments', appointment.toMap());
  }

  Map<DateTime, List<dynamic>> _events = {};

  Future<int> deleteAppointment(String id) async {
    Database db = await instance.database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}
