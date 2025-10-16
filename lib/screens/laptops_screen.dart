import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/return.dart';
import 'package:soundtry/models/sale.dart';
import '../models/laptop.dart';
import '../providers/laptop_provider.dart';
import '../utils/constants.dart';
import '../widgets/laptop_card.dart';
import 'laptop_form_screen.dart';

class LaptopsScreen extends StatefulWidget {
  const LaptopsScreen({super.key});

  @override
  State<LaptopsScreen> createState() => _LaptopsScreenState();
}

class _LaptopsScreenState extends State<LaptopsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة'),
        actions: [
          // Toggle view
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Add bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      Provider.of<LaptopProvider>(
                        context,
                        listen: false,
                      ).setSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaptopFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة جهاز جديد'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Laptops list/grid
          Expanded(
            child: Consumer<LaptopProvider>(
              builder: (context, laptopProvider, child) {
                if (laptopProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (laptopProvider.laptops.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد أجهزة مسجلة',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return _isGridView
                    ? _buildGridView(laptopProvider)
                    : _buildListView(laptopProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(LaptopProvider laptopProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: laptopProvider.laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptopProvider.laptops[index];
        return LaptopCard(laptop: laptop);
      },
    );
  }

  Widget _buildListView(LaptopProvider laptopProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: laptopProvider.laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptopProvider.laptops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              laptop.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${laptop.model} - ${laptop.serialNumber}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(laptop.status),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaptopFormScreen(laptop: laptop),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, laptop),
                ),
                if (laptop.status != AppConstants.statusReturned)
                  IconButton(
                    icon: const Icon(Icons.replay, color: Colors.orange),
                    onPressed: () {
                      if (laptop.status == AppConstants.statusAvailable) {
                        _showSaleDialog(context, laptop);
                      } else if (laptop.status == AppConstants.statusSold) {
                        _showReturnDialog(context, laptop);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case AppConstants.statusAvailable:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AppConstants.statusSold:
        color = Colors.blue;
        icon = Icons.shopping_cart;
        break;
      case AppConstants.statusReturned:
        color = Colors.orange;
        icon = Icons.replay;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      avatar: Icon(icon, color: color, size: 16),
    );
  }

  void _confirmDelete(BuildContext context, Laptop laptop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الجهاز "${laptop.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<LaptopProvider>(
                context,
                listen: false,
              ).deleteLaptop(laptop.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showSaleDialog(BuildContext context, Laptop laptop) {
    final customerController = TextEditingController();
    final priceController = TextEditingController(
      text: laptop.price.toString(),
    );
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بيع الجهاز'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: customerController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشتري',
                    icon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم المشتري';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    icon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    icon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final sale = Sale(
                  laptopId: laptop.id!,
                  customerName: customerController.text,
                  price: double.parse(priceController.text),
                  date: DateTime.now(),
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );

                Provider.of<LaptopProvider>(
                  context,
                  listen: false,
                ).sellLaptop(laptop, sale);

                Navigator.pop(context);
              }
            },
            child: const Text('بيع'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, Laptop laptop) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع الجهاز'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'سبب الاسترجاع',
                  icon: Icon(Icons.help_outline),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال سبب الاسترجاع';
                  }
                  return null;
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
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final returnData = Return(
                  laptopId: laptop.id!,
                  date: DateTime.now(),
                  reason: reasonController.text,
                );

                Provider.of<LaptopProvider>(
                  context,
                  listen: false,
                ).returnLaptop(laptop, returnData);

                Navigator.pop(context);
              }
            },
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
  }
}
