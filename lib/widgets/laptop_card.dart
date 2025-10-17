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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    laptop.name,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(laptop.status),
              ],
            ),
            const SizedBox(height: 8),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('الموديل:', laptop.model),
                  const SizedBox(height: 4),
                  _buildDetailRow('المواصفات:', laptop.serialNumber, isSmall: true),
                  const SizedBox(height: 4),
                  _buildDetailRow(
                    'السعر:',
                    '${laptop.price} جنيه',
                    isBold: true,
                    isPrice: true,
                  ),
                  if (laptop.status == AppConstants.statusSold &&
                      laptop.customer != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'المشتري:',
                          laptop.customer!,
                          isSmall: true,
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaptopFormScreen(laptop: laptop),
                      ),
                    );
                  },
                  tooltip: 'تعديل',
                  isMobile: isMobile,
                ),
                const SizedBox(width: 2),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'حذف',
                  isMobile: isMobile,
                ),
                if (laptop.status != AppConstants.statusReturned)
                  const SizedBox(width: 2),
                if (laptop.status != AppConstants.statusReturned)
                  _buildActionButton(
                    icon: Icons.replay,
                    color: Colors.orange,
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
                    isMobile: isMobile,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isSmall = false,
    bool isPrice = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 11 : 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isPrice ? Colors.green : Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isMobile,
  }) {
    return SizedBox(
      width: isMobile ? 36 : 40,
      height: isMobile ? 36 : 40,
      child: IconButton(
        icon: Icon(icon, size: isMobile ? 18 : 20),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
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
      label: Text(
        status,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
      avatar: Icon(icon, color: color, size: 14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 300),
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
