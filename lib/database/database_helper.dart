import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/auction_item.dart';
import '../models/item_photo.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('katalog_lelang.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        description $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE auction_items (
        id $idType,
        name $textType,
        category_id $intType,
        weight_gram $doubleType,
        karat $textNullable,
        condition $textType,
        base_price $doubleType,
        description $textNullable,
        is_active $boolType,
        created_at $textNullable,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE item_photos (
        id $idType,
        item_id $intType,
        local_path $textType,
        is_primary $boolType,
        sort_order $intType,
        FOREIGN KEY (item_id) REFERENCES auction_items (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'Perhiasan Emas', 'description': 'Berbagai perhiasan emas murni maupun campuran'});
    await db.insert('categories', {'name': 'Elektronik', 'description': 'Gadget, laptop, dan elektronik lainnya'});
    await db.insert('categories', {'name': 'Logam Mulia', 'description': 'Emas batangan antam/UBS'});
  }

  // --- Categories ---
  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // --- Auction Items ---
  Future<int> createAuctionItem(AuctionItem item) async {
    final db = await instance.database;
    return await db.insert('auction_items', item.toMap());
  }

  Future<AuctionItem> readAuctionItem(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'auction_items',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AuctionItem.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<AuctionItem>> readAllAuctionItems({bool activeOnly = false}) async {
    final db = await instance.database;
    final whereClause = activeOnly ? 'is_active = 1' : null;
    
    // Join with categories to get category name
    final result = await db.rawQuery('''
      SELECT a.*, c.name as category_name
      FROM auction_items a
      LEFT JOIN categories c ON a.category_id = c.id
      ${activeOnly ? "WHERE a.is_active = 1" : ""}
      ORDER BY a.created_at DESC
    ''');

    return result.map((json) {
      var item = AuctionItem.fromMap(json);
      item.categoryName = json['category_name'] as String?;
      return item;
    }).toList();
  }

  Future<int> updateAuctionItem(AuctionItem item) async {
    final db = await instance.database;
    return db.update(
      'auction_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteAuctionItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'auction_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Photos ---
  Future<int> createItemPhoto(ItemPhoto photo) async {
    final db = await instance.database;
    return await db.insert('item_photos', photo.toMap());
  }

  Future<List<ItemPhoto>> readItemPhotos(int itemId) async {
    final db = await instance.database;
    final result = await db.query(
      'item_photos',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'sort_order ASC',
    );
    return result.map((json) => ItemPhoto.fromMap(json)).toList();
  }

  Future<int> deleteItemPhoto(int id) async {
    final db = await instance.database;
    return await db.delete(
      'item_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
