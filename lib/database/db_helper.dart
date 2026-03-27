// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DbHelper {
  static final DbHelper _instance = DbHelper._();
  factory DbHelper() => _instance;
  DbHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'patisserie.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        unite TEXT NOT NULL DEFAULT 'kg',
        stock_actuel REAL NOT NULL DEFAULT 0,
        stock_min REAL NOT NULL DEFAULT 0,
        prix_unitaire REAL NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE produits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        prix_vente REAL NOT NULL DEFAULT 0,
        description TEXT,
        categorie TEXT DEFAULT 'Autres',
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE recettes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produit_id INTEGER NOT NULL,
        ingredient_id INTEGER NOT NULL,
        quantite_100 REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
        UNIQUE(produit_id, ingredient_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE commandes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client TEXT NOT NULL,
        telephone TEXT,
        date_livraison TEXT,
        statut TEXT NOT NULL DEFAULT 'en_cours',
        notes TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE lignes_commande (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id INTEGER NOT NULL,
        produit_id INTEGER NOT NULL,
        nb_pieces REAL NOT NULL DEFAULT 0,
        prix_unitaire REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE CASCADE,
        FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE achats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient_id INTEGER NOT NULL,
        quantite REAL NOT NULL DEFAULT 0,
        prix_total REAL NOT NULL DEFAULT 0,
        fournisseur TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_commandes_statut ON commandes(statut);
    ''');
    await db.execute('''
      CREATE INDEX idx_commandes_date ON commandes(created_at);
    ''');
    await db.execute('''
      CREATE INDEX idx_achats_date ON achats(created_at);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE produits ADD COLUMN categorie TEXT DEFAULT 'Autres'");
      } catch (_) {}
    }
  }

  // ── INGREDIENTS ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getIngredients({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      return db.query('ingredients',
        where: 'nom LIKE ?', whereArgs: ['%$search%'], orderBy: 'nom');
    }
    return db.query('ingredients', orderBy: 'nom');
  }

  Future<int> addIngredient(String nom, String unite, double stock,
      double stockMin, double prix) async {
    final db = await database;
    return db.insert('ingredients', {
      'nom': nom, 'unite': unite, 'stock_actuel': stock,
      'stock_min': stockMin, 'prix_unitaire': prix,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> updateIngredient(int id, String nom, String unite,
      double stock, double stockMin, double prix) async {
    final db = await database;
    await db.update('ingredients', {
      'nom': nom, 'unite': unite, 'stock_actuel': stock,
      'stock_min': stockMin, 'prix_unitaire': prix,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(int id, double delta) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ingredients SET stock_actuel = stock_actuel + ? WHERE id = ?',
      [delta, id]);
  }

  Future<void> deleteIngredient(int id) async {
    final db = await database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getStockAlerts() async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM ingredients WHERE stock_actuel <= stock_min ORDER BY (stock_actuel - stock_min) ASC'
    );
  }

  // ── PRODUITS ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProduits({String? categorie}) async {
    final db = await database;
    if (categorie != null) {
      return db.query('produits', where: 'categorie = ?', whereArgs: [categorie], orderBy: 'nom');
    }
    return db.query('produits', orderBy: 'nom');
  }

  Future<int> addProduit(String nom, double prix, String? desc, String? cat) async {
    final db = await database;
    return db.insert('produits', {
      'nom': nom, 'prix_vente': prix,
      'description': desc, 'categorie': cat ?? 'Autres',
    });
  }

  Future<void> updateProduit(int id, String nom, double prix,
      String? desc, String? cat) async {
    final db = await database;
    await db.update('produits', {
      'nom': nom, 'prix_vente': prix,
      'description': desc, 'categorie': cat ?? 'Autres',
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduit(int id) async {
    final db = await database;
    await db.delete('produits', where: 'id = ?', whereArgs: [id]);
  }

  // ── RECETTES ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecette(int produitId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT r.*, i.nom as ingredient_nom, i.unite, i.stock_actuel
      FROM recettes r
      JOIN ingredients i ON r.ingredient_id = i.id
      WHERE r.produit_id = ?
    ''', [produitId]);
  }

  Future<void> setRecetteLigne(int produitId, int ingredientId, double qte) async {
    final db = await database;
    if (qte <= 0) {
      await db.delete('recettes',
        where: 'produit_id = ? AND ingredient_id = ?',
        whereArgs: [produitId, ingredientId]);
    } else {
      await db.insert('recettes', {
        'produit_id': produitId, 'ingredient_id': ingredientId, 'quantite_100': qte,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ── COMMANDES ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommandes({
    String? statut, String? dateDebut, String? dateFin,
    String? search, int limit = 200,
  }) async {
    final db = await database;
    final conds = <String>[];
    final args  = <dynamic>[];
    if (statut != null) { conds.add("statut = ?"); args.add(statut); }
    if (dateDebut != null) { conds.add("date(created_at) >= ?"); args.add(dateDebut); }
    if (dateFin   != null) { conds.add("date(created_at) <= ?"); args.add(dateFin); }
    if (search != null && search.isNotEmpty) {
      conds.add("(client LIKE ? OR telephone LIKE ?)");
      args.addAll(['%$search%', '%$search%']);
    }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    return db.rawQuery(
      'SELECT * FROM commandes $where ORDER BY created_at DESC LIMIT $limit', args);
  }

  Future<Map<String, dynamic>?> getCommande(int id) async {
    final db = await database;
    final rows = await db.query('commandes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getLignesCommande(int commandeId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT lc.*, p.nom as produit_nom, p.categorie
      FROM lignes_commande lc
      JOIN produits p ON lc.produit_id = p.id
      WHERE lc.commande_id = ?
    ''', [commandeId]);
  }

  Future<double> getTotalCommande(int id) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(nb_pieces * prix_unitaire) as total FROM lignes_commande WHERE commande_id = ?',
      [id]);
    return (res.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> addCommande(String client, String? tel, String? dateLiv,
      String? notes, List<Map<String, dynamic>> lignes) async {
    final db = await database;
    return db.transaction((txn) async {
      final cmdId = await txn.insert('commandes', {
        'client': client, 'telephone': tel,
        'date_livraison': dateLiv, 'notes': notes, 'statut': 'en_cours',
      });
      for (final l in lignes) {
        await txn.insert('lignes_commande', {
          'commande_id': cmdId,
          'produit_id': l['produit_id'],
          'nb_pieces': l['nb_pieces'],
          'prix_unitaire': l['prix_unitaire'],
        });
      }
      return cmdId;
    });
  }

  Future<void> updateStatutCommande(int id, String statut) async {
    final db = await database;
    // Si on marque comme terminée → déduire le stock
    if (statut == 'terminee') {
      final commande = await getCommande(id);
      if (commande != null && commande['statut'] != 'terminee') {
        final lignes = await getLignesCommande(id);
        await db.transaction((txn) async {
          for (final l in lignes) {
            final recette = await txn.rawQuery('''
              SELECT r.ingredient_id, r.quantite_100, i.unite
              FROM recettes r JOIN ingredients i ON r.ingredient_id = i.id
              WHERE r.produit_id = ?
            ''', [l['produit_id']]);
            final nbPieces = (l['nb_pieces'] as num).toDouble();
            for (final r in recette) {
              final consommation = (r['quantite_100'] as num).toDouble() * nbPieces / 100.0;
              await txn.rawUpdate(
                'UPDATE ingredients SET stock_actuel = MAX(0, stock_actuel - ?) WHERE id = ?',
                [consommation, r['ingredient_id']]);
            }
          }
          await txn.update('commandes',
            {'statut': statut, 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?', whereArgs: [id]);
        });
        return;
      }
    }
    await db.update('commandes',
      {'statut': statut, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCommande(int id) async {
    final db = await database;
    await db.delete('commandes', where: 'id = ?', whereArgs: [id]);
  }

  // ── ACHATS ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAchats({
    String? dateDebut, String? dateFin}) async {
    final db = await database;
    final conds = <String>[];
    final args  = <dynamic>[];
    if (dateDebut != null) { conds.add("date(a.created_at) >= ?"); args.add(dateDebut); }
    if (dateFin   != null) { conds.add("date(a.created_at) <= ?"); args.add(dateFin); }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    return db.rawQuery('''
      SELECT a.*, i.nom as ingredient_nom, i.unite
      FROM achats a JOIN ingredients i ON a.ingredient_id = i.id
      $where ORDER BY a.created_at DESC
    ''', args);
  }

  Future<void> addAchat(int ingredientId, double qte, double prix, String? fournisseur) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('achats', {
        'ingredient_id': ingredientId, 'quantite': qte,
        'prix_total': prix, 'fournisseur': fournisseur,
      });
      await txn.rawUpdate(
        'UPDATE ingredients SET stock_actuel = stock_actuel + ? WHERE id = ?',
        [qte, ingredientId]);
    });
  }

  // ── STATS ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats({
    String? dateDebut, String? dateFin}) async {
    final db = await database;
    final conds = <String>[];
    final args  = <dynamic>[];
    if (dateDebut != null) { conds.add("date(c.created_at) >= ?"); args.add(dateDebut); }
    if (dateFin   != null) { conds.add("date(c.created_at) <= ?"); args.add(dateFin); }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';

    final caRes = await db.rawQuery('''
      SELECT SUM(lc.nb_pieces * lc.prix_unitaire) as ca
      FROM lignes_commande lc
      JOIN commandes c ON lc.commande_id = c.id
      $where ${where.isEmpty ? "WHERE" : "AND"} c.statut = 'terminee'
    ''', [...args]);
    // fix: handle WHERE clause when already present
    final whereTerminee = conds.isEmpty
        ? "WHERE c.statut = 'terminee'"
        : 'WHERE ${conds.join(' AND ')} AND c.statut = \'terminee\'';
    final caRes2 = await db.rawQuery('''
      SELECT SUM(lc.nb_pieces * lc.prix_unitaire) as ca
      FROM lignes_commande lc
      JOIN commandes c ON lc.commande_id = c.id
      $whereTerminee
    ''', args);

    final depRes = await db.rawQuery('''
      SELECT SUM(prix_total) as total FROM achats
      ${dateDebut != null || dateFin != null ? 'WHERE' : ''}
      ${dateDebut != null ? "date(created_at) >= '$dateDebut'" : ''}
      ${dateDebut != null && dateFin != null ? 'AND' : ''}
      ${dateFin   != null ? "date(created_at) <= '$dateFin'"   : ''}
    ''');

    final acondsStr = [
      if (dateDebut != null) "date(created_at) >= '$dateDebut'",
      if (dateFin   != null) "date(created_at) <= '$dateFin'",
    ].join(' AND ');
    final aWhere = acondsStr.isEmpty ? '' : 'WHERE $acondsStr';
    final depRes2 = await db.rawQuery('SELECT SUM(prix_total) as total FROM achats $aWhere');

    final countRes = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN statut='en_cours' THEN 1 ELSE 0 END) as en_cours,
        SUM(CASE WHEN statut='terminee' THEN 1 ELSE 0 END) as terminee
      FROM commandes $where
    ''', args);

    final stockVal = await db.rawQuery(
      'SELECT SUM(stock_actuel * prix_unitaire) as val FROM ingredients');
    final alertes = await getStockAlerts();

    final ca       = (caRes2.first['ca'] as num?)?.toDouble() ?? 0;
    final depenses = (depRes2.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'ca_total':            ca,
      'depenses_achats':     depenses,
      'benefice':            ca - depenses,
      'commandes_total':     countRes.first['total'] ?? 0,
      'commandes_en_cours':  countRes.first['en_cours'] ?? 0,
      'commandes_terminee':  countRes.first['terminee'] ?? 0,
      'valeur_stock':        (stockVal.first['val'] as num?)?.toDouble() ?? 0,
      'nb_alertes':          alertes.length,
    };
  }

  // ── BESOINS COMMANDE ─────────────────────────────────

  Future<List<Map<String, dynamic>>> getBesoinsPourCommande(int commandeId) async {
    final db = await database;
    final lignes = await getLignesCommande(commandeId);
    final Map<int, Map<String, dynamic>> totaux = {};

    for (final l in lignes) {
      final recette = await db.rawQuery('''
        SELECT r.ingredient_id, r.quantite_100, i.nom, i.unite, i.stock_actuel
        FROM recettes r JOIN ingredients i ON r.ingredient_id = i.id
        WHERE r.produit_id = ?
      ''', [l['produit_id']]);
      final nbPieces = (l['nb_pieces'] as num).toDouble();
      for (final r in recette) {
        final ingId = r['ingredient_id'] as int;
        final besoin = (r['quantite_100'] as num).toDouble() * nbPieces / 100.0;
        if (totaux.containsKey(ingId)) {
          totaux[ingId]!['besoin'] += besoin;
        } else {
          totaux[ingId] = {
            'ingredient_id': ingId,
            'nom': r['nom'],
            'unite': r['unite'],
            'stock_actuel': r['stock_actuel'],
            'besoin': besoin,
          };
        }
      }
    }

    return totaux.values.map((b) {
      final manque = (b['besoin'] as double) - (b['stock_actuel'] as num).toDouble();
      return {...b, 'ok': manque <= 0, 'manque': manque > 0 ? manque : 0.0};
    }).toList();
  }

  // ── BACKUP ────────────────────────────────────────────

  Future<String> getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'patisserie.db');
  }

  Future<String> backupDb() async {
    final src  = await getDbPath();
    final dir  = await getApplicationDocumentsDirectory();
    final name = 'backup_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.db';
    final dest = p.join(dir.path, name);
    await File(src).copy(dest);
    return dest;
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    final dir  = await getApplicationDocumentsDirectory();
    final files = dir.listSync()
      .whereType<File>()
      .where((f) => p.basename(f.path).startsWith('backup_'))
      .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files.map((f) => {
      'name': p.basename(f.path),
      'path': f.path,
      'size': f.lengthSync(),
    }).toList();
  }

  Future<void> restoreDb(String backupPath) async {
    final destPath = await getDbPath();
    await _db?.close();
    _db = null;
    await File(backupPath).copy(destPath);
    _db = await _initDb();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
