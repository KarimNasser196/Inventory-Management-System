import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/laptop.dart';
import '../providers/laptop_provider.dart';
import '../utils/constants.dart';

class LaptopFormScreen extends StatefulWidget {
  final Laptop? laptop;
  
  const LaptopFormScreen({super.key, this.laptop});

  @override
  State<LaptopFormScreen> createState() => _LaptopFormScreenState();
}

class _LaptopFormScreenState extends State<LaptopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _serialNumberController;
  late TextEditingController _modelController;
  late TextEditingController _priceController;
  late TextEditingController _customerController;
  late TextEditingController _notesController;
  
  String _status = AppConstants.statusAvailable;
  DateTime? _date;
  
  bool get _isEditing => widget.laptop != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.laptop?.name ?? '');
    _serialNumberController = TextEditingController(text: widget.laptop?.serialNumber ?? '');
    _modelController = TextEditingController(text: widget.laptop?.model ?? '');
    _priceController = TextEditingController(
        text: widget.laptop?.price.toString() ?? '');
    _customerController = TextEditingController(text: widget.laptop?.customer ?? '');
    _notesController = TextEditingController(text: widget.laptop?.notes ?? '');
    
    // Set initial values if editing
    if (_isEditing) {
      _status = widget.laptop!.status;
      _date = widget.laptop!.date;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل جهاز' : 'إضافة جهاز جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'اسم الجهاز',
                        icon: Icons.laptop,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال اسم الجهاز';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Serial Number field
                      _buildTextField(
                        controller: _serialNumberController,
                        label: 'الرقم التسلسلي',
                        icon: Icons.numbers,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الرقم التسلسلي';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Model field
                      _buildTextField(
                        controller: _modelController,
                        label: 'الموديل',
                        icon: Icons.devices,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الموديل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Price field
                      _buildTextField(
                        controller: _priceController,
                        label: 'السعر',
                        icon: Icons.attach_money,
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
                      
                      // Status dropdown
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'الحالة',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: AppConstants.statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _status = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Customer field (visible if status is sold)
                      if (_status == AppConstants.statusSold)
                        Column(
                          children: [
                            _buildTextField(
                              controller: _customerController,
                              label: 'اسم المشتري',
                              icon: Icons.person,
                              validator: (value) {
                                if (_status == AppConstants.statusSold &&
                                    (value == null || value.isEmpty)) {
                                  return 'الرجاء إدخال اسم المشتري';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Date picker
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'التاريخ',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _date == null
                                      ? 'اختر التاريخ'
                                      : DateFormat('yyyy-MM-dd').format(_date!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      
                      // Notes field
                      _buildTextField(
                        controller: _notesController,
                        label: 'ملاحظات',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('إلغاء'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _saveLaptop,
                            icon: const Icon(Icons.save),
                            label: const Text('حفظ'),
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveLaptop() {
    if (_formKey.currentState!.validate()) {
      final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
      
      // Create laptop object
      final laptop = Laptop(
        id: widget.laptop?.id,
        name: _nameController.text,
        serialNumber: _serialNumberController.text,
        model: _modelController.text,
        price: double.parse(_priceController.text),
        status: _status,
        customer: _status == AppConstants.statusSold ? _customerController.text : null,
        date: _status == AppConstants.statusSold ? (_date ?? DateTime.now()) : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      // Save laptop
      if (_isEditing) {
        laptopProvider.updateLaptop(laptop);
      } else {
        laptopProvider.addLaptop(laptop);
      }
      
      Navigator.pop(context);
    }
  }
}
