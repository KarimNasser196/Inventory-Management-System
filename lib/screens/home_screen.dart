import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/laptop_provider.dart';
import '../utils/constants.dart';
import 'laptops_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LaptopsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    AppConstants.navLaptops,
    AppConstants.navReports,
    AppConstants.navSettings,
  ];

  @override
  void initState() {
    super.initState();
    // Load data when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LaptopProvider>(context, listen: false).fetchLaptops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Mobile layout with bottom navigation
      return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.laptop), label: 'الأجهزة'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'التقارير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      );
    } else {
      // Desktop layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.background,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.laptop),
                  label: Text('الأجهزة'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  label: Text('التقارير'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('الإعدادات'),
                ),
              ],
            ),

            // Main content
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }
  }
}
