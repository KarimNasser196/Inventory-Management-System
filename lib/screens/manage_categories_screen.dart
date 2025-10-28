import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/database_helper.dart';
import '../widgets/password_dialog.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Controllers for adding new items
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierPhoneController =
      TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();

  // Lists to store items
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCategories();
    await _loadSuppliers();
    await _loadWarehouses();
  }

  Future<void> _loadCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    setState(() {
      _categories = result;
    });
  }

  Future<void> _loadSuppliers() async {
    final db = await _dbHelper.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    setState(() {
      _suppliers = result;
    });
  }

  Future<void> _loadWarehouses() async {
    final db = await _dbHelper.database;
    final result = await db.query('warehouses', orderBy: 'name ASC');
    setState(() {
      _warehouses = result;
    });
  }

  // Add Category
  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم الصنف'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await _dbHelper.database;
    await db.insert('categories', {
      'name': _categoryController.text,
      'created_at': DateTime.now().toIso8601String(),
    });

    _categoryController.clear();
    await _loadCategories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الصنف بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add Supplier
  Future<void> _addSupplier() async {
    if (_supplierNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المورد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await _dbHelper.database;
    await db.insert('suppliers', {
      'name': _supplierNameController.text,
      'phone': _supplierPhoneController.text,
      'created_at': DateTime.now().toIso8601String(),
    });

    _supplierNameController.clear();
    _supplierPhoneController.clear();
    await _loadSuppliers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المورد بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add Warehouse
  Future<void> _addWarehouse() async {
    if (_warehouseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المخزن'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await _dbHelper.database;
    await db.insert('warehouses', {
      'name': _warehouseController.text,
      'location': '',
      'created_at': DateTime.now().toIso8601String(),
    });

    _warehouseController.clear();
    await _loadWarehouses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المخزن بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Delete item with password confirmation
  Future<void> _deleteItem(String table, int id, String itemName) async {
    // First show password dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PasswordDialog(
        title: 'تأكيد الحذف',
        message: 'أدخل كلمة السر لحذف: $itemName',
      ),
    );

    if (confirmed != true) return;

    try {
      final db = await _dbHelper.database;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);

      // Reload data based on table
      if (table == 'categories') {
        await _loadCategories();
      } else if (table == 'suppliers') {
        await _loadSuppliers();
      } else if (table == 'warehouses') {
        await _loadWarehouses();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit item with password confirmation
  Future<void> _editItem(String table, int id, String currentName,
      {String? currentPhone}) async {
    // First show password dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PasswordDialog(
        title: 'تأكيد التعديل',
        message: 'أدخل كلمة السر للتعديل',
      ),
    );

    if (confirmed != true) return;

    // Show edit dialog
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController phoneController =
        TextEditingController(text: currentPhone ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(),
              ),
            ),
            if (table == 'suppliers') ...[
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'phone': phoneController.text,
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null || result['name']!.isEmpty) return;

    try {
      final db = await _dbHelper.database;
      if (table == 'suppliers') {
        await db.update(
          table,
          {
            'name': result['name'],
            'phone': result['phone'],
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.update(
          table,
          {'name': result['name']},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // Reload data
      if (table == 'categories') {
        await _loadCategories();
      } else if (table == 'suppliers') {
        await _loadSuppliers();
      } else if (table == 'warehouses') {
        await _loadWarehouses();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التعديل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التعديل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البيانات الأساسية'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأصناف', icon: Icon(Icons.category)),
            Tab(text: 'الموردين', icon: Icon(Icons.store)),
            Tab(text: 'المخازن', icon: Icon(Icons.warehouse)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildSuppliersTab(),
          _buildWarehousesTab(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'اسم الصنف',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
        ),
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد أصناف',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            color: Colors.purple[700],
                          ),
                        ),
                        title: Text(
                          category['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'categories',
                                category['id'],
                                category['name'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'categories',
                                category['id'],
                                category['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSuppliersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _supplierNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المورد',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _supplierPhoneController,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _addSupplier,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
            ],
          ),
        ),
        Expanded(
          child: _suppliers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد موردين',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _suppliers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.green[700],
                          ),
                        ),
                        title: Text(
                          supplier['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: supplier['phone'] != null &&
                                supplier['phone'].toString().isNotEmpty
                            ? Text(
                                'الهاتف: ${supplier['phone']}',
                                style: const TextStyle(fontSize: 14),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'suppliers',
                                supplier['id'],
                                supplier['name'],
                                currentPhone: supplier['phone']?.toString(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'suppliers',
                                supplier['id'],
                                supplier['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWarehousesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _warehouseController,
                  decoration: InputDecoration(
                    labelText: 'اسم المخزن',
                    prefixIcon: const Icon(Icons.warehouse),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _addWarehouse(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addWarehouse,
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
        ),
        Expanded(
          child: _warehouses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warehouse, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد مخازن',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warehouse,
                            color: Colors.blue[700],
                          ),
                        ),
                        title: Text(
                          warehouse['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'warehouses',
                                warehouse['id'],
                                warehouse['name'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'warehouses',
                                warehouse['id'],
                                warehouse['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
