// lib/screens/reports_screen.dart (FIXED - Product & Sales Report)

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
    _tabController = TabController(length: 2, vsync: this);
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
                Tab(icon: Icon(Icons.inventory), text: 'تقرير المنتجات'),
                Tab(icon: Icon(Icons.receipt_long), text: 'حركة المخزون'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [ProductsReportTab(), InventoryMovementTab()],
            ),
          ),
        ],
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
              isMobile
                  ? _buildMobileProductsList(context, provider)
                  : _buildDesktopProductsTable(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileProductsList(
    BuildContext context,
    ProductProvider provider,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final product = provider.products[index];
        final quantitySold = _calculateQuantitySold(provider, product.id!);
        final quantityAvailable = product.quantity;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المورد: ${product.supplierName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (product.model != null && product.model!.isNotEmpty)
                  Text(
                    'النموذج: ${product.model}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'الكمية المتاحة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantityAvailable',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'الكمية المباعة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantitySold',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopProductsTable(
    BuildContext context,
    ProductProvider provider,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('اسم المنتج')),
          DataColumn(label: Text('المورد')),
          DataColumn(label: Text('النموذج')),
          DataColumn(label: Text('الكمية المتاحة'), numeric: true),
          DataColumn(label: Text('الكمية المباعة'), numeric: true),
          DataColumn(label: Text('سعر الشراء')),
          DataColumn(label: Text('سعر البيع')),
          DataColumn(label: Text('سعر الجمله')),
          DataColumn(label: Text('سعر جمله الجمله')),
        ],
        rows: provider.products.map((product) {
          final quantitySold = _calculateQuantitySold(provider, product.id!);
          return DataRow(
            cells: [
              DataCell(Text(product.name)),
              DataCell(Text(product.supplierName)),
              DataCell(Text(product.model ?? '-')),
              DataCell(
                Text(
                  '${product.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '$quantitySold',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              DataCell(Text(product.purchasePrice.toStringAsFixed(2))),
              DataCell(Text(product.retailPrice.toStringAsFixed(2))),
              DataCell(Text(product.wholesalePrice.toStringAsFixed(2))),
              DataCell(Text(product.bulkWholesalePrice.toStringAsFixed(2))),
            ],
          );
        }).toList(),
      ),
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
              isMobile
                  ? _buildMobileTransactionsList(context, provider)
                  : _buildDesktopTransactionsTable(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileTransactionsList(
    BuildContext context,
    ProductProvider provider,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.inventoryTransactions.length,
      itemBuilder: (context, index) {
        final transaction = provider.inventoryTransactions[index];
        final isPositive = transaction.quantityChange > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isPositive ? Colors.green : Colors.red,
                      child: Icon(
                        isPositive ? Icons.add : Icons.remove,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التغيير: ${isPositive ? '+' : ''}${transaction.quantityChange}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'المتبقي: ${transaction.quantityAfter}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(transaction.dateTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (transaction.notes != null &&
                          transaction.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'ملاحظات: ${transaction.notes}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTransactionsTable(
    BuildContext context,
    ProductProvider provider,
  ) {
    return SingleChildScrollView(
      reverse: false,
      scrollDirection: Axis.horizontal,
      child: DataTable(
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(transaction.dateTime),
                ),
              ),
              DataCell(Text(transaction.notes ?? '-')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
