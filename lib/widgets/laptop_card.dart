import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/laptop.dart';
import '../models/return.dart';
import '../models/sale.dart';
import '../providers/laptop_provider.dart';
import '../screens/laptop_form_screen.dart';
import '../utils/constants.dart';

class LaptopCard extends StatelessWidget {
  final Laptop laptop;

  const LaptopCard({super.key, required this.laptop});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    laptop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(laptop.status),
              ],
            ),
            const Divider(),
            Text('الموديل: ${laptop.model}'),
            const SizedBox(height: 4),
            Text('الرقم التسلسلي: ${laptop.serialNumber}'),
            const SizedBox(height: 4),
            Text('السعر: ${laptop.price} جنيه'),
            if (laptop.status == AppConstants.statusSold &&
                laptop.customer != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('المشتري: ${laptop.customer}'),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaptopFormScreen(laptop: laptop),
                      ),
                    );
                  },
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'حذف',
                ),
                if (laptop.status != AppConstants.statusReturned)
                  IconButton(
                    icon: const Icon(
                      Icons.replay,
                      color: Colors.orange,
                      size: 20,
                    ),
                    onPressed: () {
                      if (laptop.status == AppConstants.statusAvailable) {
                        _showSaleDialog(context);
                      } else if (laptop.status == AppConstants.statusSold) {
                        _showReturnDialog(context);
                      }
                    },
                    tooltip: laptop.status == AppConstants.statusAvailable
                        ? 'بيع'
                        : 'استرجاع',
                  ),
              ],
            ),
          ],
        ),
      ),
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

  void _confirmDelete(BuildContext context) {
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

  void _showSaleDialog(BuildContext context) {
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

  void _showReturnDialog(BuildContext context) {
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
