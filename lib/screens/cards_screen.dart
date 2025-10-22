import 'package:flutter/material.dart';
import '../../services/dataBaseHelper.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const CardsScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _dbHelper.init();
    await _fetchCards();
  }

  Future<void> _fetchCards() async {
    final db = _dbHelper.database;
    final result = await db.query(
      DatabaseHelper.cardsTable,
      where: '${DatabaseHelper.cardColumnFolderId} = ?',
      whereArgs: [widget.folderId],
    );

    setState(() {
      _cards = result;
      _isLoading = false;
    });
  }

  Future<void> _addCardDialog() async {
    if (_cards.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder already has 6 cards. Cannot add more!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Card Name',
                  hintText: 'e.g., Ace of Hearts',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Card name cannot be empty.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await _dbHelper.insertCard({
                  DatabaseHelper.cardColumnName: nameController.text.trim(),
                  DatabaseHelper.cardColumnSuit: widget.folderName,
                  DatabaseHelper.cardColumnImageUrl:
                      'assets/images/default_card.jpg',
                  DatabaseHelper.cardColumnFolderId: widget.folderId,
                });

                if (mounted) Navigator.pop(context);
                await _fetchCards();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Card "${nameController.text}" added successfully.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(int id) async {
    await _dbHelper.deleteCard(id);
    await _fetchCards();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card deleted successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName} Cards'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Card',
            onPressed: _addCardDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCardDialog,
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
          ? const Center(
              child: Text('No cards in this folder yet. Tap + to add one!'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          card[DatabaseHelper.cardColumnImageUrl] ??
                              'assets/images/default_card.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card[DatabaseHelper.cardColumnName],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card[DatabaseHelper.cardColumnSuit],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteCard(card[DatabaseHelper.cardColumnId]),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
