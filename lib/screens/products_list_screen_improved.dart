import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/screens/add_product_screen.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../widgets/password_dialog.dart';

enum ViewMode { cards, table }

class ProductsListScreenUpdated extends StatefulWidget {
  const ProductsListScreenUpdated({super.key});

  @override
  State<ProductsListScreenUpdated> createState() =>
      _ProductsListScreenUpdatedState();
}

class _ProductsListScreenUpdatedState extends State<ProductsListScreenUpdated> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TextEditingController _searchController;
  String? _selectedCategoryFilter;
  String? _selectedWarehouseFilter;
  String? _selectedSupplierFilter;

  List<Map<String, dynamic>> _availableCategories = [];
  List<Map<String, dynamic>> _availableWarehouses = [];
  List<Map<String, dynamic>> _availableSuppliers = [];

  ViewMode _viewMode = ViewMode.cards;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadFilterOptions();
  }

  // دالة منفصلة للاستماع للتغييرات مع فحص mounted
  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final db = await _dbHelper.database;

      final categories = await db.query('categories', orderBy: 'name ASC');
      final warehouses = await db.query('warehouses', orderBy: 'name ASC');
      final suppliers = await db.query('suppliers', orderBy: 'name ASC');

      // فحص mounted قبل استدعاء setState
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _availableWarehouses = warehouses;
          _availableSuppliers = suppliers;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading filter options: $e');
      }
    }
  }

  @override
  void dispose() {
    // إزالة المستمع قبل dispose
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }

    // Filter by warehouse
    if (_selectedWarehouseFilter != null) {
      filtered = filtered
          .where((p) => p.warehouse == _selectedWarehouseFilter)
          .toList();
    }

    // Filter by supplier
    if (_selectedSupplierFilter != null) {
      filtered = filtered
          .where((p) => p.supplierName == _selectedSupplierFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar, filters and Add button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (query) {
                          Provider.of<ProductProvider>(
                            context,
                            listen: false,
                          ).setSearchQuery(query);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.grid_view,
                              color: _viewMode == ViewMode.cards
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _viewMode = ViewMode.cards;
                                });
                              }
                            },
                            tooltip: 'عرض البطاقات',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.table_rows,
                              color: _viewMode == ViewMode.table
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _viewMode = ViewMode.table;
                                });
                              }
                            },
                            tooltip: 'عرض الجدول',
                          ),
                        ],
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedCategoryFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب الصنف',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableCategories.map(
                            (cat) => DropdownMenuItem(
                              value: cat['name'].toString(),
                              child: Text(cat['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedCategoryFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedWarehouseFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب المخزن',
                          prefixIcon: const Icon(Icons.warehouse),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableWarehouses.map(
                            (warehouse) => DropdownMenuItem(
                              value: warehouse['name'].toString(),
                              child: Text(warehouse['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedWarehouseFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedSupplierFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب المورد',
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableSuppliers.map(
                            (supplier) => DropdownMenuItem(
                              value: supplier['name'].toString(),
                              child: Text(supplier['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedSupplierFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Products grid or table
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredProducts = _getFilteredProducts(
                  provider.products,
                );

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
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

                return _viewMode == ViewMode.cards
                    ? _buildProductsTable(context, filteredProducts)
                    : _buildProductsGrid(context, filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(
    BuildContext context,
    List<Product> products,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: products.map((product) {
          return SizedBox(
            width: 380,
            child: _buildProductCard(context, product),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsTable(
    BuildContext context,
    List<Product> products,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 4,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
            columns: const [
              DataColumn(label: Text('الاسم')),
              DataColumn(label: Text('الصنف')),
              DataColumn(label: Text('المخزن')),
              DataColumn(label: Text('المورد')),
              DataColumn(label: Text('الكمية')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(product.category ?? '-')),
                  DataCell(Text(product.warehouse ?? '-')),
                  DataCell(Text(product.supplierName)),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.quantity > 0
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () =>
                              _showProductDetails(context, product),
                          tooltip: 'عرض',
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _navigateToEditProduct(context, product),
                          tooltip: 'تعديل',
                          color: Colors.orange,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _confirmDelete(context, product),
                          tooltip: 'حذف',
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

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with product name and category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.category != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (product.warehouse != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المخزن:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            product.warehouse!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'المورد:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Text(
                            product.supplierName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quantity indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      product.quantity > 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product.quantity > 0 ? Icons.check_circle : Icons.warning,
                      color: product.quantity > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الكمية المتاحة: ${product.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: product.quantity > 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProductDetails(context, product),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('عرض'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToEditProduct(context, product),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(context, product),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Basic Info
                _buildDetailSection(
                  'معلومات أساسية',
                  Icons.info_outline,
                  Colors.blue,
                  [
                    if (product.category != null)
                      _buildDetailItem('الصنف', product.category!),
                    if (product.warehouse != null)
                      _buildDetailItem('المخزن', product.warehouse!),
                    _buildDetailItem('المورد', product.supplierName),
                    if (product.specifications != null &&
                        product.specifications!.isNotEmpty)
                      _buildDetailItem('المواصفات', product.specifications!),
                  ],
                ),

                const SizedBox(height: 16),

                // Prices
                _buildDetailSection(
                  'الأسعار',
                  Icons.attach_money,
                  Colors.green,
                  [
                    _buildDetailItem(
                      'سعر الشراء',
                      '${product.purchasePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.red[700],
                    ),
                    _buildDetailItem(
                      'سعر البيع (فردي)',
                      '${product.retailPrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.blue[700],
                    ),
                    _buildDetailItem(
                      'سعر الجملة ',
                      '${product.wholesalePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.green[700],
                    ),
                    _buildDetailItem(
                      'سعر جملة الجملة ',
                      '${product.bulkWholesalePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.orange[700],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stock Info
                _buildDetailSection(
                  'معلومات المخزون',
                  Icons.inventory,
                  Colors.purple,
                  [
                    _buildDetailItem(
                      'الكمية المتاحة',
                      '${product.quantity}',
                      valueColor: product.quantity > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                      valueWeight: FontWeight.bold,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('إغلاق'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToEditProduct(context, product);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
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

  Widget _buildDetailItem(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
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
                fontWeight: valueWeight ?? FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreenUpdated()),
    );

    // إعادة تحميل الخيارات والمنتجات بعد الرجوع
    if (mounted) {
      await _loadFilterOptions();
      // تحديث قائمة المنتجات من الـ provider
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).products;
      }
    }
  }

  void _navigateToEditProduct(BuildContext context, Product product) async {
    // Save the provider reference before any async operations
    final productProvider = context.read<ProductProvider>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreenUpdated(product: product),
      ),
    );

    if (!mounted) return;

    await _loadFilterOptions();

    if (!mounted) return;

    // Use the saved reference instead of accessing context again
    productProvider.products;
  }

  void _confirmDelete(BuildContext context, Product product) async {
    // أولاً نظهر تأكيد الحذف
    final bool? wantToDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد حذف المنتج "${product.name}"؟'),
            const SizedBox(height: 8),
            const Text(
              'تحذير: سيتم حذف جميع البيانات المرتبطة بهذا المنتج.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (wantToDelete != true || !mounted) return;

    // ثم نطلب كلمة السر
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PasswordDialog(
        title: 'تأكيد الحذف',
        message: 'أدخل كلمة السر لحذف المنتج',
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).deleteProduct(product.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنتج بنجاح')),
        );

        await _loadFilterOptions();
      }
    }
  }
}
