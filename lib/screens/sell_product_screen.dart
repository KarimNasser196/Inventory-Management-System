import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

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
  double? _customPrice;
  bool _isSelling = false;
  final _searchController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false).refreshProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                            style: Theme.of(context).textTheme.headlineSmall
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
                                    if (price == null || price <= 0)
                                      return 'خطأ';
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
                          DataColumn(label: Text('سعر الشراء')),
                          DataColumn(label: Text('فردي')),
                          DataColumn(label: Text('جملة')),
                          DataColumn(label: Text('جملة جملة')),
                        ],
                        rows: provider.products.map((product) {
                          final isSelected = _selectedProduct?.id == product.id;
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
                            onSelectChanged: (selected) {
                              setState(() {
                                _selectedProduct = selected == true
                                    ? product
                                    : null;
                                if (selected == true) {
                                  _searchController.text = product.name;
                                  _priceController.text = product.retailPrice
                                      .toStringAsFixed(2);
                                  _customPrice = product.retailPrice;
                                }
                              });
                            },
                            cells: [
                              DataCell(
                                Radio<int?>(
                                  value: product.id,
                                  groupValue: _selectedProduct?.id,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProduct = product;
                                      _searchController.text = product.name;
                                      _priceController.text = product
                                          .retailPrice
                                          .toStringAsFixed(2);
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
                                Text(product.purchasePrice.toStringAsFixed(2)),
                              ),
                              DataCell(
                                Text(product.retailPrice.toStringAsFixed(2)),
                              ),
                              DataCell(
                                Text(product.wholesalePrice.toStringAsFixed(2)),
                              ),
                              DataCell(
                                Text(
                                  product.bulkWholesalePrice.toStringAsFixed(2),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل البيع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSelling = false);
    }
  }
}
