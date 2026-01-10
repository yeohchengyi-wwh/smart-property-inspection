import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:smartpropertyinspection/model/inspection.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inspections.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Creating the table exactly as requested
    await db.execute('''
    CREATE TABLE tbl_inspections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      property_name TEXT,
      description TEXT,
      rating TEXT,
      latitude REAL,
      longitude REAL,
      date_created TEXT,
      photos TEXT
    )
    ''');
  }

  // CREATE
  Future<int> create(Inspection inspection) async {
    final db = await instance.database;
    return await db.insert('tbl_inspections', inspection.toMap());
  }

  // READ ALL (Sorted by Newest First)
  Future<List<Inspection>> readAllInspections() async {
    final db = await instance.database;
    final result = await db.query('tbl_inspections', orderBy: 'date_created DESC');
    return result.map((json) => Inspection.fromMap(json)).toList();
  }

  // UPDATE
  Future<int> update(Inspection inspection) async {
    final db = await instance.database;
    return await db.update(
      'tbl_inspections',
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tbl_inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}