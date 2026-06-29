import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/auction_item.dart';
import '../models/item_photo.dart';
import '../services/financing_calculator.dart';

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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        credit_number $textNullable,
        name $textType,
        category_id $intType,
        weight_gram $doubleType,
        karat $textNullable,
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

    await db.execute('''
      CREATE TABLE gold_prices (
        id $idType,
        price_per_gram REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE financing_config (
        id $idType,
        dp_options TEXT NOT NULL DEFAULT '15,25,35,50',
        stl_price REAL NOT NULL DEFAULT 502894,
        hdle_price REAL NOT NULL DEFAULT 550000,
        loan_ratio REAL NOT NULL DEFAULT 0.95,
        admin_fee_flat REAL NOT NULL DEFAULT 15000,
        admin_fee_percent REAL NOT NULL DEFAULT 0,
        munah_rate REAL NOT NULL DEFAULT 0.38,
        um_percentage_kca REAL NOT NULL DEFAULT 0.192,
        um_percentage_krasida REAL NOT NULL DEFAULT 0.185,
        bunga_kca REAL NOT NULL DEFAULT 0.0125,
        tempo_kca INTEGER NOT NULL DEFAULT 4,
        minimum_up_kca INTEGER NOT NULL DEFAULT 500000,
        minimum_up_krasida INTEGER NOT NULL DEFAULT 500000,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE financing_tenors (
        id $idType,
        config_id INTEGER NOT NULL,
        months INTEGER NOT NULL,
        multiplier REAL NOT NULL DEFAULT 1,
        bunga_flat REAL NOT NULL DEFAULT 0.0125,
        is_active INTEGER NOT NULL DEFAULT 1,
        other_fee REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (config_id) REFERENCES financing_config (id)
      )
    ''');

    // Insert default categories
    await db.insert('categories', {
      'name': 'Perhiasan Emas',
      'description': 'Berbagai perhiasan emas murni maupun campuran',
    });
    await db.insert('categories', {
      'name': 'Elektronik',
      'description': 'Gadget, laptop, dan elektronik lainnya',
    });
    await db.insert('categories', {
      'name': 'Logam Mulia',
      'description': 'Emas batangan antam/UBS',
    });
    await db.insert('categories', {
      'name': 'Kendaraan',
      'description': 'Mobil, motor, dan kendaraan lainnya',
    });

    // Insert default gold price
    await db.insert('gold_prices', {
      'price_per_gram': 1120000,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default financing config
    final configId = await db.insert('financing_config', {
      'dp_options': '15,25,35,50',
      'stl_price': 502894,
      'hdle_price': 550000,
      'loan_ratio': 0.95,
      'admin_fee_flat': 15000,
      'admin_fee_percent': 0,
      'munah_rate': 0.38,
      'um_percentage_kca': 0.192,
      'um_percentage_krasida': 0.185,
      'bunga_kca': 0.0125,
      'tempo_kca': 4,
      'minimum_up_kca': 500000,
      'minimum_up_krasida': 500000,
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default tenors
    final defaultBunga = {
      6: 0.0125,
      12: 0.0125,
      18: 0.0130,
      24: 0.0130,
      36: 0.0140,
    };
    for (final entry in _defaultTenorMultipliers.entries) {
      await db.insert('financing_tenors', {
        'config_id': configId,
        'months': entry.key,
        'multiplier': entry.value,
        'bunga_flat': defaultBunga[entry.key] ?? 0.0125,
        'is_active': 1,
        'other_fee': 0,
      });
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gold_prices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          price_per_gram REAL NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS financing_config (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dp_options TEXT NOT NULL DEFAULT '15,25,35,50',
          admin_fee_flat REAL NOT NULL DEFAULT 50000,
          admin_fee_percent REAL NOT NULL DEFAULT 0,
          munah_rate REAL NOT NULL DEFAULT 0.38,
          is_active INTEGER NOT NULL DEFAULT 1,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS financing_tenors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          config_id INTEGER NOT NULL,
          months INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          other_fee REAL NOT NULL DEFAULT 0,
          FOREIGN KEY (config_id) REFERENCES financing_config (id)
        )
      ''');

      // Add Kendaraan category if not exists
      final existing = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: ['Kendaraan'],
      );
      if (existing.isEmpty) {
        await db.insert('categories', {
          'name': 'Kendaraan',
          'description': 'Mobil, motor, dan kendaraan lainnya',
        });
      }

      // Insert default gold price if empty
      final goldPrices = await db.query('gold_prices');
      if (goldPrices.isEmpty) {
        await db.insert('gold_prices', {
          'price_per_gram': 1120000,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Insert default financing config if empty
      final configs = await db.query('financing_config');
      if (configs.isEmpty) {
        final configId = await db.insert('financing_config', {
          'dp_options': '15,25,35,50',
          'admin_fee_flat': 50000,
          'admin_fee_percent': 0,
          'munah_rate': 0.38,
          'is_active': 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
        for (final months in [6, 12, 18, 24, 36]) {
          await db.insert('financing_tenors', {
            'config_id': configId,
            'months': months,
            'is_active': 1,
            'other_fee': 0,
          });
        }
      }
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'auction_items', 'credit_number', 'TEXT');
      await _addColumnIfMissing(
        db,
        'financing_config',
        'stl_price',
        'REAL NOT NULL DEFAULT 502894',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'hdle_price',
        'REAL NOT NULL DEFAULT 550000',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'loan_ratio',
        'REAL NOT NULL DEFAULT 0.95',
      );
      await _addColumnIfMissing(
        db,
        'financing_tenors',
        'multiplier',
        'REAL NOT NULL DEFAULT 1',
      );

      for (final entry in _defaultTenorMultipliers.entries) {
        await db.update(
          'financing_tenors',
          {'multiplier': entry.value},
          where: 'months = ?',
          whereArgs: [entry.key],
        );
      }
    }
    if (oldVersion < 4) {
      // Add KCA and KRASIDA new fields to financing_config
      await _addColumnIfMissing(
        db,
        'financing_config',
        'um_percentage_kca',
        'REAL NOT NULL DEFAULT 0.192',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'um_percentage_krasida',
        'REAL NOT NULL DEFAULT 0.185',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'bunga_kca',
        'REAL NOT NULL DEFAULT 0.0125',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'tempo_kca',
        'INTEGER NOT NULL DEFAULT 4',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'minimum_up_kca',
        'INTEGER NOT NULL DEFAULT 500000',
      );
      await _addColumnIfMissing(
        db,
        'financing_config',
        'minimum_up_krasida',
        'INTEGER NOT NULL DEFAULT 500000',
      );

      // Add bunga_flat to financing_tenors
      await _addColumnIfMissing(
        db,
        'financing_tenors',
        'bunga_flat',
        'REAL NOT NULL DEFAULT 0.0125',
      );

      // Update existing admin_fee_flat to 15000 if it was the default 50000
      await db.update(
        'financing_config',
        {'admin_fee_flat': 15000},
        where: 'admin_fee_flat = ?',
        whereArgs: [50000],
      );

      // Update bunga_flat for tenors
      final defaultBunga = {
        6: 0.0125,
        12: 0.0125,
        18: 0.0130,
        24: 0.0130,
        36: 0.0140,
      };
      for (final entry in defaultBunga.entries) {
        await db.update(
          'financing_tenors',
          {'bunga_flat': entry.value},
          where: 'months = ?',
          whereArgs: [entry.key],
        );
      }
    }
    if (oldVersion < 5) {
      // v5: Hapus seluruh skema lama (termasuk kolom 'condition' legacy)
      // dan buat ulang dari awal agar bersih.
      // Data lama akan hilang — ini disengaja untuk menghapus schema yang tidak sinkron.
      await db.execute('DROP TABLE IF EXISTS financing_tenors');
      await db.execute('DROP TABLE IF EXISTS financing_config');
      await db.execute('DROP TABLE IF EXISTS item_photos');
      await db.execute('DROP TABLE IF EXISTS auction_items');
      await db.execute('DROP TABLE IF EXISTS gold_prices');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion);
    }
  }

  static const Map<int, double> _defaultTenorMultipliers = {
    6: 1.075,
    12: 1.15,
    18: 1.234,
    24: 1.312,
    36: 1.504,
  };

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // --- Categories ---
  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase().trim()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  // --- Auction Items ---
  Future<int> createAuctionItem(AuctionItem item) async {
    final db = await instance.database;
    return await db.insert('auction_items', item.toMap());
  }

  Future<List<int>> createAuctionItemsBatch(List<AuctionItem> items) async {
    final db = await instance.database;
    final ids = <int>[];

    await db.transaction((txn) async {
      for (final item in items) {
        final id = await txn.insert('auction_items', item.toMap());
        ids.add(id);
      }
    });

    return ids;
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

  Future<List<AuctionItem>> readAllAuctionItems({
    bool activeOnly = false,
  }) async {
    final db = await instance.database;

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

  Future<List<AuctionItem>> readAuctionItemsByCreditNumber(
    String creditNumber, {
    bool activeOnly = true,
  }) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT a.*, c.name as category_name
      FROM auction_items a
      LEFT JOIN categories c ON a.category_id = c.id
      WHERE a.credit_number = ?
      ${activeOnly ? "AND a.is_active = 1" : ""}
      ORDER BY a.created_at ASC
    ''',
      [creditNumber],
    );

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
    // Also delete photos
    await db.delete('item_photos', where: 'item_id = ?', whereArgs: [id]);
    return await db.delete('auction_items', where: 'id = ?', whereArgs: [id]);
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
    return await db.delete('item_photos', where: 'id = ?', whereArgs: [id]);
  }

  // --- Gold Prices ---
  Future<double> getGoldPricePerGram() async {
    final db = await instance.database;
    final result = await db.query('gold_prices', orderBy: 'id DESC', limit: 1);
    if (result.isNotEmpty) {
      return (result.first['price_per_gram'] as num).toDouble();
    }
    return 1120000; // Default
  }

  Future<Map<String, dynamic>?> getLatestGoldPriceRecord() async {
    final db = await instance.database;
    final result = await db.query('gold_prices', orderBy: 'id DESC', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateGoldPrice(double pricePerGram) async {
    final db = await instance.database;
    return await db.insert('gold_prices', {
      'price_per_gram': pricePerGram,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all gold-category items with auto-calculated price
  Future<List<Map<String, dynamic>>> getGoldItemsWithCalculatedPrice() async {
    final db = await instance.database;
    final goldPrice = await getGoldPricePerGram();

    final result = await db.rawQuery('''
      SELECT a.*, c.name as category_name
      FROM auction_items a
      LEFT JOIN categories c ON a.category_id = c.id
      WHERE c.name LIKE '%Emas%' OR c.name LIKE '%Logam Mulia%'
      ORDER BY a.name ASC
    ''');

    return result.map((row) {
      final weightGram = (row['weight_gram'] as num).toDouble();
      // Bug A fix: gunakan karat dalam kalkulasi, bukan sekadar berat × harga
      final karatVal = FinancingCalculator.parseKarat(row['karat'] as String?);
      final calculatedPrice = FinancingCalculator.hitungHargaEmas(
        hdlePrice: goldPrice,
        weightGram: weightGram,
        karatVal: karatVal > 0 ? karatVal : 24.0,
      );
      return {
        ...row,
        'calculated_price': calculatedPrice,
        'gold_price_per_gram': goldPrice,
      };
    }).toList();
  }

  /// Update base_price of gold items based on current gold price
  Future<void> recalculateGoldItemPrices() async {
    final db = await instance.database;
    final goldPrice = await getGoldPricePerGram();

    // Get gold categories
    final goldCategories = await db.rawQuery('''
      SELECT id FROM categories 
      WHERE name LIKE '%Emas%' OR name LIKE '%Logam Mulia%'
    ''');

    final categoryIds = goldCategories.map((c) => c['id']).toList();
    if (categoryIds.isEmpty) return;

    final placeholders = categoryIds.map((_) => '?').join(',');
    final items = await db.rawQuery(
      'SELECT id, weight_gram, karat FROM auction_items WHERE category_id IN ($placeholders)',
      categoryIds,
    );

    for (final item in items) {
      final weight = (item['weight_gram'] as num).toDouble();
      final karatStr = item['karat'] as String?;

      // Bug B fix: gunakan parseKarat terpusat, bukan inline regex duplikat
      final karatVal = FinancingCalculator.parseKarat(karatStr);
      final effectiveKarat = karatVal > 0 ? karatVal : 24.0;

      final newPrice = FinancingCalculator.hitungHargaEmas(
        hdlePrice: goldPrice,
        weightGram: weight,
        karatVal: effectiveKarat,
      );
      await db.update(
        'auction_items',
        {'base_price': newPrice.toDouble()},
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
  }

  // --- Financing Config ---
  Future<Map<String, dynamic>?> getActiveFinancingConfig() async {
    final db = await instance.database;
    final result = await db.query(
      'financing_config',
      where: 'is_active = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<Map<String, dynamic>?> getLatestFinancingConfig() async {
    final db = await instance.database;
    final result = await db.query(
      'financing_config',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getFinancingTenors(int configId) async {
    final db = await instance.database;
    return await db.query(
      'financing_tenors',
      where: 'config_id = ?',
      whereArgs: [configId],
      orderBy: 'months ASC',
    );
  }

  Future<void> saveFinancingConfig({
    required String dpOptions,
    required double adminFeeFlat,
    required double adminFeePercent,
    required double munahRate,
    required bool isActive,
    required List<Map<String, dynamic>> tenors,
    double stlPrice = 502894,
    double hdlePrice = 550000,
    double loanRatio = 0.95,
    double umPercentageKca = 0.192,
    double umPercentageKrasida = 0.185,
    double bungaKca = 0.0125,
    int tempoKca = 4,
    int minimumUpKca = 500000,
    int minimumUpKrasida = 500000,
  }) async {
    final db = await instance.database;

    // Deactivate old configs
    await db.update('financing_config', {'is_active': 0});

    final configId = await db.insert('financing_config', {
      'dp_options': dpOptions,
      'stl_price': stlPrice,
      'hdle_price': hdlePrice,
      'loan_ratio': loanRatio,
      'admin_fee_flat': adminFeeFlat,
      'admin_fee_percent': adminFeePercent,
      'munah_rate': munahRate,
      'um_percentage_kca': umPercentageKca,
      'um_percentage_krasida': umPercentageKrasida,
      'bunga_kca': bungaKca,
      'tempo_kca': tempoKca,
      'minimum_up_kca': minimumUpKca,
      'minimum_up_krasida': minimumUpKrasida,
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    for (final tenor in tenors) {
      await db.insert('financing_tenors', {
        'config_id': configId,
        'months': tenor['months'],
        'multiplier':
            tenor['multiplier'] ??
            _defaultTenorMultipliers[tenor['months']] ??
            1.0,
        'bunga_flat': tenor['bunga_flat'] ??
            {
              6: 0.0125,
              12: 0.0125,
              18: 0.0130,
              24: 0.0130,
              36: 0.0140,
            }[tenor['months']] ??
            0.0125,
        'is_active': tenor['is_active'] ?? 1,
        'other_fee': tenor['other_fee'] ?? 0,
      });
    }
  }

  // --- Stats ---
  Future<int> getActiveItemCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM auction_items WHERE is_active = 1',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>?> getTopCategory() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT c.name, COUNT(a.id) as cnt 
      FROM auction_items a 
      JOIN categories c ON a.category_id = c.id 
      WHERE a.is_active = 1
      GROUP BY c.name 
      ORDER BY cnt DESC 
      LIMIT 1
    ''');
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getRecentItems({int limit = 3}) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT a.*, c.name as category_name
      FROM auction_items a
      LEFT JOIN categories c ON a.category_id = c.id
      ORDER BY a.created_at DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<double> getTotalBasePrice() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(base_price) as total FROM auction_items WHERE is_active = 1',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT c.name, COUNT(a.id) as cnt, SUM(a.base_price) as total_value
      FROM auction_items a
      JOIN categories c ON a.category_id = c.id
      WHERE a.is_active = 1
      GROUP BY c.name
      ORDER BY cnt DESC
    ''');
  }

  // --- Backup ---
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'katalog_lelang.db');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
