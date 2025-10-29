import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/responsive.dart';

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
    Responsive.init(context);

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
              labelStyle: TextStyle(fontSize: Responsive.font(14)),
              tabs: [
                Tab(
                  icon: Icon(Icons.account_balance_wallet,
                      size: Responsive.icon(24)),
                  text: 'الإحصائيات المالية',
                ),
                Tab(
                  icon: Icon(Icons.inventory, size: Responsive.icon(24)),
                  text: 'تقرير المنتجات',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long, size: Responsive.icon(24)),
                  text: 'حركة المخزون',
                ),
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
    Responsive.init(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

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
        final profitMargin =
            totalSalesAmount > 0 ? (totalProfit / totalSalesAmount * 100) : 0.0;

        return SingleChildScrollView(
          padding: Responsive.paddingAll(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإحصائيات المالية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(isMobile ? 24 : 32),
                    ),
              ),
              Responsive.vBox(24),

              // البطاقات الإحصائية - 3 بطاقات فقط (أزلنا متوسط البيع)
              isMobile
                  ? Column(
                      children: [
                        _buildStatCard(
                          context,
                          'إجمالي قيمة المخزون',
                          '${totalInventoryValue.toStringAsFixed(2)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        Responsive.vBox(12),
                        _buildStatCard(
                          context,
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية بيع',
                        ),
                        Responsive.vBox(12),
                        _buildStatCard(
                          context,
                          'إجمالي الربح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'نسبة الربح: ${profitMargin.toStringAsFixed(1)}%',
                        ),
                      ],
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          isTablet ? 2 : 3, // 2 للتابلت، 3 للديسكتوب
                      crossAxisSpacing: Responsive.width(24),
                      mainAxisSpacing: Responsive.height(24),
                      childAspectRatio: isTablet ? 1.3 : 1.5,
                      children: [
                        _buildStatCard(
                          context,
                          'إجمالي قيمة المخزون',
                          '${totalInventoryValue.toStringAsFixed(2)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        _buildStatCard(
                          context,
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية',
                        ),
                        _buildStatCard(
                          context,
                          'إجمالي الربح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'هامش ${profitMargin.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),

              Responsive.vBox(32),

              // جدول تفصيلي للمنتجات والأرباح
              Text(
                'تفاصيل الأرباح حسب المنتج',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(20),
                    ),
              ),
              Responsive.vBox(16),

              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(14),
                      color: Colors.black87,
                    ),
                    dataTextStyle: TextStyle(fontSize: Responsive.font(13)),
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
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: Responsive.icon(40), color: color),
            Responsive.vBox(12),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.font(14),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Responsive.vBox(8),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.font(20),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Responsive.vBox(4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.font(12),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== تقرير المنتجات ====================
class ProductsReportTab extends StatefulWidget {
  const ProductsReportTab({super.key});

  @override
  State<ProductsReportTab> createState() => _ProductsReportTabState();
}

class _ProductsReportTabState extends State<ProductsReportTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isMobile = Responsive.isMobile(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory,
                  size: Responsive.icon(64),
                  color: Colors.grey,
                ),
                Responsive.vBox(16),
                Text(
                  'لا توجد منتجات',
                  style: TextStyle(fontSize: Responsive.font(16)),
                ),
              ],
            ),
          );
        }

        // حساب إحصائيات المنتجات
        final productReports = _calculateProductReports(provider);

        // تطبيق البحث
        final filteredReports = _searchQuery.isEmpty
            ? productReports
            : productReports.where((report) {
                final query = _searchQuery.toLowerCase();
                return report['name'].toLowerCase().contains(query) ||
                    (report['category']?.toLowerCase().contains(query) ??
                        false) ||
                    (report['warehouse']?.toLowerCase().contains(query) ??
                        false) ||
                    report['supplier'].toLowerCase().contains(query);
              }).toList();

        return SingleChildScrollView(
          padding: Responsive.paddingAll(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقرير المنتجات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(isMobile ? 24 : 32),
                    ),
              ),
              Responsive.vBox(8),
              Text(
                'عدد المنتجات: ${provider.products.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: Responsive.font(16),
                    ),
              ),
              Responsive.vBox(16),

              // حقل البحث
              Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : Responsive.width(500),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج، صنف، مخزن، أو مورد...',
                    hintStyle: TextStyle(fontSize: Responsive.font(14)),
                    prefixIcon: Icon(
                      Icons.search,
                      size: Responsive.icon(24),
                      color: Colors.purple,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: Responsive.icon(20),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                      borderSide:
                          const BorderSide(color: Colors.purple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: Responsive.paddingSym(h: 16, v: 12),
                  ),
                  style: TextStyle(fontSize: Responsive.font(14)),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Responsive.vBox(16),

              // عرض عدد النتائج
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: Responsive.paddingOnly(bottom: 8),
                  child: Text(
                    'النتائج: ${filteredReports.length} من ${productReports.length}',
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Responsive.vBox(8),

              // الجدول
              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(14),
                      color: Colors.black87,
                    ),
                    dataTextStyle: TextStyle(fontSize: Responsive.font(13)),
                    columns: const [
                      DataColumn(label: Text('اسم المنتج')),
                      DataColumn(label: Text('الصنف')),
                      DataColumn(label: Text('المخزن')),
                      DataColumn(label: Text('المورد')),
                      DataColumn(label: Text('الكمية المتاحة'), numeric: true),
                      DataColumn(label: Text('الكمية المباعة'), numeric: true),
                      DataColumn(label: Text('إجمالي المبيعات')),
                      DataColumn(label: Text('تكلفة الشراء')),
                      DataColumn(label: Text('الربح الصافي')),
                      DataColumn(label: Text('نسبة الربح %')),
                    ],
                    rows: filteredReports.map((report) {
                      return DataRow(
                        cells: [
                          DataCell(Text(report['name'])),
                          DataCell(Text(report['category'] ?? '-')),
                          DataCell(Text(report['warehouse'] ?? '-')),
                          DataCell(Text(report['supplier'])),
                          DataCell(
                            Text(
                              '${report['availableQty']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: report['availableQty'] > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${report['soldQty']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${report['totalSales'].toStringAsFixed(2)} جنيه',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${report['totalCost'].toStringAsFixed(2)} جنيه',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${report['profit'].toStringAsFixed(2)} جنيه',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: report['profit'] > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${report['profitMargin'].toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: report['profitMargin'] > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
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

  List<Map<String, dynamic>> _calculateProductReports(
      ProductProvider provider) {
    final reports = <Map<String, dynamic>>[];

    for (var product in provider.products) {
      // حساب الكمية المباعة
      final soldQty = provider.sales
          .where((sale) => sale.productId == product.id)
          .fold<int>(0, (sum, sale) => sum + sale.quantitySold);

      // حساب إجمالي المبيعات
      final totalSales = provider.sales
          .where((sale) => sale.productId == product.id)
          .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

      // حساب تكلفة الشراء الإجمالية
      final totalCost = provider.sales
          .where((sale) => sale.productId == product.id)
          .fold<double>(
              0, (sum, sale) => sum + (sale.purchasePrice * sale.quantitySold));

      // حساب الربح
      final profit = totalSales - totalCost;

      // حساب نسبة الربح
      final profitMargin = totalSales > 0 ? (profit / totalSales * 100) : 0.0;

      reports.add({
        'name': product.name,
        'category': product.category,
        'warehouse': product.warehouse,
        'supplier': product.supplierName,
        'availableQty': product.quantity,
        'soldQty': soldQty,
        'totalSales': totalSales,
        'totalCost': totalCost,
        'profit': profit,
        'profitMargin': profitMargin,
      });
    }

    // ترتيب حسب الكمية المباعة (الأعلى أولاً)
    reports
        .sort((a, b) => (b['soldQty'] as int).compareTo(a['soldQty'] as int));

    return reports;
  }
}

// ==================== حركة المخزون ====================
class InventoryMovementTab extends StatelessWidget {
  const InventoryMovementTab({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isMobile = Responsive.isMobile(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.inventoryTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: Responsive.icon(64),
                  color: Colors.grey,
                ),
                Responsive.vBox(16),
                Text(
                  'لا توجد حركات مخزون بعد',
                  style: TextStyle(fontSize: Responsive.font(16)),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: Responsive.paddingAll(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حركة المخزون',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(isMobile ? 24 : 32),
                    ),
              ),
              Responsive.vBox(8),
              Text(
                'عدد الحركات: ${provider.inventoryTransactions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: Responsive.font(16),
                    ),
              ),
              Responsive.vBox(24),
              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(14),
                      color: Colors.black87,
                    ),
                    dataTextStyle: TextStyle(fontSize: Responsive.font(13)),
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
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(transaction.dateTime),
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
