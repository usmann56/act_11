import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

//Initializing DatabaseHelper Class
class DatabaseHelper {
  static final _databaseName = "CardsDatabase.db";
  static final _databaseVersion = 1;

  // Defining Table variables
  static final foldersTable = 'folders';
  static final cardsTable = 'cards';

  // Defining Folders Table Meta ID (column) variables
  static final folderColumnId = 'id';
  static final folderColumnName = 'folder_name';
  static final folderColumnCreatedAt = 'created_at';
  static final folderColumnUpdatedAt = 'updated_at';

  // Defining Cards table Meta ID (column) variables
  static final cardColumnId = 'id';
  static final cardColumnName = 'name';
  static final cardColumnSuit = 'suit';
  static final cardColumnImageUrl = 'image_url';
  static final cardColumnFolderId = 'folder_id';

  late Database _db;

  // Initializing the database
  Future<void> init() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Creating tables and insert initial data
  Future _onCreate(Database db, int version) async {
    // Create folders table and insert default meta data
    await db.execute('''
      CREATE TABLE $foldersTable (
        $folderColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $folderColumnName TEXT NOT NULL UNIQUE,
        $folderColumnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        $folderColumnUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create cards table and insert default meta data
    await db.execute('''
      CREATE TABLE $cardsTable (
        $cardColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cardColumnName TEXT NOT NULL,
        $cardColumnSuit TEXT NOT NULL CHECK ($cardColumnSuit IN ('Hearts', 'Spades', 'Diamonds', 'Clubs')),
        $cardColumnImageUrl TEXT,
        $cardColumnFolderId INTEGER NOT NULL,
        FOREIGN KEY ($cardColumnFolderId) REFERENCES $foldersTable($folderColumnId) ON DELETE CASCADE
      )
    ''');

    // Inserting folder suits into the table
    await db.insert(foldersTable, {folderColumnName: 'Hearts'});
    await db.insert(foldersTable, {folderColumnName: 'Spades'});
    await db.insert(foldersTable, {folderColumnName: 'Diamonds'});
    await db.insert(foldersTable, {folderColumnName: 'Clubs'});

    // Inserting cards
    final sampleCards = [
      {
        'name': 'Ace of Hearts',
        'suit': 'Hearts',
        'image_url': 'assets/images/ace_hearts.jpg',
        'folder_id': 1,
      },
      {
        'name': 'King of Hearts',
        'suit': 'Hearts',
        'image_url': 'assets/images/king_hearts.jpg',
        'folder_id': 1,
      },
      {
        'name': 'Queen of Hearts',
        'suit': 'Hearts',
        'image_url': 'assets/images/queen_hearts.jpg',
        'folder_id': 1,
      },
      {
        'name': 'Ace of Spades',
        'suit': 'Spades',
        'image_url': 'assets/images/ace_spades.jpg',
        'folder_id': 2,
      },
      {
        'name': 'King of Spades',
        'suit': 'Spades',
        'image_url': 'assets/images/king_spades.jpg',
        'folder_id': 2,
      },
      {
        'name': 'Queen of Spades',
        'suit': 'Spades',
        'image_url': 'assets/images/queen_spades.jpg',
        'folder_id': 2,
      },
      {
        'name': 'Ace of Diamonds',
        'suit': 'Diamonds',
        'image_url': 'assets/images/ace_diamonds.webp',
        'folder_id': 3,
      },
      {
        'name': 'King of Diamonds',
        'suit': 'Diamonds',
        'image_url': 'assets/images/king_diamonds.webp',
        'folder_id': 3,
      },
      {
        'name': 'Queen of Diamonds',
        'suit': 'Diamonds',
        'image_url': 'assets/images/queen_diamonds.jpg',
        'folder_id': 3,
      },
      {
        'name': 'Ace of Clubs',
        'suit': 'Clubs',
        'image_url': 'assets/images/ace_clubs.webp',
        'folder_id': 4,
      },
      {
        'name': 'King of Clubs',
        'suit': 'Clubs',
        'image_url': 'assets/images/king_clubs.jpg',
        'folder_id': 4,
      },
      {
        'name': 'Queen of Clubs',
        'suit': 'Clubs',
        'image_url': 'assets/images/queen_clubs.jpg',
        'folder_id': 4,
      },
    ];
    //Inserting each card and its meta data into the cards table
    for (Map<String, dynamic> card in sampleCards) {
      await db.insert(cardsTable, {
        cardColumnName: card['name'],
        cardColumnSuit: card['suit'],
        cardColumnImageUrl: card['image_url'],
        cardColumnFolderId: card['folder_id'],
      });
    }
  }

  // Folders Table CRUD operations

  // Create - Inserting new folder
  Future<int> insertFolder(Map<String, dynamic> row) async {
    return await _db.insert(foldersTable, row);
  }

  // Updating a Folder
  Future<int> updateFolder(Map<String, dynamic> row) async {
    int id = row[folderColumnId];
    return await _db.update(
      foldersTable,
      row,
      where: '$folderColumnId = ?',
      whereArgs: [id],
    );
  }

  // Deleting a folder
  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      foldersTable,
      where: '$folderColumnId = ?',
      whereArgs: [id],
    );
  }

  // Cards Table CRUD Operations

  // allows users to select a card and add to a folder
  Future<int> insertCard(Map<String, dynamic> row) async {
    return await _db.insert(cardsTable, row);
  }

  // Update card details
  Future<int> updateCard(Map<String, dynamic> row) async {
    int id = row[cardColumnId];
    return await _db.update(
      cardsTable,
      row,
      where: '$cardColumnId = ?',
      whereArgs: [id],
    );
  }

  // Deleting a card from a folder
  Future<int> deleteCard(int id) async {
    // Get card info to check which folder it belongs to
    List<Map<String, dynamic>> cardInfo = await _db.query(
      cardsTable,
      where: '$cardColumnId = ?',
      whereArgs: [id],
    );
    
    if (cardInfo.isEmpty) {
      throw Exception('Card not found');
    }
    
    int folderId = cardInfo.first[cardColumnFolderId];
    
    // Check if folder will have fewer than 3 cards after deletion
    int currentCardCount = await getCardCountInFolder(folderId);
    if (currentCardCount <= 3) {
      throw Exception('You need at least 3 cards in this folder.');
    }
    
    return await _db.delete(
      cardsTable,
      where: '$cardColumnId = ?',
      whereArgs: [id],
    );
  }

  // ENHANCED CARD MANAGEMENT METHODS

  // Create: Add a specific card to a folder by name
  // Example: Add "Ace of Hearts" to Hearts folder
  Future<int> addCardToFolder(String cardName, String cardSuit, String folderName, {String? imageUrl}) async {
    // First, find the folder ID by name
    List<Map<String, dynamic>> folders = await _db.query(
      foldersTable,
      where: '$folderColumnName = ?',
      whereArgs: [folderName],
    );
    
    if (folders.isEmpty) {
      throw Exception('Folder "$folderName" not found');
    }
    
    int folderId = folders.first[folderColumnId];
    
    // Check if folder already has 6 cards (maximum allowed)
    int currentCardCount = await getCardCountInFolder(folderId);
    if (currentCardCount >= 6) {
      throw Exception('This folder can only hold 6 cards.');
    }
    
    // Create the card data
    Map<String, dynamic> cardData = {
      cardColumnName: cardName,
      cardColumnSuit: cardSuit,
      cardColumnFolderId: folderId,
    };
    
    // Add image URL if provided
    if (imageUrl != null) {
      cardData[cardColumnImageUrl] = imageUrl;
    } else {
      // Generate default image path based on card name and suit
      String defaultImagePath = _generateDefaultImagePath(cardName, cardSuit);
      cardData[cardColumnImageUrl] = defaultImagePath;
    }
    
    // Insert the card
    return await _db.insert(cardsTable, cardData);
  }

  // Update: Move card to another folder
  Future<int> moveCardToFolder(int cardId, String newFolderName) async {
    // Find the new folder ID
    List<Map<String, dynamic>> folders = await _db.query(
      foldersTable,
      where: '$folderColumnName = ?',
      whereArgs: [newFolderName],
    );
    
    if (folders.isEmpty) {
      throw Exception('Folder "$newFolderName" not found');
    }
    
    int newFolderId = folders.first[folderColumnId];
    
    // Get current card info to check source folder
    List<Map<String, dynamic>> currentCard = await _db.query(
      cardsTable,
      where: '$cardColumnId = ?',
      whereArgs: [cardId],
    );
    
    if (currentCard.isEmpty) {
      throw Exception('Card not found');
    }
    
    int currentFolderId = currentCard.first[cardColumnFolderId];
    
    // Check if destination folder already has 6 cards (maximum allowed)
    int destinationCardCount = await getCardCountInFolder(newFolderId);
    if (destinationCardCount >= 6) {
      throw Exception('This folder can only hold 6 cards.');
    }
    
    // Check if source folder will have fewer than 3 cards after moving
    int sourceCardCount = await getCardCountInFolder(currentFolderId);
    if (sourceCardCount <= 3) {
      throw Exception('You need at least 3 cards in this folder.');
    }
    
    // Update the card's folder_id
    return await _db.update(
      cardsTable,
      {cardColumnFolderId: newFolderId},
      where: '$cardColumnId = ?',
      whereArgs: [cardId],
    );
  }

  // Update: Change card details (name, suit, image)
  Future<int> updateCardDetails(int cardId, {String? newName, String? newSuit, String? newImageUrl}) async {
    Map<String, dynamic> updateData = {};
    
    if (newName != null) {
      updateData[cardColumnName] = newName;
    }
    
    if (newSuit != null) {
      updateData[cardColumnSuit] = newSuit;
    }
    
    if (newImageUrl != null) {
      updateData[cardColumnImageUrl] = newImageUrl;
    }
    
    if (updateData.isEmpty) {
      throw Exception('No update data provided');
    }
    
    return await _db.update(
      cardsTable,
      updateData,
      where: '$cardColumnId = ?',
      whereArgs: [cardId],
    );
  }

  // Helper method to generate default image paths
  String _generateDefaultImagePath(String cardName, String suit) {
    String cleanName = cardName.toLowerCase()
        .replaceAll(' of ', '_')
        .replaceAll(' ', '_');
    return 'assets/images/${cleanName}.jpg';
  }

  // Get available folders for card assignment
  Future<List<Map<String, dynamic>>> getAvailableFolders() async {
    return await _db.query(foldersTable, orderBy: folderColumnName);
  }

  // Find card by name and suit
  Future<Map<String, dynamic>?> findCardByNameAndSuit(String name, String suit) async {
    List<Map<String, dynamic>> results = await _db.query(
      cardsTable,
      where: '$cardColumnName = ? AND $cardColumnSuit = ?',
      whereArgs: [name, suit],
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  // Get cards count in a specific folder
  Future<int> getCardCountInFolder(int folderId) async {
    List<Map<String, dynamic>> result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $cardsTable WHERE $cardColumnFolderId = ?',
      [folderId],
    );
    return result.first['count'] as int;
  }

  // Get cards count in a folder by folder name
  Future<int> getCardCountInFolderByName(String folderName) async {
    List<Map<String, dynamic>> folders = await _db.query(
      foldersTable,
      where: '$folderColumnName = ?',
      whereArgs: [folderName],
    );
    
    if (folders.isEmpty) {
      throw Exception('Folder "$folderName" not found');
    }
    
    int folderId = folders.first[folderColumnId];
    return await getCardCountInFolder(folderId);
  }

  Database get database => _db;
}
