import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class ReturnProductScreen extends StatelessWidget {
  const ReturnProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // Get return transactions
          final returnTransactions =
              provider.inventoryTransactions
                  .where((tx) => tx.transactionType == 'استرجاع من بيع')
                  .toList()
                ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          if (returnTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reply, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات مسترجعة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك استرجاع المنتجات من صفحة المبيعات',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final totalReturns = returnTransactions.length;
          final totalQuantityReturned = returnTransactions.fold<int>(
            0,
            (sum, tx) => sum + tx.quantityChange,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.reply,
                        size: 32,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المنتجات المسترجعة',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 24 : 32,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'عرض جميع عمليات الاسترجاع',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Statistics cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'إجمالي الاسترجاعات',
                        '$totalReturns',
                        Icons.receipt_long,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'إجمالي القطع المسترجعة',
                        '$totalQuantityReturned',
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Returns list
                isMobile
                    ? _buildMobileReturnsList(
                        context,
                        provider,
                        returnTransactions,
                      )
                    : _buildDesktopReturnsList(
                        context,
                        provider,
                        returnTransactions,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileReturnsList(
    BuildContext context,
    ProductProvider provider,
    List<dynamic> returnTransactions,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: returnTransactions.length,
      itemBuilder: (context, index) {
        final tx = returnTransactions[index];

        // الحصول على بيانات البيع الأصلية
        final sale = tx.relatedSaleId != null
            ? provider.sales.cast<dynamic?>().firstWhere(
                (s) => s?.id.toString() == tx.relatedSaleId,
                orElse: () => null,
              )
            : null;

        final quantityReturned = tx.quantityChange;
        final customerName = sale?.customerName ?? 'غير متاح';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () => _showReturnDetails(context, tx, sale),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and product name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.reply,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رقم العملية: #${tx.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quantity returned
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Text(
                                'الكمية المسترجعة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$quantityReturned',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'اسم العميل',
                            customerName,
                            Icons.person,
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'السبب',
                            tx.notes ?? 'غير محدد',
                            Icons.comment,
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'التاريخ والوقت',
                            DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime),
                            Icons.calendar_today,
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'الكمية بعد الاسترجاع',
                            '${tx.quantityAfter}',
                            Icons.inventory,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopReturnsList(
    BuildContext context,
    ProductProvider provider,
    List<dynamic> returnTransactions,
  ) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: returnTransactions.map((tx) {
        final sale = tx.relatedSaleId != null
            ? provider.sales.cast<dynamic?>().firstWhere(
                (s) => s?.id.toString() == tx.relatedSaleId,
                orElse: () => null,
              )
            : null;

        final quantityReturned = tx.quantityChange;
        final customerName = sale?.customerName ?? 'غير متاح';

        return SizedBox(
          width: 380,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () => _showReturnDetails(context, tx, sale),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.reply,
                            color: Colors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رقم العملية: #${tx.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quantity
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                'المسترجع',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$quantityReturned',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('العميل', customerName, Icons.person),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'السبب',
                            tx.notes ?? 'غير محدد',
                            Icons.comment,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'التاريخ',
                            DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime),
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showReturnDetails(BuildContext context, dynamic tx, dynamic sale) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.reply,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل الاسترجاع',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'رقم العملية: #${tx.id}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Product Info
                _buildInfoSection(
                  'معلومات المنتج',
                  Icons.inventory_2,
                  Colors.blue,
                  [
                    _buildInfoItem('اسم المنتج', tx.productName),
                    _buildInfoItem(
                      'الكمية المسترجعة',
                      '${tx.quantityChange}',
                      valueColor: Colors.orange,
                    ),
                    _buildInfoItem(
                      'الكمية بعد الاسترجاع',
                      '${tx.quantityAfter}',
                      valueColor: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sale Info
                if (sale != null)
                  _buildInfoSection(
                    'معلومات البيع الأصلي',
                    Icons.shopping_cart,
                    Colors.green,
                    [
                      _buildInfoItem('العميل', sale.customerName),
                      _buildInfoItem('الكمية المباعة', '${sale.quantitySold}'),
                      _buildInfoItem(
                        'سعر الوحدة',
                        '${sale.unitPrice.toStringAsFixed(2)} جنيه',
                      ),
                      _buildInfoItem(
                        'تاريخ البيع',
                        DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(sale.saleDateTime),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'لا توجد معلومات عن البيع الأصلي',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Return Info
                _buildInfoSection(
                  'معلومات الاسترجاع',
                  Icons.assignment_return,
                  Colors.orange,
                  [
                    _buildInfoItem('سبب الاسترجاع', tx.notes ?? 'غير محدد'),
                    _buildInfoItem(
                      'تاريخ الاسترجاع',
                      DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime),
                    ),
                    if (tx.relatedSaleId != null)
                      _buildInfoItem(
                        'رقم البيع المرتبط',
                        '#${tx.relatedSaleId}',
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
