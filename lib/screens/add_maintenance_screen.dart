// lib/screens/add_maintenance_screen.dart (محدث مع حالة "مرفوض" وإخفاء الأسعار)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final MaintenanceRecord? record;

  const AddMaintenanceScreen({super.key, this.record});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deviceTypeController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _problemController;
  late TextEditingController _costController;
  late TextEditingController _paidAmountController;

  String _selectedStatus = 'قيد الإصلاح';
  bool _isSaving = false;
  bool get _isEditing => widget.record != null;

  final List<String> _statusOptions = [
    'قيد الإصلاح',
    'جاهز للاستلام',
    'تم التسليم',
    'ملغي',
    'مرفوض', // ⭐ حالة جديدة
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;

    _deviceTypeController = TextEditingController(
      text: record?.deviceType ?? '',
    );
    _customerNameController = TextEditingController(
      text: record?.customerName ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: record?.customerPhone ?? '',
    );
    _problemController = TextEditingController(
      text: record?.problemDescription ?? '',
    );
    _costController = TextEditingController(
      text: record?.cost.toString() ?? '0',
    );
    _paidAmountController = TextEditingController(
      text: record?.paidAmount.toString() ?? '0',
    );

    if (record != null) {
      _selectedStatus = record.status;
    }
  }

  @override
  void dispose() {
    _deviceTypeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _problemController.dispose();
    _costController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل سجل الصيانة' : 'سجل صيانة جديد'),
        backgroundColor: Colors.blue,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'حذف',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات العميل والجهاز
                  _buildSection(
                      'معلومات العميل والجهاز', Icons.info, Colors.blue, [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _customerNameController,
                            'اسم العميل *',
                            Icons.person_outline,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _customerPhoneController,
                            'رقم الهاتف *',
                            Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _deviceTypeController,
                      'نوع الجهاز *',
                      Icons.devices,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // وصف المشكلة/العطل
                  _buildSection(
                    'وصف العطل',
                    Icons.report_problem,
                    Colors.orange,
                    [
                      _buildTextField(
                        _problemController,
                        'وصف العطل *',
                        Icons.description,
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'مطلوب' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // الحالة
                  _buildSection('الحالة', Icons.flag, Colors.purple, [
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // التكاليف (مخفية - للاستخدام الداخلي فقط)
                  _buildSection(
                    'التكاليف والدفع (داخلي)',
                    Icons.attach_money,
                    Colors.teal,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _costController,
                              'التكلفة',
                              Icons.paid,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final cost = double.tryParse(value);
                                if (cost == null || cost < 0) return 'رقم صحيح';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _paidAmountController,
                              'المبلغ المدفوع',
                              Icons.payment,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المتبقي:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              _calculateRemaining(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showPaymentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة دفعة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // أزرار الحفظ والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _confirmSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('حفظ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
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
                            horizontal: 48,
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
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
      maxLines: maxLines,
      validator: validator,
    );
  }

  String _calculateRemaining() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;
    final remaining = cost - paidAmount;
    return '${remaining.toStringAsFixed(2)} جنيه';
  }

  void _showPaymentDialog() {
    final paymentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المبلغ المتبقي: ${_calculateRemaining()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(paymentController.text);
              if (amount != null && amount > 0) {
                setState(() {
                  final currentPaid =
                      double.tryParse(_paidAmountController.text) ?? 0;
                  _paidAmountController.text =
                      (currentPaid + amount).toString();
                });
                Navigator.pop(context);

                if (_isEditing) {
                  _addPayment(amount);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(double amount) async {
    try {
      final provider = Provider.of<MaintenanceProvider>(context, listen: false);
      await provider.addPayment(widget.record!.id!, amount);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الدفعة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmSave() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isEditing ? 'تأكيد التعديل' : 'تأكيد الحفظ'),
          content: Text(
            _isEditing ? 'هل تريد حفظ التعديلات؟' : 'هل تريد حفظ سجل الصيانة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveRecord();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);

    try {
      final record = MaintenanceRecord(
        id: widget.record?.id,
        deviceType: _deviceTypeController.text,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        problemDescription: _problemController.text,
        status: _selectedStatus,
        cost: double.tryParse(_costController.text) ?? 0,
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0,
        receivedDate: widget.record?.receivedDate ?? DateTime.now(),
      );

      final provider = Provider.of<MaintenanceProvider>(context, listen: false);

      if (_isEditing) {
        await provider.updateMaintenanceRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث سجل الصيانة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await provider.addMaintenanceRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة سجل الصيانة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف سجل الصيانة هذا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecord();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord() async {
    try {
      final provider = Provider.of<MaintenanceProvider>(context, listen: false);
      await provider.deleteMaintenanceRecord(widget.record!.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف سجل الصيانة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
