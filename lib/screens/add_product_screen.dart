// lib/screens/add_product_screen.dart (FIXED)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _modelController; // FIX: Added model controller
  late TextEditingController _specController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _bulkWholesalePriceController;
  late TextEditingController _supplierController;
  late TextEditingController _quantityController;
  bool _isSaveHovered = false;
  bool _isSaving = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _modelController = TextEditingController(text: widget.product?.model ?? '');
    _specController = TextEditingController(
      text: widget.product?.specifications ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice.toString() ?? '',
    );
    _retailPriceController = TextEditingController(
      text: widget.product?.retailPrice.toString() ?? '',
    );
    _wholesalePriceController = TextEditingController(
      text: widget.product?.wholesalePrice.toString() ?? '',
    );
    _bulkWholesalePriceController = TextEditingController(
      text: widget.product?.bulkWholesalePrice.toString() ?? '',
    );
    _supplierController = TextEditingController(
      text: widget.product?.supplierName ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose(); // FIX: Dispose model controller
    _specController.dispose();
    _purchasePriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _bulkWholesalePriceController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    super.dispose();
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
            onInvoke: (intent) => _confirmSave(),
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
              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: FocusScope(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing ? 'تعديل منتج' : 'إضافة منتج جديد',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 24 : 32,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'معلومات المنتج',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 20 : 24,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: 5,
                                  children: [
                                    _buildTextField(
                                      _nameController,
                                      'اسم المنتج',
                                      Icons.shopping_bag,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'الرجاء إدخال اسم المنتج'
                                          : null,
                                    ),
                                    _buildTextField(
                                      _modelController, // FIX: Added model field
                                      'الصنف ',
                                      Icons.category,
                                    ),
                                    _buildTextField(
                                      _specController,
                                      'المواصفات',
                                      Icons.description,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                    _buildTextField(
                                      _supplierController,
                                      'اسم المورد',
                                      Icons.store,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'الرجاء إدخال اسم المورد'
                                          : null,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  'الأسعار',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 20 : 24,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                isMobile
                                    ? Column(
                                        children: [
                                          _buildPriceField(
                                            _purchasePriceController,
                                            'سعر الشراء',
                                          ),
                                          const SizedBox(height: 12),
                                          _buildPriceField(
                                            _retailPriceController,
                                            'سعر البيع (فردي)',
                                          ),
                                          const SizedBox(height: 12),
                                          _buildPriceField(
                                            _wholesalePriceController,
                                            'سعر الجملة',
                                          ),
                                          const SizedBox(height: 12),
                                          _buildPriceField(
                                            _bulkWholesalePriceController,
                                            'سعر جملة الجملة',
                                          ),
                                        ],
                                      )
                                    : GridView.count(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 24,
                                        childAspectRatio: 2,
                                        children: [
                                          _buildPriceField(
                                            _purchasePriceController,
                                            'سعر الشراء',
                                          ),
                                          _buildPriceField(
                                            _retailPriceController,
                                            'سعر البيع (فردي)',
                                          ),
                                          _buildPriceField(
                                            _wholesalePriceController,
                                            'سعر الجملة',
                                          ),
                                          _buildPriceField(
                                            _bulkWholesalePriceController,
                                            'سعر جملة الجملة',
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  _quantityController,
                                  'الكمية',
                                  Icons.inventory,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final qty = int.tryParse(value ?? '');
                                    if (qty == null || qty < 0) {
                                      return 'الرجاء إدخال كمية صالحة (رقم إيجابي)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _isSaveHovered = true),
                                      onExit: (_) => setState(
                                        () => _isSaveHovered = false,
                                      ),
                                      child: Semantics(
                                        label: 'حفظ المنتج',
                                        child: ElevatedButton.icon(
                                          onPressed: _isSaving
                                              ? null
                                              : _confirmSave,
                                          icon: _isSaving
                                              ? const CircularProgressIndicator()
                                              : const Icon(Icons.save),
                                          label: const Text('حفظ'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            backgroundColor: _isSaveHovered
                                                ? Colors.green[700]
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    MouseRegion(
                                      onEnter: (_) => setState(() {}),
                                      onExit: (_) => setState(() {}),
                                      child: Semantics(
                                        label: 'إلغاء',
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                    ),
                                  ],
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال $label';
        }
        final price = double.tryParse(value);
        if (price == null) {
          return 'الرجاء إدخال رقم صحيح';
        }
        // FIX: Validate that price is positive (greater than 0)
        if (price <= 0) {
          return 'الرجاء إدخال سعر موجب (أكبر من 0)';
        }
        return null;
      },
    );
  }

  void _confirmSave() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isEditing ? 'تأكيد التعديل' : 'تأكيد الإضافة'),
          content: Text(
            _isEditing
                ? 'هل تريد حفظ التعديلات على المنتج؟'
                : 'هل تريد إضافة المنتج؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveProduct();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    }
  }

  void _saveProduct() async {
    setState(() => _isSaving = true);
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      model: _modelController.text.isEmpty
          ? null
          : _modelController.text, // FIX: Handle model field
      specifications: _specController.text.isEmpty
          ? null
          : _specController.text,
      purchasePrice: double.parse(_purchasePriceController.text),
      retailPrice: double.parse(_retailPriceController.text),
      wholesalePrice: double.parse(_wholesalePriceController.text),
      bulkWholesalePrice: double.parse(_bulkWholesalePriceController.text),
      supplierName: _supplierController.text,
      quantity: int.parse(_quantityController.text),
    );
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      if (_isEditing) {
        await provider.updateProduct(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث المنتج بنجاح')));
      } else {
        await provider.addProduct(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة المنتج بنجاح')));
        // Clear form after adding new product
        _nameController.clear();
        _modelController.clear(); // FIX: Clear model field
        _specController.clear();
        _purchasePriceController.clear();
        _retailPriceController.clear();
        _wholesalePriceController.clear();
        _bulkWholesalePriceController.clear();
        _supplierController.clear();
        _quantityController.clear();
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      // FIX: Always clear loading state
      setState(() => _isSaving = false);
    }
  }
}
