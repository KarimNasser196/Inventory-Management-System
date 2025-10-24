import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Column(
        children: [
          // Search bar and Add button
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<ProductProvider>(
                                  context,
                                  listen: false,
                                ).setSearchQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (query) {
                      Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      ).setSearchQuery(query);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddProduct(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Excel-style table
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('لا توجد منتجات'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddProduct(context),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة منتج جديد'),
                        ),
                      ],
                    ),
                  );
                }
                return _buildExcelTable(context, provider.products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelTable(BuildContext context, List<Product> products) {
    return Card(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      elevation: 4,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
            headingRowHeight: 56,
            dataRowHeight: 60,
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            columnSpacing: 24,
            columns: const [
              DataColumn(
                label: Text(
                  'الاسم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الصنف',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'المخزن',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              DataColumn(
                label: Text(
                  'المواصفات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'المورد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الكمية',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'سعر الشراء',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'سعر البيع (فردي)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'سعر الجملة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'سعر جملة الجملة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'الملاحظات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الإجراءات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(width: 100, child: Text(product.category ?? '-')),
                  ),
                  DataCell(
                    SizedBox(width: 100, child: Text(product.warehouse ?? '-')),
                  ),

                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        product.specifications ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(width: 120, child: Text(product.supplierName)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: product.quantity > 0
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.quantity > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.purchasePrice.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.retailPrice.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.wholesalePrice.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.bulkWholesalePrice.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        product.notes ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          tooltip: 'عرض',
                          onPressed: () =>
                              _showProductDetails(context, product),
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'تعديل',
                          onPressed: () =>
                              _navigateToEditProduct(context, product),
                          color: Colors.orange,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'حذف',
                          onPressed: () => _confirmDelete(context, product),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.category != null)
                _buildDetailItem('الصنف', product.category!),
              if (product.warehouse != null)
                if (product.specifications != null &&
                    product.specifications!.isNotEmpty)
                  _buildDetailItem('المواصفات', product.specifications!),
              _buildDetailItem('المورد', product.supplierName),
              const Divider(),
              _buildDetailItem(
                'سعر الشراء',
                '${product.purchasePrice.toStringAsFixed(2)} جنيه',
              ),
              _buildDetailItem(
                'سعر البيع (فردي)',
                '${product.retailPrice.toStringAsFixed(2)} جنيه',
              ),
              _buildDetailItem(
                'سعر الجملة',
                '${product.wholesalePrice.toStringAsFixed(2)} جنيه',
              ),
              _buildDetailItem(
                'سعر جملة الجملة',
                '${product.bulkWholesalePrice.toStringAsFixed(2)} جنيه',
              ),
              const Divider(),
              _buildDetailItem('الكمية المتاحة', '${product.quantity}'),
              if (product.notes != null && product.notes!.isNotEmpty)
                _buildDetailItem('ملاحظات', product.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditProduct(context, product);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProductProvider>(
                context,
                listen: false,
              ).deleteProduct(product.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المنتج بنجاح')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
