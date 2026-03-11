import 'package:flutter/material.dart';
import 'package:frontend/screens/activity_screen.dart';
import 'package:frontend/screens/add_expense_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'dashboard_screen.dart';
import 'friends_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Hier kommen später die anderen Screens rein
  final List<Widget> _screens = [
    const DashboardScreen(),
    const FriendsScreen(), // Platzhalter
    const ActivityScreen(), // Platzhalter
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_currentIndex],

      // Schwebender + Button in der Mitte
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Wartet darauf, ob der Screen mit "true" geschlossen wurde (Erfolgreich hinzugefügt)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );

          // Wenn ein Eintrag hinzugefügt wurde, laden wir den aktuellen Screen neu
          if (result == true) {
            setState(() {
              // Zwingt das Dashboard, sich neu zu zeichnen (die Daten werden in initState bzw. didChangeDependencies neu geladen)
              _currentIndex = _currentIndex;
            });
          }
        },
        backgroundColor:
            theme.floatingActionButtonTheme.backgroundColor ??
            theme.colorScheme.primary,
        foregroundColor:
            theme.floatingActionButtonTheme.foregroundColor ??
            theme.colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigationsleiste unten
      bottomNavigationBar: BottomAppBar(
        color: theme.bottomAppBarTheme.color ?? theme.cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Start', 0),
              _buildNavItem(Icons.people_outline, 'Freunde', 1),
              const SizedBox(width: 48), // Platz für den Floating Action Button
              _buildNavItem(Icons.receipt_long_outlined, 'Aktivität', 2),
              _buildNavItem(Icons.settings_outlined, 'Einstellungen', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(166) ?? Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? selectedColor : unselectedColor),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : unselectedColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
