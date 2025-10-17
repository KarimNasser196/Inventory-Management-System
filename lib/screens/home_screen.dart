import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'add_product_screen.dart';
import 'sell_product_screen.dart';
import 'return_product_screen.dart';
import 'reports_screen.dart';
import 'dashboard_screen.dart';
import 'products_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final List<Widget> screens = [
      const DashboardScreen(),
      const ProductsListScreen(),
      const SellProductScreen(),
      const ReturnProductScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        backgroundColor: Colors.blue,
        actions: [
          if (navigationProvider.selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
              },
              tooltip: 'إضافة منتج',
            ),
        ],
      ),
      body: Row(
        children: [
          // NavigationRail للـ Desktop
          if (!isMobile)
            NavigationRail(
              selectedIndex: navigationProvider.selectedIndex,
              onDestinationSelected: (index) {
                navigationProvider.setSelectedIndex(index);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              elevation: 4,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  selectedIcon: Icon(Icons.home_filled),
                  label: Text('الرئيسية'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('المنتجات'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sell),
                  selectedIcon: Icon(Icons.sell_outlined),
                  label: Text('بيع'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_return),
                  selectedIcon: Icon(Icons.assignment_return_outlined),
                  label: Text('استرجاع'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  selectedIcon: Icon(Icons.bar_chart_outlined),
                  label: Text('التقارير'),
                ),
              ],
            ),
          // المحتوى الرئيسي
          Expanded(
            child: Builder(
              builder: (context) {
                try {
                  return screens[navigationProvider.selectedIndex];
                } catch (e, stackTrace) {
                  debugPrint(
                    'Error rendering screen ${navigationProvider.selectedIndex}: $e\n$stackTrace',
                  );
                  return Center(child: Text('خطأ في تحميل الصفحة: $e'));
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: navigationProvider.selectedIndex,
              onTap: (index) {
                navigationProvider.setSelectedIndex(index);
              },
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'المنتجات',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'بيع'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_return),
                  label: 'استرجاع',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'التقارير',
                ),
              ],
            )
          : null,
    );
  }
}
