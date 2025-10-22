import 'package:flutter/material.dart';
import '../../services/dataBaseHelper.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    await _dbHelper.init();
    await _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    final db = _dbHelper.database;

    // Query folders with card counts
    final List<Map<String, dynamic>> folders = await db.rawQuery('''
      SELECT f.*, COUNT(c.id) AS card_count, 
        (SELECT image_url FROM ${DatabaseHelper.cardsTable} 
         WHERE folder_id = f.id LIMIT 1) AS preview_image
      FROM ${DatabaseHelper.foldersTable} f
      LEFT JOIN ${DatabaseHelper.cardsTable} c
      ON f.id = c.folder_id
      GROUP BY f.id
      ORDER BY f.id
    ''');

    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  Future<void> _showDeleteConfirmationDialog(
    int folderId,
    String folderName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete "$folderName" and all its cards?',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteFolder(folderId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(int folderId) async {
    final db = _dbHelper.database;

    try {
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseHelper.cardsTable,
          where: '${DatabaseHelper.cardColumnFolderId} = ?',
          whereArgs: [folderId],
        );
        await txn.delete(
          DatabaseHelper.foldersTable,
          where: '${DatabaseHelper.folderColumnId} = ?',
          whereArgs: [folderId],
        );
      });

      await _fetchFolders();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: _folders.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  final folderName = folder['folder_name'];
                  final cardCount = folder['card_count'];
                  final previewImage = folder['preview_image'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardsScreen(
                            folderId: folder['id'],
                            folderName: folderName,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: previewImage != null
                                  ? Image.asset(
                                      previewImage,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(
                                      Icons.folder,
                                      size: 70,
                                      color: Colors.deepPurple,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              folderName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$cardCount cards',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                folder['id'],
                                folderName,
                              ),
                              tooltip: 'Delete Folder',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
