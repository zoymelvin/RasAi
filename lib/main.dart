import 'package:flutter/material.dart';
import 'db/hive_boxes.dart';
import 'screens/search_screen.dart';
import 'screens/saved_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  runApp(const RasAIApp());
}

class RasAIApp extends StatelessWidget {
  const RasAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RasAI',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 40, 83, 83),
        useMaterial3: true,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _index = 0;
  final _pages = const [SearchScreen(), SavedScreen()];

  @override
Widget build(BuildContext context) {
  return Scaffold(
    // tidak ada AppBar
    body: SafeArea(child: _pages[_index]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
        NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
      ],
    ),
  );
}

}
