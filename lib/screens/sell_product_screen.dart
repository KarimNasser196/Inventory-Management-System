import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/invoice.dart';
import 'package:soundtry/screens/invoice_screen.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});
  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int _quantity = 1;
  String _customerName = '';
  String? _notes;
  double? _customPrice;
  bool _isSelling = false;
  final _searchController = TextEditingController();
  final _priceController = TextEditingController();
  late TabController _tabController;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];
  Set<int> _visiblePricesProducts = {}; // لتتبع المنتجات التي تم إظهار أسعارها

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
    _priceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
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
              children: [_buildSellTab(isMobile), _buildSalesListTab(isMobile)],
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

        return Column(
          children: [
            // نموذج البيع
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              color: Colors.grey[50],
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل بيع جديد',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المنتج',
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
                                    value: null,
                                    child: Text('الكل'),
                                  ),
                                  ..._availableCategories.map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryFilter = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'الكمية',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: '1',
                                onChanged: (value) {
                                  setState(() {
                                    _quantity = int.tryParse(value) ?? 1;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'مطلوب';
                                  final qty = int.tryParse(value);
                                  if (qty == null || qty <= 0) return 'خطأ';
                                  if (_selectedProduct != null &&
                                      qty > _selectedProduct!.quantity) {
                                    return 'أكثر من المتاح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'السعر',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _customPrice = double.tryParse(value);
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'مطلوب';
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) return 'خطأ';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'اسم العميل',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _customerName = value;
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'مطلوب'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isSelling ? null : _confirmSell,
                              icon: _isSelling
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sell),
                              label: const Text('بيع'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
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
            ),
            // جدول المنتجات
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Card(
                  elevation: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.blue[50],
                      ),
                      columns: const [
                        DataColumn(label: Text('اختيار')),
                        DataColumn(label: Text('الاسم')),
                        DataColumn(label: Text('الصنف')),
                        DataColumn(label: Text('المخزن')),
                        DataColumn(label: Text('المورد')),
                        DataColumn(label: Text('الكمية')),
                        DataColumn(label: Text('الأسعار')),
                      ],
                      rows: filteredProducts.map((product) {
                        final isSelected = _selectedProduct?.id == product.id;
                        final isPriceVisible = _visiblePricesProducts.contains(
                          product.id,
                        );

                        return DataRow(
                          selected: isSelected,
                          color: MaterialStateProperty.resolveWith<Color?>((
                            Set<MaterialState> states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue.withOpacity(0.2);
                            }
                            return null;
                          }),
                          cells: [
                            DataCell(
                              Radio<int?>(
                                value: product.id,
                                groupValue: _selectedProduct?.id,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProduct = product;
                                    _searchController.text = product.name;
                                    _priceController.text =
                                        product.retailPrice.toStringAsFixed(2);
                                    _customPrice = product.retailPrice;
                                  });
                                },
                              ),
                            ),
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
                              Row(
                                children: [
                                  if (isPriceVisible)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'شراء: ${product.purchasePrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'فردي: ${product.retailPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'جملة: ${product.wholesalePrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ج.ج: ${product.bulkWholesalePrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      isPriceVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isPriceVisible) {
                                          _visiblePricesProducts.remove(
                                            product.id,
                                          );
                                        } else {
                                          _visiblePricesProducts.add(
                                            product.id!,
                                          );
                                        }
                                      });
                                    },
                                    tooltip: isPriceVisible
                                        ? 'إخفاء الأسعار'
                                        : 'إظهار الأسعار',
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesListTab(bool isMobile) {
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
          padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                  DataColumn(label: Text('الربح')),
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('إجراءات')),
                  DataColumn(label: Text('فاتورة')),
                ],
                rows: provider.sales.map((sale) {
                  final profit =
                      (sale.unitPrice - sale.purchasePrice) * sale.quantitySold;
                  return DataRow(
                    cells: [
                      DataCell(Text(sale.productName)),
                      DataCell(Text(sale.customerName)),
                      DataCell(
                        Text(
                          '${sale.quantitySold}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text('${sale.unitPrice.toStringAsFixed(2)} جنيه'),
                      ),
                      DataCell(
                        Text(
                          '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
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
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(sale.saleDateTime),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.reply, color: Colors.orange),
                          tooltip: 'استرجاع',
                          onPressed: () => _showReturnDialog(sale),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.receipt, color: Colors.blue),
                              tooltip: 'عرض الفاتورة',
                              onPressed: () => _showInvoiceForSale(sale),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.reply, color: Colors.orange),
                              tooltip: 'استرجاع',
                              onPressed: () => _showReturnDialog(sale),
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
      },
    );
  }

  void _showReturnDialog(sale) {
    final quantityController = TextEditingController(
      text: sale.quantitySold.toString(),
    );
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
              Text(
                'المنتج: ${sale.productName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('العميل: ${sale.customerName}'),
              Text('الكمية المباعة: ${sale.quantitySold}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'كمية الاسترجاع',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'سبب الاسترجاع',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
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
              final quantity = int.tryParse(quantityController.text);
              final reason = reasonController.text.trim();

              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال كمية صحيحة')),
                );
                return;
              }

              if (quantity > sale.quantitySold) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'الكمية المسترجعة لا يمكن أن تكون أكثر من ${sale.quantitySold}',
                    ),
                  ),
                );
                return;
              }

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال سبب الاسترجاع')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final provider = Provider.of<ProductProvider>(
                  context,
                  listen: false,
                );
                await provider.returnSale(sale.id!, quantity, reason);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الاسترجاع بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
  }

  void _confirmSell() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار منتج')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المنتج: ${_selectedProduct!.name}'),
              Text('الكمية: $_quantity'),
              Text('السعر: ${_customPrice!.toStringAsFixed(2)} جنيه'),
              Text(
                'الإجمالي: ${(_customPrice! * _quantity).toStringAsFixed(2)} جنيه',
              ),
              Text('العميل: $_customerName'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sellProduct();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    }
  }

  void _sellProduct() async {
    setState(() => _isSelling = true);

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.sellProductWithCustomPrice(
        _selectedProduct!,
        _quantity,
        _customerName,
        _customPrice!,
        _notes,
      );

      // إنشاء الفاتورة
      final invoiceItems = [
        InvoiceItem(
          productName: _selectedProduct!.name,
          quantity: _quantity,
          unitPrice: _customPrice!,
        ),
      ];

      final invoice = Invoice(
        invoiceNumber: Invoice.generateInvoiceNumber(),
        invoiceDate: DateTime.now(),
        customerName: _customerName,
        items: invoiceItems,
        tax: 0, // يمكن إضافة حقل للضريبة في النموذج
        discount: 0, // يمكن إضافة حقل للخصم في النموذج
        notes: _notes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل البيع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // إظهار حوار لسؤال المستخدم إذا كان يريد طباعة الفاتورة
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
              child: const Text('لا'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.receipt),
              label: const Text('عرض الفاتورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );

      if (shouldPrintInvoice == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceScreen(invoice: invoice),
          ),
        );
      }

      // إعادة تعيين النموذج
      _formKey.currentState!.reset();
      setState(() {
        _selectedProduct = null;
        _quantity = 1;
        _customerName = '';
        _notes = null;
        _customPrice = null;
        _isSelling = false;
        _searchController.clear();
        _priceController.clear();
      });
      provider.setSearchQuery('');
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSelling = false);
    }
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
