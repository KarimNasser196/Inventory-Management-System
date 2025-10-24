import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundtry/screens/cat_screen.dart';
import 'dart:convert';
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
  late TextEditingController _modelController;
  late TextEditingController _specController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _bulkWholesalePriceController;
  late TextEditingController _supplierController;
  late TextEditingController _quantityController;
  late TextEditingController _warehouseController;

  String? _selectedCategory;
  List<String> _categories = [];
  bool _isSaveHovered = false;
  bool _isSaving = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
    _warehouseController = TextEditingController(
      text: widget.product?.warehouse ?? '',
    );
    _selectedCategory = widget.product?.category;
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('categories') ?? '[]';
    setState(() {
      _categories = List<String>.from(json.decode(categoriesJson));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _specController.dispose();
    _purchasePriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _bulkWholesalePriceController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منتج' : 'إضافة منتج جديد'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              _loadCategories();
            },
            tooltip: 'إدارة الأصناف',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلومات المنتج',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 20 : 24,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // الصف الأول: الاسم، الصنف، المخزن، المورد
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _nameController,
                                  'اسم المنتج',
                                  Icons.shopping_bag,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'الصنف',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  value: _selectedCategory,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('-- اختر --'),
                                    ),
                                    ..._categories.map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _warehouseController,
                                  'المخزن',
                                  Icons.warehouse,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _supplierController,
                                  'المورد',
                                  Icons.store,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // الصف الثاني: الموديل، المواصفات، الكمية
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _modelController,
                                  'الموديل',
                                  Icons.devices,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  _specController,
                                  'المواصفات',
                                  Icons.description,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _quantityController,
                                  'الكمية',
                                  Icons.inventory,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final qty = int.tryParse(value ?? '');
                                    if (qty == null || qty < 0) {
                                      return 'رقم إيجابي';
                                    }
                                    return null;
                                  },
                                ),
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

                          // صف الأسعار
                          Row(
                            children: [
                              Expanded(
                                child: _buildPriceField(
                                  _purchasePriceController,
                                  'سعر الشراء',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPriceField(
                                  _retailPriceController,
                                  'سعر البيع (فردي)',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPriceField(
                                  _wholesalePriceController,
                                  'سعر الجملة',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPriceField(
                                  _bulkWholesalePriceController,
                                  'سعر جملة الجملة',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isSaveHovered = true),
                                onExit: (_) =>
                                    setState(() => _isSaveHovered = false),
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _confirmSave,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: const Text('حفظ'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    backgroundColor: _isSaveHovered
                                        ? Colors.green[700]
                                        : Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.cancel),
                                label: const Text('إلغاء'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
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
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      keyboardType: keyboardType,
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'مطلوب';
        final price = double.tryParse(value);
        if (price == null || price <= 0) return 'سعر موجب';
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
            _isEditing ? 'هل تريد حفظ التعديلات؟' : 'هل تريد إضافة المنتج؟',
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
      category: _selectedCategory,
      warehouse: _warehouseController.text.isEmpty
          ? null
          : _warehouseController.text,
      model: _modelController.text.isEmpty ? null : _modelController.text,
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
        _nameController.clear();
        _modelController.clear();
        _specController.clear();
        _purchasePriceController.clear();
        _retailPriceController.clear();
        _wholesalePriceController.clear();
        _bulkWholesalePriceController.clear();
        _supplierController.clear();
        _quantityController.clear();
        _warehouseController.clear();
        setState(() => _selectedCategory = null);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
