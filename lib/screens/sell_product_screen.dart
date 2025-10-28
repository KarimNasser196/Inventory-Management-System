// lib/screens/sell_product_screen.dart (FIXED PROFIT CALCULATION)

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
  double discount; // إضافة خصم لكل منتج

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.customPrice,
    this.discount = 0,
  });

  double get subtotal => customPrice * quantity;
  double get total => subtotal - discount;
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
  final _discountController = TextEditingController(text: '0');
  late TabController _tabController;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];
  Set<int> _visiblePricesProducts = {};

  List<CartItem> _cart = [];
  bool _isSelling = false;

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
    _discountController.dispose();
    _tabController.dispose();
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
      _cart.fold(0.0, (sum, item) => sum + item.discount) +
      (double.tryParse(_discountController.text) ?? 0);
  double get _cartTotal => _cartSubtotal - _totalDiscounts;

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
      _discountController.text = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Tab(icon: Icon(Icons.receipt_long), text: 'المبيعات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSellTab(),
                _buildSalesListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredProducts = _getFilteredProducts(provider.products);

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
                          child: DataTable(
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
                                  DataCell(Text(product.name)),
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
                                    Row(
                                      children: [
                                        if (isPriceVisible)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                    'شراء: ${product.purchasePrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                Text(
                                                    'فردي: ${product.retailPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                Text(
                                                    'جملة: ${product.wholesalePrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                Text(
                                                    'ج.ج: ${product.bulkWholesalePrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                              isPriceVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.blue),
                                          onPressed: () {
                                            setState(() {
                                              if (isPriceVisible) {
                                                _visiblePricesProducts
                                                    .remove(product.id);
                                              } else {
                                                _visiblePricesProducts
                                                    .add(product.id!);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart,
                                          color: Colors.green),
                                      onPressed: product.quantity > 0
                                          ? () => _showAddToCartDialog(product)
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
                ],
              ),
            ),
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
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
                            icon: const Icon(Icons.delete_sweep,
                                color: Colors.white),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تفريغ العربة'),
                                  content:
                                      const Text('هل تريد حذف جميع المنتجات؟'),
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
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600])),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            onPressed: () =>
                                                _removeFromCart(index),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('الكمية: ${item.quantity}'),
                                          Text(
                                              'السعر: ${item.customPrice.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'المجموع: ${item.subtotal.toStringAsFixed(2)}'),
                                          if (item.discount > 0)
                                            Text(
                                              'خصم: ${item.discount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'الإجمالي:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${item.total.toStringAsFixed(2)} جنيه',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showItemDiscountDialog(item),
                                        icon: const Icon(Icons.discount,
                                            size: 16),
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
                            controller: _discountController,
                            decoration: const InputDecoration(
                              labelText: 'خصم إضافي على الفاتورة',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.discount),
                              suffixText: 'جنيه',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {}),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المجموع الفرعي:'),
                                    Text(
                                        '${_cartSubtotal.toStringAsFixed(2)} جنيه',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (_totalDiscounts > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('إجمالي الخصومات:'),
                                      Text(
                                          '${_totalDiscounts.toStringAsFixed(2)} جنيه',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red)),
                                    ],
                                  ),
                                ],
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('الإجمالي:',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        '${_cartTotal.toStringAsFixed(2)} جنيه',
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
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
              Text('العميل: ${_customerNameController.text}'),
              const Divider(),
              const Text('المنتجات:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._cart.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '• ${item.product.name} × ${item.quantity} = ${item.subtotal.toStringAsFixed(2)} جنيه'),
                        if (item.discount > 0)
                          Text(
                              '  خصم المنتج: ${item.discount.toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  )),
              const Divider(),
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

      // حساب الخصم الإضافي على الفاتورة موزع على المنتجات
      final invoiceDiscount = double.tryParse(_discountController.text) ?? 0;

      for (var item in _cart) {
        // حساب نسبة هذا المنتج من المجموع الفرعي
        final itemRatio = item.subtotal / _cartSubtotal;
        // توزيع الخصم الإضافي حسب النسبة
        final distributedDiscount = invoiceDiscount * itemRatio;
        // السعر النهائي بعد كل الخصومات
        final finalPrice =
            (item.subtotal - item.discount - distributedDiscount) /
                item.quantity;

        await provider.sellProductWithCustomPrice(
          item.product,
          item.quantity,
          _customerNameController.text,
          finalPrice,
          _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      final invoiceItems = _cart
          .map((item) => InvoiceItem(
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.customPrice,
              ))
          .toList();

      final invoice = Invoice(
        invoiceNumber: Invoice.generateInvoiceNumber(),
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

  Widget _buildSalesListTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.sales.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد مبيعات'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.green[50]),
                columns: const [
                  DataColumn(label: Text('المنتج')),
                  DataColumn(label: Text('العميل')),
                  DataColumn(label: Text('الكمية')),
                  DataColumn(label: Text('سعر الوحدة')),
                  DataColumn(label: Text('الإجمالي')),
                  DataColumn(label: Text('الربح الصافي')),
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('إجراءات')),
                ],
                rows: provider.sales.map((sale) {
                  // الربح الصافي = (سعر البيع - سعر الشراء) × الكمية
                  final netProfit =
                      (sale.unitPrice - sale.purchasePrice) * sale.quantitySold;

                  return DataRow(
                    cells: [
                      DataCell(Text(sale.productName)),
                      DataCell(Text(sale.customerName)),
                      DataCell(Text('${sale.quantitySold}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                          Text('${sale.unitPrice.toStringAsFixed(2)} جنيه')),
                      DataCell(Text(
                          '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${netProfit.toStringAsFixed(2)} جنيه',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: netProfit > 0
                                        ? Colors.green
                                        : netProfit < 0
                                            ? Colors.red
                                            : Colors.orange)),
                            if (netProfit == 0)
                              const Text('(بعد الخصم)',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.orange)),
                          ],
                        ),
                      ),
                      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm')
                          .format(sale.saleDateTime))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.receipt,
                                    color: Colors.blue),
                                tooltip: 'عرض الفاتورة',
                                onPressed: () => _showInvoiceForSale(sale)),
                            IconButton(
                                icon: const Icon(Icons.reply,
                                    color: Colors.orange),
                                tooltip: 'استرجاع',
                                onPressed: () => _showReturnDialog(sale)),
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
      },
    );
  }

  void _showReturnDialog(sale) {
    final quantityController =
        TextEditingController(text: sale.quantitySold.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع منتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المنتج: ${sale.productName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('العميل: ${sale.customerName}'),
              Text('الكمية المباعة: ${sale.quantitySold}'),
              const SizedBox(height: 16),
              TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                      labelText: 'كمية الاسترجاع',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                      labelText: 'سبب الاسترجاع', border: OutlineInputBorder()),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              final reason = reasonController.text.trim();
              if (quantity == null ||
                  quantity <= 0 ||
                  quantity > sale.quantitySold ||
                  reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تحقق من البيانات المدخلة')));
                return;
              }
              Navigator.pop(context);
              try {
                await Provider.of<ProductProvider>(context, listen: false)
                    .returnSale(sale.id!, quantity, reason);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم الاسترجاع بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceForSale(sale) {
    final invoiceItems = [
      InvoiceItem(
        productName: sale.productName,
        quantity: sale.quantitySold,
        unitPrice: sale.unitPrice,
      ),
    ];

    final invoice = Invoice(
      invoiceNumber: 'INV-${sale.id}',
      invoiceDate: sale.saleDateTime,
      customerName: sale.customerName,
      items: invoiceItems,
      tax: 0,
      discount: 0,
      notes: sale.notes,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(invoice: invoice),
      ),
    );
  }
}
