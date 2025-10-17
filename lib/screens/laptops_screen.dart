import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/return.dart';
import 'package:soundtry/models/sale.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
  String _selectedStatus = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Laptop> _filterLaptops(List<Laptop> laptops) {
    if (_selectedStatus == 'الكل') {
      return laptops;
    }
    return laptops.where((laptop) => laptop.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: IconButton(
            onPressed: () {
              Provider.of<LaptopProvider>(context, listen: false).resetData();
            },
            icon: Icon(Icons.delete),
          ),
        ),
        title: const Text('الأجهزة'),
        actions: [
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
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      Provider.of<LaptopProvider>(
                        context,
                        listen: false,
                      ).setSearchQuery(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter and Add button row
                  if (isMobile)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LaptopFormScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة جهاز جديد'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LaptopFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'إضافة جهاز جديد',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Consumer<LaptopProvider>(
              builder: (context, laptopProvider, child) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        'الكل',
                        laptopProvider.laptops.length,
                        Colors.grey,
                        _selectedStatus == 'الكل',
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'متاح',
                        laptopProvider.availableLaptopsCount,
                        Colors.green,
                        _selectedStatus == AppConstants.statusAvailable,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'مباع',
                        laptopProvider.soldLaptopsCount,
                        Colors.blue,
                        _selectedStatus == AppConstants.statusSold,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'مرتجع',
                        laptopProvider.returnedLaptopsCount,
                        Colors.orange,
                        _selectedStatus == AppConstants.statusReturned,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Laptops list/grid
          Expanded(
            child: Consumer<LaptopProvider>(
              builder: (context, laptopProvider, child) {
                if (laptopProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredLaptops = _filterLaptops(laptopProvider.laptops);

                if (filteredLaptops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.laptop_mac_sharp,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد أجهزة',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _isGridView
                    ? _buildGridView(filteredLaptops, isMobile, isTablet)
                    : _buildListView(filteredLaptops);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label == 'الكل' ? 'الكل' : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.grey[200],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Laptop> laptops, bool isMobile, bool isTablet) {
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 1.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptops[index];
        return LaptopCard(laptop: laptop);
      },
    );
  }

  Widget _buildListView(List<Laptop> laptops) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            laptop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${laptop.model} - ${laptop.serialNumber}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(laptop.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السعر: ${laptop.price.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaptopFormScreen(laptop: laptop),
                                ),
                              );
                            },
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, laptop),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 20),
                          if (laptop.status != AppConstants.statusReturned)
                            IconButton(
                              icon: const Icon(
                                Icons.replay,
                                color: Colors.orange,
                                size: 22,
                              ),
                              onPressed: () {
                                if (laptop.status ==
                                    AppConstants.statusAvailable) {
                                  _showSaleDialog(context, laptop);
                                } else if (laptop.status ==
                                    AppConstants.statusSold) {
                                  _showReturnDialog(context, laptop);
                                }
                              },
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ],
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
      label: Text(status, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      avatar: Icon(icon, color: color, size: 14),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
