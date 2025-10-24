import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.purple,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'الإحصائيات المالية',
                ),
                Tab(icon: Icon(Icons.inventory), text: 'تقرير المنتجات'),
                Tab(icon: Icon(Icons.receipt_long), text: 'حركة المخزون'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FinancialStatisticsTab(),
                ProductsReportTab(),
                InventoryMovementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== الإحصائيات المالية ====================
class FinancialStatisticsTab extends StatelessWidget {
  const FinancialStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // حساب إجمالي قيمة المخزون (بسعر الشراء)
        final totalInventoryValue = provider.products.fold<double>(
          0,
          (sum, p) => sum + (p.purchasePrice * p.quantity),
        );

        // حساب إجمالي المبيعات
        final totalSalesAmount = provider.sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );

        // حساب إجمالي الربح
        final totalProfit = provider.sales.fold<double>(
          0,
          (sum, sale) =>
              sum + ((sale.unitPrice - sale.purchasePrice) * sale.quantitySold),
        );

        // حساب نسبة الربح
        final profitMargin = totalSalesAmount > 0
            ? (totalProfit / totalSalesAmount * 100)
            : 0.0;

        // حساب متوسط قيمة البيع
        final averageSaleValue = provider.sales.isNotEmpty
            ? totalSalesAmount / provider.sales.length
            : 0.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإحصائيات المالية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(height: 24),

              // البطاقات الإحصائية
              isMobile
                  ? Column(
                      children: [
                        _buildStatCard(
                          'إجمالي قيمة المخزون',
                          '${totalInventoryValue.toStringAsFixed(2)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية بيع',
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'إجمالي الربح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'نسبة الربح: ${profitMargin.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'متوسط قيمة البيع',
                          '${averageSaleValue.toStringAsFixed(2)} جنيه',
                          Icons.calculate,
                          Colors.purple,
                          'لكل عملية بيع',
                        ),
                      ],
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'إجمالي قيمة المخزون',
                          '${totalInventoryValue.toStringAsFixed(2)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        _buildStatCard(
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية',
                        ),
                        _buildStatCard(
                          'إجمالي الربح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'هامش ${profitMargin.toStringAsFixed(1)}%',
                        ),
                        _buildStatCard(
                          'متوسط البيع',
                          '${averageSaleValue.toStringAsFixed(2)} جنيه',
                          Icons.calculate,
                          Colors.purple,
                          'لكل عملية',
                        ),
                      ],
                    ),

              const SizedBox(height: 32),

              // جدول تفصيلي للمنتجات والأرباح
              Text(
                'تفاصيل الأرباح حسب المنتج',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text('المنتج')),
                      DataColumn(label: Text('الكمية المباعة')),
                      DataColumn(label: Text('إجمالي المبيعات')),
                      DataColumn(label: Text('تكلفة الشراء')),
                      DataColumn(label: Text('الربح الصافي')),
                      DataColumn(label: Text('هامش الربح %')),
                    ],
                    rows: _buildProfitRows(provider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DataRow> _buildProfitRows(ProductProvider provider) {
    final productStats = <int, Map<String, dynamic>>{};

    // تجميع البيانات حسب المنتج
    for (var sale in provider.sales) {
      if (!productStats.containsKey(sale.productId)) {
        productStats[sale.productId] = {
          'name': sale.productName,
          'quantitySold': 0,
          'totalSales': 0.0,
          'totalCost': 0.0,
        };
      }

      productStats[sale.productId]!['quantitySold'] += sale.quantitySold;
      productStats[sale.productId]!['totalSales'] += sale.totalAmount;
      productStats[sale.productId]!['totalCost'] +=
          (sale.purchasePrice * sale.quantitySold);
    }

    // إنشاء صفوف الجدول
    final rows = productStats.entries.map((entry) {
      final data = entry.value;
      final totalSales = data['totalSales'] as double;
      final totalCost = data['totalCost'] as double;
      final profit = totalSales - totalCost;
      final profitMargin = totalSales > 0 ? (profit / totalSales * 100) : 0.0;

      return DataRow(
        cells: [
          DataCell(Text(data['name'])),
          DataCell(Text('${data['quantitySold']}')),
          DataCell(Text('${totalSales.toStringAsFixed(2)} جنيه')),
          DataCell(Text('${totalCost.toStringAsFixed(2)} جنيه')),
          DataCell(
            Text(
              '${profit.toStringAsFixed(2)} جنيه',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
          DataCell(
            Text(
              '${profitMargin.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profitMargin > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      );
    }).toList();

    // ترتيب حسب الربح (الأعلى أولاً)
    rows.sort((a, b) {
      final profitA = double.parse(
        a.cells[4].child
            .toString()
            .split(' ')[0]
            .replaceAll(RegExp(r'[^0-9.-]'), ''),
      );
      final profitB = double.parse(
        b.cells[4].child
            .toString()
            .split(' ')[0]
            .replaceAll(RegExp(r'[^0-9.-]'), ''),
      );
      return profitB.compareTo(profitA);
    });

    return rows;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
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
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== تقرير المنتجات ====================
class ProductsReportTab extends StatelessWidget {
  const ProductsReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد منتجات'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقرير المنتجات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عدد المنتجات: ${provider.products.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text('اسم المنتج')),
                      DataColumn(label: Text('الصنف')),
                      DataColumn(label: Text('المخزن')),
                      DataColumn(label: Text('المورد')),
                      DataColumn(label: Text('الكمية المتاحة'), numeric: true),
                      DataColumn(label: Text('الكمية المباعة'), numeric: true),
                      DataColumn(label: Text('سعر الشراء')),
                      DataColumn(label: Text('سعر البيع')),
                      DataColumn(label: Text('سعر الجملة')),
                      DataColumn(label: Text('سعر جملة الجملة')),
                    ],
                    rows: provider.products.map((product) {
                      final quantitySold = _calculateQuantitySold(
                        provider,
                        product.id!,
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(product.name)),
                          DataCell(Text(product.category ?? '-')),
                          DataCell(Text(product.warehouse ?? '-')),
                          DataCell(Text(product.supplierName)),
                          DataCell(
                            Text(
                              '${product.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: product.quantity > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '$quantitySold',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(product.purchasePrice.toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(product.retailPrice.toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(product.wholesalePrice.toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(product.bulkWholesalePrice.toStringAsFixed(2)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateQuantitySold(ProductProvider provider, int productId) {
    return provider.sales
        .where((sale) => sale.productId == productId)
        .fold<int>(0, (sum, sale) => sum + sale.quantitySold);
  }
}

// ==================== حركة المخزون ====================
class InventoryMovementTab extends StatelessWidget {
  const InventoryMovementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.inventoryTransactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد حركات مخزون بعد'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حركة المخزون',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عدد الحركات: ${provider.inventoryTransactions.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text('المنتج')),
                      DataColumn(label: Text('نوع العملية')),
                      DataColumn(label: Text('التغيير'), numeric: true),
                      DataColumn(label: Text('المتبقي'), numeric: true),
                      DataColumn(label: Text('التاريخ')),
                      DataColumn(label: Text('الملاحظات')),
                    ],
                    rows: provider.inventoryTransactions.map((transaction) {
                      final isPositive = transaction.quantityChange > 0;
                      return DataRow(
                        cells: [
                          DataCell(Text(transaction.productName)),
                          DataCell(Text(transaction.transactionType)),
                          DataCell(
                            Text(
                              '${isPositive ? '+' : ''}${transaction.quantityChange}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${transaction.quantityAfter}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(transaction.dateTime),
                            ),
                          ),
                          DataCell(Text(transaction.notes ?? '-')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
