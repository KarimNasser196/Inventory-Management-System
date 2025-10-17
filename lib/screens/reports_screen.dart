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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Column(
        children: [
          // TabBar
          Container(
            color: Colors.purple,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'لوحة التحكم'),
                Tab(icon: Icon(Icons.receipt_long), text: 'المبيعات'),
                Tab(icon: Icon(Icons.history), text: 'حركة المخزون'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                DashboardTab(),
                SalesTab(),
                InventoryTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== لوحة التحكم ====================
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final totalProfit = provider.calculateTotalProfit();
        final totalSalesAmount = provider.sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الملخص العام',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(height: 24),
              // بطاقات الإحصائيات
              isMobile
                  ? Column(
                      children: [
                        _buildStatCard(
                          'إجمالي المنتجات',
                          '${provider.totalProducts}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'إجمالي الكميات',
                          '${provider.totalQuantityInStock}',
                          Icons.storage,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.attach_money,
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'إجمالي الأرباح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ],
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'إجمالي المنتجات',
                          '${provider.totalProducts}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'إجمالي الكميات',
                          '${provider.totalQuantityInStock}',
                          Icons.storage,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'إجمالي المبيعات',
                          '${totalSalesAmount.toStringAsFixed(2)} جنيه',
                          Icons.attach_money,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'إجمالي الأرباح',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ],
                    ),
              const SizedBox(height: 32),
              // آخر المبيعات
              Text(
                'آخر المبيعات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(height: 16),
              if (provider.sales.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('لا توجد مبيعات بعد'),
                  ),
                )
              else
                isMobile
                    ? _buildSalesList(
                        context,
                        provider.getRecentSales(limit: 5),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 3,
                            ),
                        itemCount: provider.getRecentSales(limit: 5).length,
                        itemBuilder: (context, index) {
                          final sale = provider.getRecentSales(limit: 5)[index];
                          return _buildSaleCard(context, sale);
                        },
                      ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {},
        onHover: (isHovering) {},
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, dynamic sale) {
    final profit = (sale.unitPrice - sale.purchasePrice) * sale.quantitySold;
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {},
        onHover: (isHovering) {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green,
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${sale.customerName} • ${sale.getFormattedDateTime()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'ربح: ${profit.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesList(BuildContext context, List<dynamic> sales) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) => _buildSaleCard(context, sales[index]),
    );
  }
}

// ==================== تقرير المبيعات ====================
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.sales.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد مبيعات بعد'),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'جميع المبيعات (${provider.sales.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(height: 16),
              isMobile
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.sales.length,
                      itemBuilder: (context, index) {
                        final sale = provider.sales[index];
                        return _buildSaleExpansionTile(context, sale);
                      },
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 3,
                          ),
                      itemCount: provider.sales.length,
                      itemBuilder: (context, index) {
                        final sale = provider.sales[index];
                        return _buildSaleCard(context, sale);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaleExpansionTile(BuildContext context, dynamic sale) {
    final profit = (sale.unitPrice - sale.purchasePrice) * sale.quantitySold;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getPriceTypeColor(sale.priceType),
          child: Text(
            sale.priceType == 'فردي'
                ? 'ف'
                : sale.priceType == 'جملة'
                ? 'ج'
                : 'جج',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          sale.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${sale.customerName} • ${sale.getFormattedDateTime()}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${sale.totalAmount.toStringAsFixed(2)} جنيه',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            Text(
              'ربح: ${profit.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('نوع السعر', sale.priceType),
                _buildDetailRow(
                  'سعر الوحدة',
                  '${sale.unitPrice.toStringAsFixed(2)} جنيه',
                ),
                _buildDetailRow('الكمية المباعة', '${sale.quantitySold}'),
                _buildDetailRow(
                  'الإجمالي',
                  '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                ),
                _buildDetailRow('المورد', sale.supplierName),
                _buildDetailRow(
                  'الكمية المتبقية',
                  '${sale.quantityRemainingInStock}',
                ),
                if (sale.notes != null && sale.notes!.isNotEmpty)
                  _buildDetailRow('ملاحظات', sale.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, dynamic sale) {
    final profit = (sale.unitPrice - sale.purchasePrice) * sale.quantitySold;
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {},
        onHover: (isHovering) {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getPriceTypeColor(sale.priceType),
                child: Text(
                  sale.priceType == 'فردي'
                      ? 'ف'
                      : sale.priceType == 'جملة'
                      ? 'ج'
                      : 'جج',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${sale.customerName} • ${sale.getFormattedDateTime()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'ربح: ${profit.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriceTypeColor(String priceType) {
    switch (priceType) {
      case 'فردي':
        return Colors.blue;
      case 'جملة':
        return Colors.orange;
      case 'جملة جملة':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== حركة المخزون ====================
class InventoryTransactionsTab extends StatelessWidget {
  const InventoryTransactionsTab({super.key});

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
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حركة المخزون (${provider.inventoryTransactions.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(height: 16),
              isMobile
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.inventoryTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction =
                            provider.inventoryTransactions[index];
                        return _buildTransactionCard(context, transaction);
                      },
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 3,
                          ),
                      itemCount: provider.inventoryTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction =
                            provider.inventoryTransactions[index];
                        return _buildTransactionCard(context, transaction);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic transaction) {
    final isPositive = transaction.quantityChange > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {},
        onHover: (isHovering) {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isPositive ? Colors.green : Colors.red,
                child: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      transaction.transactionType,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(transaction.dateTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (transaction.notes != null &&
                        transaction.notes!.isNotEmpty)
                      Text(
                        transaction.notes!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${transaction.quantityChange}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    'متبقي: ${transaction.quantityAfter}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
