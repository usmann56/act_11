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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(int id) async {
    try {
      await _dbHelper.deleteCard(id);
      await _fetchCards();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  // Updated Card Management methods

  Future<void> _showCardOptionsDialog(Map<String, dynamic> card) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card[DatabaseHelper.cardColumnName]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              card[DatabaseHelper.cardColumnImageUrl] ?? 'assets/images/default_card.jpg',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text('Suit: ${card[DatabaseHelper.cardColumnSuit]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editCardDialog(card);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _moveCardDialog(card);
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCardDialog(Map<String, dynamic> card) async {
    final nameController = TextEditingController(text: card[DatabaseHelper.cardColumnName]);
    final suitController = TextEditingController(text: card[DatabaseHelper.cardColumnSuit]);
    final imageController = TextEditingController(text: card[DatabaseHelper.cardColumnImageUrl]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Card Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Card Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: suitController.text,
              decoration: const InputDecoration(
                labelText: 'Suit',
                border: OutlineInputBorder(),
              ),
              items: ['Hearts', 'Spades', 'Diamonds', 'Clubs']
                  .map((suit) => DropdownMenuItem<String>(value: suit, child: Text(suit)))
                  .toList(),
              onChanged: (value) {
                if (value != null) suitController.text = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
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
              try {
                await _dbHelper.updateCardDetails(
                  card[DatabaseHelper.cardColumnId],
                  newName: nameController.text.trim(),
                  newSuit: suitController.text,
                  newImageUrl: imageController.text.trim().isEmpty ? null : imageController.text.trim(),
                );

                if (mounted) Navigator.pop(context);
                await _fetchCards();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorDialog(e.toString());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCardDialog(Map<String, dynamic> card) async {
    List<Map<String, dynamic>> folders = await _dbHelper.getAvailableFolders();
    String? selectedFolder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${card[DatabaseHelper.cardColumnName]}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select destination folder:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Destination Folder',
                border: OutlineInputBorder(),
              ),
              items: folders
                  .where((folder) => folder[DatabaseHelper.folderColumnName] != widget.folderName)
                  .map((folder) => DropdownMenuItem<String>(
                        value: folder[DatabaseHelper.folderColumnName],
                        child: Text(folder[DatabaseHelper.folderColumnName]),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedFolder = value;
              },
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
              if (selectedFolder != null) {
                try {
                  await _dbHelper.moveCardToFolder(
                    card[DatabaseHelper.cardColumnId],
                    selectedFolder!,
                  );

                  if (mounted) Navigator.pop(context);
                  await _fetchCards();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Card moved to $selectedFolder!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              }
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCardDialog() async {
    final nameController = TextEditingController();
    String selectedSuit = 'Hearts';
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Card to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Card Name (e.g., "Ace of Hearts")',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSuit,
              decoration: const InputDecoration(
                labelText: 'Suit',
                border: OutlineInputBorder(),
              ),
              items: ['Hearts', 'Spades', 'Diamonds', 'Clubs']
                  .map((suit) => DropdownMenuItem<String>(value: suit, child: Text(suit)))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedSuit = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
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
                    content: Text('Please enter a card name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _dbHelper.addCardToFolder(
                  nameController.text.trim(),
                  selectedSuit,
                  widget.folderName,
                  imageUrl: imageController.text.trim().isEmpty ? null : imageController.text.trim(),
                );

                if (mounted) Navigator.pop(context);
                await _fetchCards();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Card "${nameController.text}" added to ${widget.folderName}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorDialog(e.toString());
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
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
            onPressed: _addNewCardDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCardDialog,
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
                        child: GestureDetector(
                          onTap: () => _showCardOptionsDialog(card),
                          child: Image.asset(
                            card[DatabaseHelper.cardColumnImageUrl] ??
                                'assets/images/default_card.jpg',
                            fit: BoxFit.contain,
                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCardDialog(card),
                            tooltip: 'Edit Card',
                          ),
                          IconButton(
                            icon: const Icon(Icons.move_to_inbox, color: Colors.orange),
                            onPressed: () => _moveCardDialog(card),
                            tooltip: 'Move to Folder',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCard(card[DatabaseHelper.cardColumnId]),
                            tooltip: 'Delete Card',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
