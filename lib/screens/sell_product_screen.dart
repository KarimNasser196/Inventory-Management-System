// lib/screens/sell_product_screen.dart (UPDATED - Fixed Return & Invoice Management)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/invoice.dart';
import 'package:soundtry/screens/invoice_screen.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  double customPrice;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.customPrice,
    this.discount = 0,
  });

  double get subtotal => customPrice * quantity;
  double get priceAfterDiscount => customPrice - (discount / quantity);
  double get total => (customPrice * quantity) - discount;
}

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});
  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();
  late TabController _tabController;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];
  Set<int> _visiblePricesProducts = {};

  List<CartItem> _cart = [];
  bool _isSelling = false;
  final _invoiceSearchController = TextEditingController();
  String _invoiceSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Provider.of<ProductProvider>(context, listen: false).refreshProducts();
    _loadCategories();
  }

  void _loadCategories() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final categories = provider.products
        .where((p) => p.category != null && p.category!.isNotEmpty)
        .map((p) => p.category!)
        .toSet()
        .toList();
    setState(() {
      _availableCategories = categories;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    _invoiceSearchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;
    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }
    return filtered;
  }

  double get _cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _totalDiscounts =>
      _cart.fold(0.0, (sum, item) => sum + item.discount);
  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + item.total);

  void _addToCart(Product product, double price, int quantity) {
    if (quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية المطلوبة أكثر من المتاح')),
      );
      return;
    }

    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _cart[existingIndex].quantity += quantity;
        _cart[existingIndex].customPrice = price;
      } else {
        _cart.add(CartItem(
          product: product,
          quantity: quantity,
          customPrice: price,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة ${product.name} إلى العربة'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _customerNameController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.green,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.add_shopping_cart), text: 'بيع جديد'),
                Tab(icon: Icon(Icons.receipt_long), text: 'الفواتير'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSellTab(isMobile),
                _buildInvoicesListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab(bool isMobile) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredProducts = _getFilteredProducts(provider.products);

        if (isMobile) {
          return _buildMobileSellView(provider, filteredProducts);
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'بحث عن منتج',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              provider.setSearchQuery(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _selectedCategoryFilter,
                            decoration: const InputDecoration(
                              labelText: 'الصنف',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.filter_list),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('الكل')),
                              ..._availableCategories.map((cat) =>
                                  DropdownMenuItem(
                                      value: cat, child: Text(cat))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryFilter = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 450,
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 12,
                              headingRowColor:
                                  MaterialStateProperty.all(Colors.blue[50]),
                              columns: const [
                                DataColumn(label: Text('المنتج')),
                                DataColumn(label: Text('الصنف')),
                                DataColumn(label: Text('المتاح')),
                                DataColumn(label: Text('الأسعار')),
                                DataColumn(label: Text('إضافة')),
                              ],
                              rows: filteredProducts.map((product) {
                                final isPriceVisible =
                                    _visiblePricesProducts.contains(product.id);
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 200),
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(product.category ?? '-')),
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
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        tooltip: 'عرض الأسعار',
                                        onPressed: () =>
                                            _showPricesDialogInTable(product),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.green),
                                        onPressed: product.quantity > 0
                                            ? () =>
                                                _showAddToCartDialog(product)
                                            : null,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: _buildCartSection(),
            ),
          ],
        );
      },
    );
  }

  void _showPricesDialogInTable(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.price_check, color: Colors.blue[700], size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'المتاح: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: product.quantity > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceCard(
              icon: Icons.person,
              title: ' فردي',
              price: product.retailPrice,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPriceCard(
              icon: Icons.group,
              title: ' جملة',
              price: product.wholesalePrice,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildPriceCard(
              icon: Icons.groups,
              title: ' جملة الجملة',
              price: product.bulkWholesalePrice,
              color: Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard({
    required IconData icon,
    required String title,
    required double price,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Text(
            '  ${price.toStringAsFixed(2)} جنيه',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSellView(
      ProductProvider provider, List<Product> filteredProducts) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'بحث عن منتج',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedCategoryFilter,
                decoration: const InputDecoration(
                  labelText: 'الصنف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ..._availableCategories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryFilter = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الصنف: ${product.category ?? '-'}'),
                      Text(
                        'المتاح: ${product.quantity}',
                        style: TextStyle(
                          color:
                              product.quantity > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _visiblePricesProducts.contains(product.id)
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_visiblePricesProducts.contains(product.id)) {
                              _visiblePricesProducts.remove(product.id);
                            } else {
                              _visiblePricesProducts.add(product.id!);
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.green),
                        onPressed: product.quantity > 0
                            ? () => _showAddToCartDialog(product)
                            : null,
                      ),
                    ],
                  ),
                  onTap: () {
                    if (_visiblePricesProducts.contains(product.id)) {
                      _showPricesDialog(product);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (_cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('العربة (${_cart.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_cartTotal.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCartDetails,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('عرض العربة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSelling ? null : _confirmSell,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('إتمام البيع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showPricesDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('سعر فردي'),
              trailing: Text('${product.retailPrice.toStringAsFixed(2)} جنيه'),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('سعر جملة (10+)'),
              trailing:
                  Text('${product.wholesalePrice.toStringAsFixed(2)} جنيه'),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('سعر جملة الجملة (50+)'),
              trailing:
                  Text('${product.bulkWholesalePrice.toStringAsFixed(2)} جنيه'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddToCartDialog(product);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('إضافة للعربة'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showCartDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('عربة التسوق',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'الكمية: ${item.quantity} × ${item.customPrice.toStringAsFixed(2)}'),
                          if (item.discount > 0)
                            Text('خصم: ${item.discount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.red)),
                          Text(
                              'الإجمالي: ${item.total.toStringAsFixed(2)} جنيه',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _removeFromCart(index);
                          });
                          Navigator.pop(context);
                          _showCartDetails();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي النهائي:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${_cartTotal.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(
                          fontSize: 20,
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
  }

  Widget _buildCartSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green,
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              const SizedBox(width: 8),
              Text('عربة التسوق (${_cart.length})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تفريغ العربة'),
                        content: const Text('هل تريد حذف جميع المنتجات؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: () {
                              _clearCart();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('العربة فارغة',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الكمية: ${item.quantity}'),
                                Text(
                                    'السعر: ${item.customPrice.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'المجموع: ${item.subtotal.toStringAsFixed(2)}'),
                                if (item.discount > 0)
                                  Text(
                                      'خصم: ${item.discount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('بعد الخصم:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('${item.total.toStringAsFixed(2)} جنيه',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => _showItemDiscountDialog(item),
                              icon: const Icon(Icons.discount, size: 16),
                              label: Text(item.discount > 0
                                  ? 'تعديل الخصم'
                                  : 'إضافة خصم'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المجموع الفرعي:'),
                          Text('${_cartSubtotal.toStringAsFixed(2)} جنيه',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_totalDiscounts > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي الخصومات:'),
                            Text('${_totalDiscounts.toStringAsFixed(2)} جنيه',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_cartTotal.toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSelling ? null : _confirmSell,
                    icon: _isSelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: const Text('إتمام البيع',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showItemDiscountDialog(CartItem item) {
    final discountController =
        TextEditingController(text: item.discount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خصم على ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المجموع الفرعي: ${item.subtotal.toStringAsFixed(2)} جنيه'),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'قيمة الخصم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount),
                suffixText: 'جنيه',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0;
              if (discount >= 0 && discount <= item.subtotal) {
                setState(() {
                  item.discount = discount;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('الخصم يجب أن يكون أقل من المجموع')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showAddToCartDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final priceController =
        TextEditingController(text: product.retailPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المتاح: ${product.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                  labelText: 'الكمية', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                  suffixText: 'جنيه'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.retailPrice.toStringAsFixed(2);
                    },
                    child: const Text('فردي')),
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.wholesalePrice.toStringAsFixed(2);
                    },
                    child: const Text('جملة')),
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.bulkWholesalePrice.toStringAsFixed(2);
                    },
                    child: const Text('ج.ج')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final price =
                  double.tryParse(priceController.text) ?? product.retailPrice;
              if (quantity > 0 && price > 0) {
                _addToCart(product, price, quantity);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmSell() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('العربة فارغة')));
      return;
    }
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال اسم العميل')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('العميل: ${_customerNameController.text}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              const Text('المنتجات:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._cart.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${item.product.name} × ${item.quantity}',
                            style: const TextStyle(fontSize: 14)),
                        Text(
                            '  ${item.customPrice.toStringAsFixed(2)} جنيه/الوحدة = ${item.subtotal.toStringAsFixed(2)} جنيه',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        if (item.discount > 0)
                          Text(
                              '  خصم: ${item.discount.toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        Text(
                            '  الإجمالي: ${item.total.toStringAsFixed(2)} جنيه',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green)),
                      ],
                    ),
                  )),
              const Divider(thickness: 2),
              Text('المجموع الفرعي: ${_cartSubtotal.toStringAsFixed(2)} جنيه'),
              if (_totalDiscounts > 0)
                Text(
                    'إجمالي الخصومات: ${_totalDiscounts.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(color: Colors.red)),
              Text('الإجمالي: ${_cartTotal.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSale();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    setState(() => _isSelling = true);
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final invoiceNumber = Invoice.generateInvoiceNumber();

      for (var item in _cart) {
        final finalPricePerUnit = item.priceAfterDiscount;

        await provider.sellProductWithCustomPrice(
          item.product,
          item.quantity,
          _customerNameController.text,
          finalPricePerUnit,
          '${_notesController.text.isEmpty ? '' : '${_notesController.text} | '}فاتورة: $invoiceNumber',
        );
      }

      final invoiceItems = _cart
          .map((item) => InvoiceItem(
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.customPrice,
                discount: item.discount,
                purchasePrice: item.product.purchasePrice,
              ))
          .toList();

      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        invoiceDate: DateTime.now(),
        customerName: _customerNameController.text,
        items: invoiceItems,
        tax: 0,
        discount: _totalDiscounts,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تسجيل البيع بنجاح'),
          backgroundColor: Colors.green));

      final shouldPrintInvoice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('تم البيع بنجاح'),
            ],
          ),
          content: const Text('هل تريد عرض وطباعة الفاتورة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لا')),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.receipt),
              label: const Text('عرض الفاتورة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );

      if (shouldPrintInvoice == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => InvoiceScreen(invoice: invoice)));
      }

      _clearCart();
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSelling = false);
    }
  }

  Widget _buildInvoicesListTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.sales.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد فواتير'),
              ],
            ),
          );
        }

        // تجميع الفواتير
        final Map<String, List<dynamic>> groupedSales = {};
        for (var sale in provider.sales) {
          final invoiceNumber = _extractInvoiceNumber(sale.notes);
          if (!groupedSales.containsKey(invoiceNumber)) {
            groupedSales[invoiceNumber] = [];
          }
          groupedSales[invoiceNumber]!.add(sale);
        }

        // تطبيق البحث
        final filteredInvoices = groupedSales.entries.where((entry) {
          if (_invoiceSearchQuery.isEmpty) return true;

          final query = _invoiceSearchQuery.toLowerCase();
          final invoiceNumber = entry.key.toLowerCase();
          final sales = entry.value;
          final customerName = sales.first.customerName.toLowerCase();

          // البحث في رقم الفاتورة
          if (invoiceNumber.contains(query)) return true;

          // البحث في اسم العميل
          if (customerName.contains(query)) return true;

          // البحث في أسماء المنتجات
          for (var sale in sales) {
            if (sale.productName.toLowerCase().contains(query)) {
              return true;
            }
          }

          return false;
        }).toList();

        return Column(
          children: [
            // حقل البحث
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _invoiceSearchController,
                      decoration: InputDecoration(
                        hintText:
                            'ابحث برقم الفاتورة، اسم العميل، أو المنتج...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        suffixIcon: _invoiceSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _invoiceSearchController.clear();
                                    _invoiceSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.green, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _invoiceSearchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // عداد النتائج
            if (_invoiceSearchQuery.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                color: Colors.green[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'النتائج: ${filteredInvoices.length} من ${groupedSales.length} فاتورة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // قائمة الفواتير
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج للبحث',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب البحث بكلمات مختلفة',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _invoiceSearchQuery.isEmpty
                                ? 'الفواتير (${groupedSales.length})'
                                : 'نتائج البحث (${filteredInvoices.length})',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...filteredInvoices.map((entry) {
                            final invoiceNumber = entry.key;
                            final sales = entry.value;
                            final firstSale = sales.first;
                            final totalAmount = sales.fold<double>(
                                0, (sum, s) => sum + s.totalAmount);
                            final totalQuantity = sales.fold<int>(
                                0, (sum, s) => sum + (s.quantitySold as int));

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.receipt,
                                      color: Colors.green[700]),
                                ),
                                title: Text(
                                  'فاتورة $invoiceNumber',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('العميل: ${firstSale.customerName}',
                                        style: const TextStyle(fontSize: 14)),
                                    Text(
                                      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(firstSale.saleDateTime)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${totalAmount.toStringAsFixed(2)} جنيه',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'تفاصيل الفاتورة:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 12),
                                        ...sales.map((sale) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        sale.productName,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'الكمية: ${sale.quantitySold} × ${sale.unitPrice.toStringAsFixed(2)} جنيه',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[700]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.green),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        const Divider(thickness: 2),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('المجموع:',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${totalAmount.toStringAsFixed(2)} جنيه',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.green),
                                                ),
                                                Text(
                                                  'إجمالي القطع: $totalQuantity',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showReturnDialogNew(
                                                      sales, provider),
                                              icon: const Icon(
                                                  Icons.assignment_return,
                                                  color: Colors.orange),
                                              label: const Text('استرجاع'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.orange,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showManageInvoiceDialog(
                                                      invoiceNumber,
                                                      sales,
                                                      provider),
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              label: const Text('إدارة'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showInvoiceForGroup(sales),
                                              icon: const Icon(Icons.receipt),
                                              label: const Text('عرض الفاتورة'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  } // دالة استرجاع محسّنة

  void _showReturnDialogNew(List<dynamic> sales, ProductProvider provider) {
    final Map<int, TextEditingController> quantityControllers = {};
    final Map<int, TextEditingController> reasonControllers = {};

    for (var sale in sales) {
      quantityControllers[sale.id] = TextEditingController(text: '0');
      reasonControllers[sale.id] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('استرجاع من الفاتورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Text(
                    'اختر المنتجات والكمية المراد استرجاعها',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ...sales.map((sale) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sale.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('الكمية المباعة: ${sale.quantitySold}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: quantityControllers[sale.id],
                            decoration: InputDecoration(
                              labelText: 'كمية الاسترجاع *',
                              hintText: 'الحد الأقصى: ${sale.quantitySold}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final qty = int.tryParse(value) ?? 0;
                              if (qty > sale.quantitySold) {
                                quantityControllers[sale.id]!.text =
                                    sale.quantitySold.toString();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'الحد الأقصى: ${sale.quantitySold}'),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reasonControllers[sale.id],
                            decoration: const InputDecoration(
                              labelText: 'سبب الاسترجاع *',
                              hintText: 'اكتب السبب هنا...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool hasReturns = false;
                bool hasErrors = false;

                for (var sale in sales) {
                  final quantity =
                      int.tryParse(quantityControllers[sale.id]!.text) ?? 0;
                  final reason = reasonControllers[sale.id]!.text.trim();

                  if (quantity > 0) {
                    // التحقق من السبب
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'يرجى كتابة سبب الاسترجاع لـ ${sale.productName}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                      continue;
                    }

                    // التحقق من الكمية
                    if (quantity > sale.quantitySold) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'كمية ${sale.productName} أكبر من المباعة (${sale.quantitySold})'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                      continue;
                    }

                    hasReturns = true;
                    try {
                      await provider.returnSale(sale.id, quantity, reason);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('خطأ في استرجاع ${sale.productName}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                    }
                  }
                }

                if (!hasErrors) {
                  Navigator.pop(context);
                }

                if (hasReturns && !hasErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم استرجاع المنتجات بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                } else if (!hasReturns && !hasErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم تحديد أي منتجات للاسترجاع'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('تأكيد الاسترجاع'),
            ),
          ],
        ),
      ),
    );
  } // دالة إدارة الفاتورة

  void _showManageInvoiceDialog(
      String invoiceNumber, List<dynamic> sales, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إدارة فاتورة $invoiceNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('إضافة منتج للفاتورة'),
              onTap: () {
                Navigator.pop(context);
                _showAddProductToInvoiceDialog(invoiceNumber, sales, provider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('حذف الفاتورة بالكامل'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteInvoice(invoiceNumber, sales, provider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // إضافة منتج للفاتورة
  void _showAddProductToInvoiceDialog(
      String invoiceNumber, List<dynamic> sales, ProductProvider provider) {
    Product? selectedProduct;
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة منتج للفاتورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'اختر المنتج',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.products
                      .where((p) => p.quantity > 0)
                      .map((product) => DropdownMenuItem(
                            value: product,
                            child: Text(product.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduct = value;
                      priceController.text =
                          value?.retailPrice.toStringAsFixed(2) ?? '';
                    });
                  },
                ),
                if (selectedProduct != null) ...[
                  const SizedBox(height: 12),
                  Text('المتاح: ${selectedProduct!.quantity}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      border: OutlineInputBorder(),
                      suffixText: 'جنيه',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedProduct == null
                  ? null
                  : () async {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 1;
                      final price = double.tryParse(priceController.text) ??
                          selectedProduct!.retailPrice;

                      if (quantity > selectedProduct!.quantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الكمية المطلوبة أكثر من المتاح')),
                        );
                        return;
                      }

                      try {
                        // استخدام نفس اسم العميل والملاحظات من الفاتورة الأصلية
                        final customerName = sales.first.customerName;
                        final notes = 'فاتورة: $invoiceNumber';

                        await provider.sellProductWithCustomPrice(
                          selectedProduct!,
                          quantity,
                          customerName,
                          price,
                          notes,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت إضافة المنتج للفاتورة بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {});
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // حذف الفاتورة بالكامل
  void _confirmDeleteInvoice(
      String invoiceNumber, List<dynamic> sales, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من حذف هذه الفاتورة بالكامل؟'),
            const SizedBox(height: 8),
            Text('فاتورة: $invoiceNumber',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('سيتم حذف جميع المنتجات المرتبطة بهذه الفاتورة.',
                style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // حذف جميع المبيعات المرتبطة بالفاتورة
                for (var sale in sales) {
                  await provider.deleteSale(sale.id);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الفاتورة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ في الحذف: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _extractInvoiceNumber(String? notes) {
    if (notes == null || notes.isEmpty) return 'غير محدد';
    final match = RegExp(r'فاتورة:\s*(.+?)(?:\||$)').firstMatch(notes);
    return match?.group(1)?.trim() ?? 'غير محدد';
  }

  void _showInvoiceForGroup(List<dynamic> sales) {
    final invoiceItems = sales
        .map((sale) => InvoiceItem(
              productName: sale.productName,
              quantity: sale.quantitySold,
              unitPrice: sale.unitPrice,
              discount: 0,
              purchasePrice: sale.purchasePrice,
            ))
        .toList();

    final invoice = Invoice(
      invoiceNumber: _extractInvoiceNumber(sales.first.notes),
      invoiceDate: sales.first.saleDateTime,
      customerName: sales.first.customerName,
      items: invoiceItems,
      tax: 0,
      discount: 0,
      notes: sales.first.notes?.split('|').first.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InvoiceScreen(invoice: invoice)),
    );
  }
}
