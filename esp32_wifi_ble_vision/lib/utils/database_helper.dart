import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/wifi.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper; // Singleton DatabaseHelper
  static Database _database; // Singleton Database

  String wifiTable = 'wifi_table';
  String colId = 'id';
  String colSSID = 'SSID';
  String colPassword = 'Password';
  String colDate = 'date';

  DatabaseHelper._createInstance(); // Named constructor to create instance of DatabaseHelper

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper
          ._createInstance(); // This is executed only once, singleton object
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'wifi.db';

    // Open/create the database at a given path
    var wifiDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return wifiDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $wifiTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colSSID TEXT, '
        '$colPassword TEXT, $colDate TEXT)');
  }

  // Fetch Operation: Get all note objects from database
  Future<List<Map<String, dynamic>>> getWifiMapList() async {
    Database db = await this.database;

//		var result = await db.rawQuery('SELECT * FROM $noteTable order by $colPriority ASC');
    var result = await db.query(wifiTable, orderBy: '$colId ASC');
    return result;
  }

  // Insert Operation: Insert a Note object to database
  Future<int> insertWifi(Wifi wifi) async {
    Database db = await this.database;
    var result = await db.insert(wifiTable, wifi.toMap());
    return result;
  }

  // Update Operation: Update a Note object and save it to database
  Future<int> updateWifi(Wifi wifi) async {
    var db = await this.database;
    var result = await db.update(wifiTable, wifi.toMap(),
        where: '$colId = ?', whereArgs: [wifi.id]);
    return result;
  }

  // Delete Operation: Delete a Note object from database
  Future<int> deleteWifi(int id) async {
    var db = await this.database;
    int result =
        await db.rawDelete('DELETE FROM $wifiTable WHERE $colId = $id');
    return result;
  }

  // Get number of Note objects in database
  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT (*) from $wifiTable');
    int result = Sqflite.firstIntValue(x);
    return result;
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'Note List' [ List<Note> ]
  Future<List<Wifi>> getWifiList() async {
    var wifiMapList = await getWifiMapList(); // Get 'Map List' from database
    int count =
        wifiMapList.length; // Count the number of map entries in db table

    List<Wifi> wifiList = List<Wifi>();
    // For loop to create a 'Note List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      wifiList.add(Wifi.fromMapObject(wifiMapList[i]));
    }

    return wifiList;
  }
}
