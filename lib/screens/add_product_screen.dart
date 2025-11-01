import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../utils/responsive.dart';
import '../widgets/password_dialog.dart';

class AddProductScreenUpdated extends StatefulWidget {
  final Product? product;

  const AddProductScreenUpdated({super.key, this.product});

  @override
  State<AddProductScreenUpdated> createState() =>
      _AddProductScreenUpdatedState();
}

class _AddProductScreenUpdatedState extends State<AddProductScreenUpdated> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isEditing = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _specificationsController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _bulkWholesalePriceController;
  late TextEditingController _quantityController;

  // Focus nodes for Enter navigation
  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _warehouseFocus = FocusNode();
  final _supplierFocus = FocusNode();
  final _specificationsFocus = FocusNode();
  final _purchasePriceFocus = FocusNode();
  final _retailPriceFocus = FocusNode();
  final _wholesalePriceFocus = FocusNode();
  final _bulkWholesalePriceFocus = FocusNode();
  final _quantityFocus = FocusNode();

  // Dropdown data loaded from database
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _suppliers = [];

  String? _selectedCategory;
  String? _selectedWarehouse;
  String? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    // Initialize controllers
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _specificationsController =
        TextEditingController(text: widget.product?.specifications ?? '');
    _purchasePriceController = TextEditingController(
        text: widget.product?.purchasePrice.toString() ?? '');
    _retailPriceController = TextEditingController(
        text: widget.product?.retailPrice.toString() ?? '');
    _wholesalePriceController = TextEditingController(
        text: widget.product?.wholesalePrice.toString() ?? '');
    _bulkWholesalePriceController = TextEditingController(
        text: widget.product?.bulkWholesalePrice.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.product?.quantity.toString() ?? '');

    _selectedCategory = widget.product?.category;
    _selectedWarehouse = widget.product?.warehouse;
    _selectedSupplier = widget.product?.supplierName;

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final db = await _dbHelper.database;

    // Load categories
    final categoriesResult = await db.query('categories', orderBy: 'name ASC');

    // Load warehouses
    final warehousesResult = await db.query('warehouses', orderBy: 'name ASC');

    // Load suppliers
    final suppliersResult = await db.query('suppliers', orderBy: 'name ASC');

    setState(() {
      _categories = categoriesResult;
      _warehouses = warehousesResult;
      _suppliers = suppliersResult;
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _specificationsController.dispose();
    _purchasePriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _bulkWholesalePriceController.dispose();
    _quantityController.dispose();

    // Dispose focus nodes
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _warehouseFocus.dispose();
    _supplierFocus.dispose();
    _specificationsFocus.dispose();
    _purchasePriceFocus.dispose();
    _retailPriceFocus.dispose();
    _wholesalePriceFocus.dispose();
    _bulkWholesalePriceFocus.dispose();
    _quantityFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل منتج' : 'إضافة منتج جديد',
          style: TextStyle(fontSize: Responsive.font(20)),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: Responsive.paddingAll(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card with icon
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(16)),
                ),
                child: Padding(
                  padding: Responsive.paddingAll(20),
                  child: Row(
                    children: [
                      Container(
                        padding: Responsive.paddingAll(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius:
                              BorderRadius.circular(Responsive.radius(12)),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.blue[700],
                          size: Responsive.icon(32),
                        ),
                      ),
                      Responsive.hBox(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'تعديل بيانات المنتج' : 'منتج جديد',
                              style: TextStyle(
                                fontSize: Responsive.font(20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Responsive.vBox(4),
                            Text(
                              'الرجاء ملء جميع الحقول المطلوبة',
                              style: TextStyle(
                                fontSize: Responsive.font(14),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Responsive.vBox(24),

              // Basic Information Section
              _buildSectionCard(
                title: 'المعلومات الأساسية',
                icon: Icons.info_outline,
                color: Colors.blue,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _categoryFocus,
                    label: 'اسم المنتج',
                    icon: Icons.inventory_2,
                    hint: 'أدخل اسم المنتج',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المنتج';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  Responsive.vBox(16),
                  _buildDropdown(
                    label: 'الصنف',
                    icon: Icons.category,
                    value: _selectedCategory,
                    items: _categories
                        .map((cat) => DropdownMenuItem<String>(
                              value: cat['name'].toString(),
                              child: Text(cat['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار الصنف';
                      }
                      return null;
                    },
                  ),
                  Responsive.vBox(16),
                  _buildDropdown(
                    label: 'المخزن',
                    icon: Icons.warehouse,
                    value: _selectedWarehouse,
                    items: _warehouses
                        .map((warehouse) => DropdownMenuItem<String>(
                              value: warehouse['name'].toString(),
                              child: Text(warehouse['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWarehouse = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المخزن';
                      }
                      return null;
                    },
                  ),
                  Responsive.vBox(16),
                  _buildDropdown(
                    label: 'المورد',
                    icon: Icons.store,
                    value: _selectedSupplier,
                    items: _suppliers
                        .map((supplier) => DropdownMenuItem<String>(
                              value: supplier['name'].toString(),
                              child: Text(supplier['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplier = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المورد';
                      }
                      return null;
                    },
                  ),
                  Responsive.vBox(16),
                  _buildTextField(
                    controller: _specificationsController,
                    focusNode: _specificationsFocus,
                    nextFocus: _purchasePriceFocus,
                    label: 'المواصفات',
                    icon: Icons.description,
                    hint: 'أدخل مواصفات المنتج',
                    maxLines: 3,
                  ),
                ],
              ),

              Responsive.vBox(24),

              // Prices Section
              _buildSectionCard(
                title: 'الأسعار',
                icon: Icons.attach_money,
                color: Colors.green,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _purchasePriceController,
                          focusNode: _purchasePriceFocus,
                          nextFocus: _retailPriceFocus,
                          label: 'سعر الشراء',
                          icon: Icons.shopping_cart,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'مطلوب';
                            }
                            if (double.tryParse(value) == null) {
                              return 'رقم غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text(
                            'جنيه',
                            style: TextStyle(fontSize: Responsive.font(14)),
                          ),
                        ),
                      ),
                      Responsive.hBox(12),
                      Expanded(
                        child: _buildTextField(
                          controller: _retailPriceController,
                          focusNode: _retailPriceFocus,
                          nextFocus: _wholesalePriceFocus,
                          label: 'سعر البيع (فردي)',
                          icon: Icons.sell,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'مطلوب';
                            }
                            if (double.tryParse(value) == null) {
                              return 'رقم غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text(
                            'جنيه',
                            style: TextStyle(fontSize: Responsive.font(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Responsive.vBox(16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _wholesalePriceController,
                          focusNode: _wholesalePriceFocus,
                          nextFocus: _bulkWholesalePriceFocus,
                          label: 'سعر  الجملة ',
                          icon: Icons.shopping_basket,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'مطلوب';
                            }
                            if (double.tryParse(value) == null) {
                              return 'رقم غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text(
                            'جنيه',
                            style: TextStyle(fontSize: Responsive.font(14)),
                          ),
                        ),
                      ),
                      Responsive.hBox(12),
                      Expanded(
                        child: _buildTextField(
                          controller: _bulkWholesalePriceController,
                          focusNode: _bulkWholesalePriceFocus,
                          nextFocus: _quantityFocus,
                          label: 'سعر جملة الجملة',
                          icon: Icons.store,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'مطلوب';
                            }
                            if (double.tryParse(value) == null) {
                              return 'رقم غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text(
                            'جنيه',
                            style: TextStyle(fontSize: Responsive.font(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Responsive.vBox(24),

              // Stock Section
              _buildSectionCard(
                title: 'المخزون',
                icon: Icons.inventory,
                color: Colors.purple,
                children: [
                  _buildTextField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    label: 'الكمية المتاحة',
                    icon: Icons.numbers,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الكمية';
                      }
                      if (int.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _saveProduct(),
                  ),
                ],
              ),

              Responsive.vBox(32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: Responsive.icon(20)),
                      label: Text(
                        'إلغاء',
                        style: TextStyle(fontSize: Responsive.font(16)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: Responsive.paddingSym(v: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Responsive.radius(12)),
                        ),
                      ),
                    ),
                  ),
                  Responsive.hBox(16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: Icon(Icons.check, size: Responsive.icon(20)),
                      label: Text(
                        _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                        style: TextStyle(fontSize: Responsive.font(16)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: Responsive.paddingSym(v: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Responsive.radius(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Responsive.vBox(16),

              // Helper text
              Center(
                child: Text(
                  'نصيحة: اضغط Enter للانتقال إلى الحقل التالي',
                  style: TextStyle(
                    fontSize: Responsive.font(12),
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: Responsive.icon(24)),
                Responsive.hBox(12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.font(18),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Responsive.vBox(20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffix,
    bool autofocus = false,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: Responsive.font(14)),
        hintText: hint,
        hintStyle: TextStyle(fontSize: Responsive.font(14)),
        prefixIcon: Icon(icon, size: Responsive.icon(20)),
        suffix: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: Responsive.paddingSym(h: 16, v: 16),
      ),
      style: TextStyle(fontSize: Responsive.font(15)),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted ??
          (nextFocus != null ? (_) => nextFocus.requestFocus() : null),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: Responsive.font(14)),
        prefixIcon: Icon(icon, size: Responsive.icon(20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: Responsive.paddingSym(h: 16, v: 16),
      ),
      style: TextStyle(fontSize: Responsive.font(15), color: Colors.black),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _saveProduct() async {
    // للتعديل، نتحقق من كلمة السر أولاً
    if (_isEditing) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const PasswordDialog(
          title: 'تأكيد التعديل',
          message: 'أدخل كلمة السر لتعديل المنتج',
        ),
      );

      if (confirmed != true) return;
    }

    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text,
        category: _selectedCategory,
        warehouse: _selectedWarehouse,
        supplierName: _selectedSupplier!,
        specifications: _specificationsController.text.isNotEmpty
            ? _specificationsController.text
            : null,
        purchasePrice: double.parse(_purchasePriceController.text),
        retailPrice: double.parse(_retailPriceController.text),
        wholesalePrice: double.parse(_wholesalePriceController.text),
        bulkWholesalePrice: double.parse(_bulkWholesalePriceController.text),
        quantity: int.parse(_quantityController.text),
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);

      if (_isEditing) {
        provider.updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث المنتج بنجاح',
              style: TextStyle(fontSize: Responsive.font(14)),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        provider.addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة المنتج بنجاح',
              style: TextStyle(fontSize: Responsive.font(14)),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    }
  }
}
