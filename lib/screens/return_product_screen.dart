import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ReturnProductScreen extends StatefulWidget {
  const ReturnProductScreen({super.key});

  @override
  State<ReturnProductScreen> createState() => _ReturnProductScreenState();
}

class _ReturnProductScreenState extends State<ReturnProductScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int _quantity = 1;
  String _returnReason = '';
  String? _notes;

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
            onInvoke: (intent) => _returnProduct(),
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
                return const Center(
                  child: Text('لا توجد منتجات متاحة للإرجاع'),
                );
              }
              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: FocusScope(
                          child: Form(
                            key: _formKey,
                            child: isMobile
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: _buildFormFields(
                                            context,
                                            provider,
                                            isMobile,
                                          ).sublist(0, 2),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: _buildFormFields(
                                            context,
                                            provider,
                                            isMobile,
                                          ).sublist(2),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
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
    return [
      Text(
        'إرجاع منتج',
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
          return DropdownMenuItem(value: product, child: Text(product.name));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProduct = value;
            _quantity = 1;
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
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return 'يرجى إدخال الكمية';
          final qty = int.tryParse(value);
          if (qty == null || qty <= 0) return 'الكمية يجب أن تكون أكبر من 0';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'سبب الإرجاع',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.warning),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        onChanged: (value) {
          _returnReason = value;
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'يرجى إدخال سبب الإرجاع' : null,
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
              onPressed: _returnProduct,
              icon: const Icon(Icons.assignment_return),
              label: const Text('تسجيل الإرجاع'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 16),
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.cancel),
              label: const Text('إلغاء'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _returnProduct() {
    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        provider.returnProduct(_selectedProduct!, _quantity, _returnReason);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الإرجاع بنجاح للمنتج ${_selectedProduct!.name}',
            ),
            action: SnackBarAction(
              label: 'عرض التفاصيل',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تفاصيل الإرجاع'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('المنتج', _selectedProduct!.name),
                        _buildDetailItem('الكمية', '$_quantity'),
                        _buildDetailItem('سبب الإرجاع', _returnReason),
                        if (_notes != null)
                          _buildDetailItem('ملاحظات', _notes!),
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
            ),
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedProduct = null;
          _quantity = 1;
          _returnReason = '';
          _notes = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء تسجيل الإرجاع: $e')));
      }
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
