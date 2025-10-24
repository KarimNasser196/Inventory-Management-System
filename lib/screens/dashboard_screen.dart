import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/navigation_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? 16 : 32,
        ), // زيادة Padding للـ Desktop
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً بك في نظام إدارة المخزون',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 24 : 32, // حجم خط أكبر للـ Desktop
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'الخيارات السريعة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
            ),
            const SizedBox(height: 16),
            isMobile
                ? Column(
                    children: [
                      _buildQuickActionCard(
                        context,
                        'إضافة منتج جديد',
                        Icons.add_circle,
                        Colors.blue,
                        () => _navigateToScreen(context, 1),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionCard(
                        context,
                        'تسجيل بيع',
                        Icons.shopping_cart,
                        Colors.green,
                        () => _navigateToScreen(context, 2),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionCard(
                        context,
                        'استرجاع منتج',
                        Icons.reply,
                        Colors.orange,
                        () => _navigateToScreen(context, 3),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionCard(
                        context,
                        'عرض التقارير',
                        Icons.bar_chart,
                        Colors.purple,
                        () => _navigateToScreen(context, 4),
                      ),
                    ],
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4, // زيادة الأعمدة للـ Desktop
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.2,
                    children: [
                      _buildQuickActionCard(
                        context,
                        'إضافة منتج',
                        Icons.add_circle,
                        Colors.blue,
                        () => _navigateToScreen(context, 1),
                      ),
                      _buildQuickActionCard(
                        context,
                        'تسجيل بيع',
                        Icons.shopping_cart,
                        Colors.green,
                        () => _navigateToScreen(context, 2),
                      ),
                      _buildQuickActionCard(
                        context,
                        'استرجاع',
                        Icons.reply,
                        Colors.orange,
                        () => _navigateToScreen(context, 3),
                      ),
                      _buildQuickActionCard(
                        context,
                        'التقارير',
                        Icons.bar_chart,
                        Colors.purple,
                        () => _navigateToScreen(context, 4),
                      ),
                    ],
                  ),
            const SizedBox(height: 32),
            Text(
              'الملخص الإحصائي',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
            ),
            const SizedBox(height: 16),
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final totalProfit = provider.calculateTotalProfit();
                final totalSalesAmount = provider.sales.fold<double>(
                  0,
                  (sum, sale) => sum + sale.totalAmount,
                );
                return isMobile
                    ? Column(
                        children: [
                          _buildStatTile(
                            'المنتجات',
                            '${provider.totalProducts}',
                            Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildStatTile(
                            'الكميات',
                            '${provider.totalQuantityInStock}',
                            Colors.green,
                          ),
                        ],
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4, // زيادة الأعمدة
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatTile(
                            'المنتجات',
                            '${provider.totalProducts}',
                            Colors.blue,
                          ),
                          _buildStatTile(
                            'الكميات',
                            '${provider.totalQuantityInStock}',
                            Colors.green,
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'آخر المبيعات',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
            ),
            const SizedBox(height: 16),
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final recentSales = provider.getRecentSales();
                if (recentSales.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد مبيعات حديثة'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSales.length,
                  itemBuilder: (context, index) {
                    final sale = recentSales[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 4,
                      child: InkWell(
                        onTap: () {}, // يمكن إضافة تفاصيل المبيعة هنا
                        onHover: (isHovering) {
                          // تأثير Hover للـ Desktop
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(sale.productName),
                          subtitle: Text(
                            '${sale.customerName} • ${sale.getFormattedDateTime()}',
                          ),
                          trailing: Text(
                            '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        onHover: (isHovering) {
          // تأثير Hover للـ Desktop
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Provider.of<NavigationProvider>(
      context,
      listen: false,
    ).setSelectedIndex(index);
  }
}
