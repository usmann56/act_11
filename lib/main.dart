import 'package:flutter/material.dart';
import 'screens/folder_screen.dart';
import 'services/dataBaseHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database before running the app
  final dbHelper = DatabaseHelper();
  await dbHelper.init();

  runApp(CardOrganizerApp(dbHelper: dbHelper));
}

class CardOrganizerApp extends StatelessWidget {
  final DatabaseHelper dbHelper;

  const CardOrganizerApp({super.key, required this.dbHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const FoldersScreen(),
    );
  }
}
