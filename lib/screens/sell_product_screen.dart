// lib/screens/sell_product_screen.dart - WITH RETURN COUNTER

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});
  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int _quantity = 1;
  String _customerName = '';
  String? _notes;
  String _priceType = 'فردي';
  bool _isSelling = false;

  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false).refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) => _confirmSell(),
          ),
        },
        child: Scaffold(
          body: Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.errorMessage != null) {
                return Center(child: Text('خطأ: ${provider.errorMessage}'));
              }
              if (provider.products.isEmpty) {
                return const Center(child: Text('لا توجد منتجات متاحة للبيع'));
              }
              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: FocusScope(
                              child: Form(
                                key: _formKey,
                                child: isMobile
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _buildFormFields(
                                          context,
                                          provider,
                                          isMobile,
                                        ),
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: _buildFormFields(
                                                context,
                                                provider,
                                                isMobile,
                                              ).sublist(0, 3),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: _buildFormFields(
                                                context,
                                                provider,
                                                isMobile,
                                              ).sublist(3),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'آخر المبيعات (${provider.sales.length})',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 20 : 24,
                              ),
                        ),
                        const SizedBox(height: 16),
                        provider.sales.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('لا توجد مبيعات بعد'),
                                ),
                              )
                            : isMobile
                            ? _buildSalesList(
                                context,
                                provider.getRecentSales(limit: 10),
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
                                itemCount: provider
                                    .getRecentSales(limit: 10)
                                    .length,
                                itemBuilder: (context, index) {
                                  final sale = provider.getRecentSales(
                                    limit: 10,
                                  )[index];
                                  return _buildSaleCard(
                                    context,
                                    sale,
                                    provider,
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(
    BuildContext context,
    ProductProvider provider,
    bool isMobile,
  ) {
    final double? selectedPrice = _selectedProduct != null
        ? _priceType == 'فردي'
              ? _selectedProduct!.retailPrice
              : _priceType == 'جملة'
              ? _selectedProduct!.wholesalePrice
              : _selectedProduct!.bulkWholesalePrice
        : null;

    return [
      Text(
        'تسجيل بيع جديد',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 24 : 32,
        ),
      ),
      const SizedBox(height: 24),
      DropdownButtonFormField<Product>(
        decoration: InputDecoration(
          labelText: 'اختر المنتج',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.inventory),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        value: _selectedProduct,
        items: provider.products.map((product) {
          return DropdownMenuItem(
            value: product,
            child: Text(
              '${product.name}${product.model != null ? ' (${product.model})' : ''}',
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProduct = value;
            _quantity = 1;
            _priceType = value != null ? value.getPriceType(1) : 'فردي';
          });
        },
        validator: (value) => value == null ? 'يرجى اختيار منتج' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'الكمية',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.format_list_numbered),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        keyboardType: TextInputType.number,
        initialValue: '1',
        onChanged: (value) {
          setState(() {
            _quantity = int.tryParse(value) ?? 1;
            if (_selectedProduct != null) {
              _priceType = _selectedProduct!.getPriceType(_quantity);
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return 'يرجى إدخال الكمية';
          final qty = int.tryParse(value);
          if (qty == null || qty <= 0) return 'الكمية يجب أن تكون أكبر من 0';
          if (_selectedProduct != null && qty > _selectedProduct!.quantity) {
            return 'الكمية المدخلة أكبر من المخزون المتاح (${_selectedProduct!.quantity})';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'اسم العميل',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        onChanged: (value) {
          _customerName = value;
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'يرجى إدخال اسم العميل' : null,
      ),
      const SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'نوع السعر',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.price_check),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            value: _priceType,
            items: const [
              DropdownMenuItem(value: 'فردي', child: Text('فردي')),
              DropdownMenuItem(value: 'جملة', child: Text('جملة')),
              DropdownMenuItem(value: 'جملة جملة', child: Text('جملة جملة')),
            ],
            onChanged: (value) {
              setState(() {
                _priceType = value!;
              });
            },
          ),
          if (_selectedProduct != null && selectedPrice != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'سعر $_priceType: ${selectedPrice.toStringAsFixed(2)} جنيه',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'ملاحظات (اختياري)',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.note),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        maxLines: 3,
        onChanged: (value) {
          _notes = value.isEmpty ? null : value;
        },
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: ElevatedButton.icon(
              onPressed: _isSelling ? null : _confirmSell,
              icon: _isSelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sell),
              label: const Text('تسجيل البيع'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    ];
  }

  Widget _buildSaleCard(
    BuildContext context,
    SaleTransaction sale,
    ProductProvider provider,
  ) {
    // حساب عدد الاسترجاعات لهذا البيع
    final returnCount = provider.inventoryTransactions
        .where(
          (tx) =>
              tx.transactionType == 'استرجاع من بيع' &&
              tx.relatedSaleId == sale.id.toString(),
        )
        .length;

    final totalReturned = provider.inventoryTransactions
        .where(
          (tx) =>
              tx.transactionType == 'استرجاع من بيع' &&
              tx.relatedSaleId == sale.id.toString(),
        )
        .fold<int>(0, (sum, tx) => sum + tx.quantityChange);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('تفاصيل البيع: ${sale.productName}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('المنتج', sale.productName),
                        _buildDetailItem(
                          'الكمية المباعة',
                          '${sale.quantitySold}',
                        ),
                        _buildDetailItem('اسم العميل', sale.customerName),
                        _buildDetailItem('نوع السعر', sale.priceType),
                        _buildDetailItem(
                          'سعر الوحدة',
                          '${sale.unitPrice.toStringAsFixed(2)} جنيه',
                        ),
                        _buildDetailItem(
                          'الإجمالي',
                          '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                        ),
                        if (returnCount > 0) ...[
                          const Divider(),
                          _buildDetailItem('عدد الاسترجاعات', '$returnCount'),
                          _buildDetailItem('إجمالي المسترجع', '$totalReturned'),
                        ],
                        if (sale.notes != null)
                          _buildDetailItem('ملاحظات', sale.notes!),
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
              },
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
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          // عرض معلومات الاسترجاع
                          if (returnCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'تم استرجاع $totalReturned ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الكمية: ${sale.quantitySold}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${sale.priceType}: ${sale.unitPrice.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showReturnDialog(context, sale, provider),
                    icon: const Icon(Icons.reply, color: Colors.orange),
                    label: const Text(
                      'استرجاع',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(
    BuildContext context,
    SaleTransaction sale,
    ProductProvider provider,
  ) {
    int returnQuantity = 1;
    String returnReason = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('استرجاع المنتج'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المنتج: ${sale.productName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'الكمية المباعة: ${sale.quantitySold}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'كمية الاسترجاع',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    helperText: 'من 1 إلى ${sale.quantitySold}',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    returnQuantity = int.tryParse(value) ?? 1;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'سبب الاسترجاع',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.warning),
                    hintText: 'مثال: عيب في المنتج، عدم رضا العميل، إلخ',
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    returnReason = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (returnQuantity <= 0 || returnQuantity > sale.quantitySold) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'الكمية يجب أن تكون بين 1 و ${sale.quantitySold}',
                      ),
                    ),
                  );
                  return;
                }

                if (returnReason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سبب الاسترجاع')),
                  );
                  return;
                }

                try {
                  await provider.returnSale(
                    sale.id!,
                    returnQuantity,
                    returnReason,
                  );

                  Navigator.pop(context);

                  String message = returnQuantity == sale.quantitySold
                      ? 'تم حذف البيع من السجلات نهائياً'
                      : 'تم استرجاع $returnQuantity من ${sale.productName}';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
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
              icon: const Icon(Icons.reply),
              label: const Text('تأكيد الاسترجاع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(BuildContext context, List<SaleTransaction> sales) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sales.length,
          itemBuilder: (context, index) =>
              _buildSaleCard(context, sales[index], provider),
        );
      },
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

  void _confirmSell() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد البيع'),
          content: Text(
            'هل تريد تسجيل بيع ${_quantity} من ${_selectedProduct!.name} لـ $_customerName؟',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جارٍ تسجيل البيع...'),
          ],
        ),
      ),
    );
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.sellProduct(
        _selectedProduct!,
        _quantity,
        _customerName,
        _notes,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل البيع بنجاح للمنتج ${_selectedProduct!.name}',
          ),
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedProduct = null;
        _quantity = 1;
        _customerName = '';
        _notes = null;
        _priceType = 'فردي';
        _isSelling = false;
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      setState(() => _isSelling = false);
    }
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
}
