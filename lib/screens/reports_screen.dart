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
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
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

// ==================== تقرير المنتجات مع إجمالي القيمة ====================
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

        // ⭐ حساب إجمالي القيمة الكلية للمنتجات المفلترة
        final totalInventoryValue = filteredReports.fold<double>(
          0,
          (sum, report) => sum + report['inventoryValue'],
        );

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

              // ⭐ عرض الإحصائيات مع إجمالي القيمة
              Row(
                children: [
                  Text(
                    'عدد المنتجات: ${filteredReports.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: Responsive.font(16),
                        ),
                  ),
                  Responsive.hBox(16),
                  Container(
                    padding: Responsive.paddingSym(h: 12, v: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(Responsive.radius(8)),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: Responsive.icon(20),
                          color: Colors.green[700],
                        ),
                        Responsive.hBox(6),
                        Text(
                          'إجمالي قيمة المخزون: ${NumberFormat('#,##0.00', 'ar').format(totalInventoryValue)} جنيه',
                          style: TextStyle(
                            fontSize: Responsive.font(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
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
                      DataColumn(
                          label: Text('قيمة المخزون'),
                          numeric: true), // ⭐ عمود جديد
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
                          // ⭐ عمود قيمة المخزون الجديد
                          DataCell(
                            Container(
                              padding: Responsive.paddingSym(h: 8, v: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius:
                                    BorderRadius.circular(Responsive.radius(6)),
                              ),
                              child: Text(
                                '${NumberFormat('#,##0.00', 'ar').format(report['inventoryValue'])} جنيه',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
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

  // ⭐ دالة حساب التقارير - تأكد من إضافة حساب قيمة المخزون
  List<Map<String, dynamic>> _calculateProductReports(
      ProductProvider provider) {
    return provider.products.map((product) {
      // حساب المبيعات لهذا المنتج
      final productSales =
          provider.sales.where((sale) => sale.productId == product.id).toList();

      final soldQty =
          productSales.fold<int>(0, (sum, sale) => sum + sale.quantitySold);
      final totalSales =
          productSales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
      final totalCost = productSales.fold<double>(
          0, (sum, sale) => sum + (sale.purchasePrice * sale.quantitySold));
      final profit = totalSales - totalCost;
      final profitMargin = totalSales > 0 ? (profit / totalSales) * 100 : 0;

      // ⭐ حساب قيمة المخزون = الكمية المتاحة × سعر الشراء
      final inventoryValue = product.quantity * product.purchasePrice;

      return {
        'name': product.name,
        'category': product.category,
        'warehouse': product.warehouse,
        'supplier': product.supplierName,
        'availableQty': product.quantity,
        'inventoryValue': inventoryValue, // ⭐ القيمة الجديدة
        'soldQty': soldQty,
        'totalSales': totalSales,
        'totalCost': totalCost,
        'profit': profit,
        'profitMargin': profitMargin,
      };
    }).toList();
  }
}
// ==================== حركة المخزون ====================
// lib/widgets/inventory_movement_tab.dart - مع فلتر التاريخ

class InventoryMovementTab extends StatefulWidget {
  const InventoryMovementTab({super.key});

  @override
  State<InventoryMovementTab> createState() => _InventoryMovementTabState();
}

class _InventoryMovementTabState extends State<InventoryMovementTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType =
      'الكل'; // 'الكل', 'بيع', 'إضافة', 'استرجاع', 'زيادة', 'نقصان'

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // تطبيق الفلتر
        var filteredTransactions = provider.inventoryTransactions;

        // فلتر حسب التاريخ
        if (_startDate != null) {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.dateTime
                .isAfter(_startDate!.subtract(const Duration(days: 1)));
          }).toList();
        }

        if (_endDate != null) {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.dateTime.isBefore(_endDate!.add(const Duration(days: 1)));
          }).toList();
        }

        // فلتر حسب نوع العملية
        if (_filterType != 'الكل') {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.transactionType == _filterType;
          }).toList();
        }

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

        return Column(
          children: [
            // شريط الفلاتر
            _buildFiltersSection(provider),

            // الجدول
            Expanded(
              child: SingleChildScrollView(
                padding: Responsive.paddingAll(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حركة المخزون',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.font(32),
                              ),
                            ),
                            Responsive.vBox(4),
                            Text(
                              _getFilterDescription(
                                filteredTransactions.length,
                                provider.inventoryTransactions.length,
                              ),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Responsive.font(16),
                              ),
                            ),
                          ],
                        ),
                        if (_startDate != null ||
                            _endDate != null ||
                            _filterType != 'الكل')
                          OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.clear, size: Responsive.icon(18)),
                            label: Text(
                              'إزالة الفلاتر',
                              style: TextStyle(fontSize: Responsive.font(14)),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    Responsive.vBox(24),
                    Card(
                      elevation: 4,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Colors.blue[50]),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.font(14),
                            color: Colors.black87,
                          ),
                          dataTextStyle:
                              TextStyle(fontSize: Responsive.font(13)),
                          columns: const [
                            DataColumn(label: Text('المنتج')),
                            DataColumn(label: Text('نوع العملية')),
                            DataColumn(label: Text('التغيير'), numeric: true),
                            DataColumn(label: Text('المتبقي'), numeric: true),
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('الملاحظات')),
                          ],
                          rows: filteredTransactions.map((transaction) {
                            final isPositive = transaction.quantityChange > 0;
                            return DataRow(
                              cells: [
                                DataCell(Text(transaction.productName)),
                                DataCell(
                                  Container(
                                    padding: Responsive.paddingSym(h: 8, v: 4),
                                    decoration: BoxDecoration(
                                      color: _getTransactionTypeColor(
                                              transaction.transactionType)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          Responsive.radius(4)),
                                    ),
                                    child: Text(
                                      transaction.transactionType,
                                      style: TextStyle(
                                        color: _getTransactionTypeColor(
                                            transaction.transactionType),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${isPositive ? '+' : ''}${transaction.quantityChange}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? Colors.green
                                          : Colors.red,
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersSection(ProductProvider provider) {
    return Container(
      padding: Responsive.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: Responsive.icon(20)),
              Responsive.hBox(8),
              Text(
                'تصفية حسب:',
                style: TextStyle(
                  fontSize: Responsive.font(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Responsive.vBox(12),

          // صف الفلاتر
          Wrap(
            spacing: Responsive.width(12),
            runSpacing: Responsive.height(12),
            children: [
              // فلتر نوع العملية
              _buildFilterChip(
                label: 'نوع العملية',
                value: _filterType,
                icon: Icons.category,
                onTap: () => _showTransactionTypeFilter(),
              ),

              // فلتر تاريخ البداية
              _buildFilterChip(
                label: _startDate == null
                    ? 'من تاريخ'
                    : 'من: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                value: null,
                icon: Icons.calendar_today,
                onTap: () => _selectStartDate(),
              ),

              // فلتر تاريخ النهاية
              _buildFilterChip(
                label: _endDate == null
                    ? 'إلى تاريخ'
                    : 'إلى: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                value: null,
                icon: Icons.event,
                onTap: () => _selectEndDate(),
              ),

              // أزرار سريعة
              _buildQuickFilterChip('اليوم', () => _setTodayFilter()),
              _buildQuickFilterChip('آخر 7 أيام', () => _setLast7DaysFilter()),
              _buildQuickFilterChip('هذا الشهر', () => _setThisMonthFilter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value != 'الكل';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: Responsive.paddingSym(h: 12, v: 8),
        decoration: BoxDecoration(
          color: hasValue ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          border: Border.all(
            color: hasValue ? Colors.blue : Colors.grey[300]!,
            width: hasValue ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Responsive.icon(18),
              color: hasValue ? Colors.blue[700] : Colors.grey[600],
            ),
            Responsive.hBox(6),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.font(13),
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                color: hasValue ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
            if (hasValue) ...[
              Responsive.hBox(4),
              Icon(
                Icons.check_circle,
                size: Responsive.icon(16),
                color: Colors.blue[700],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: Responsive.paddingSym(h: 12, v: 8),
        side: BorderSide(color: Colors.green[300]!),
        foregroundColor: Colors.green[700],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: Responsive.font(12)),
      ),
    );
  }

  void _showTransactionTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'اختر نوع العملية',
          style: TextStyle(fontSize: Responsive.font(18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeOption('الكل'),
            _buildTypeOption('بيع'),
            _buildTypeOption('إضافة'),
            _buildTypeOption('استرجاع'),
            _buildTypeOption('استرجاع من بيع'),
            _buildTypeOption('إلغاء بيع'),
            _buildTypeOption('زيادة'),
            _buildTypeOption('نقصان'),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type) {
    final isSelected = _filterType == type;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Colors.blue : Colors.grey,
        size: Responsive.icon(24),
      ),
      title: Text(
        type,
        style: TextStyle(
          fontSize: Responsive.font(14),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isSelected ? Colors.blue[50] : null,
      onTap: () {
        setState(() {
          _filterType = type;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _setTodayFilter() {
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
  }

  void _setLast7DaysFilter() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 7));
      _endDate = DateTime.now();
    });
  }

  void _setThisMonthFilter() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterType = 'الكل';
    });
  }

  String _getFilterDescription(int filtered, int total) {
    if (filtered == total) {
      return 'عدد الحركات: $total';
    }
    return 'عرض $filtered من أصل $total حركة';
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'بيع':
        return Colors.red;
      case 'إضافة':
        return Colors.green;
      case 'استرجاع':
      case 'استرجاع من بيع':
        return Colors.orange;
      case 'إلغاء بيع':
        return Colors.purple;
      case 'زيادة':
        return Colors.blue;
      case 'نقصان':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
