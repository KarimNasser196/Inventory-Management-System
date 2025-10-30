// lib/screens/add_representative_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';

class AddRepresentativeScreen extends StatefulWidget {
  final Representative? representative; // للتعديل

  const AddRepresentativeScreen({Key? key, this.representative})
      : super(key: key);

  @override
  State<AddRepresentativeScreen> createState() =>
      _AddRepresentativeScreenState();
}

class _AddRepresentativeScreenState extends State<AddRepresentativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'مندوب'; // 'مندوب' أو 'عميل'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.representative != null) {
      _nameController.text = widget.representative!.name;
      _phoneController.text = widget.representative!.phone ?? '';
      _addressController.text = widget.representative!.address ?? '';
      _notesController.text = widget.representative!.notes ?? '';
      _selectedType = widget.representative!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.representative != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل ${_selectedType}' : 'إضافة ${_selectedType} جديد'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildAddressField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSaveButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النوع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'مندوب',
                  label: Text('مندوب'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment(
                  value: 'عميل',
                  label: Text('عميل'),
                  icon: Icon(Icons.people),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: widget.representative == null
                  ? (Set<String> selection) {
                      setState(() {
                        _selectedType = selection.first;
                      });
                    }
                  : null, // لا يمكن تغيير النوع عند التعديل
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'الاسم *',
        hintText: 'أدخل اسم ${_selectedType}',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال الاسم';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'رقم الهاتف',
        hintText: '01xxxxxxxxx',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: 'العنوان',
        hintText: 'أدخل العنوان',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 2,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'ملاحظات',
        hintText: 'أي ملاحظات إضافية',
        prefixIcon: const Icon(Icons.notes_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveRepresentative,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              isEditing ? 'حفظ التعديلات' : 'إضافة ${_selectedType}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _saveRepresentative() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);

      final representative = Representative(
        id: widget.representative?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        type: _selectedType,
        totalDebt: widget.representative?.totalDebt ?? 0.0,
        totalPaid: widget.representative?.totalPaid ?? 0.0,
        createdAt: widget.representative?.createdAt,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      bool success;
      if (widget.representative == null) {
        success = await provider.addRepresentative(representative);
      } else {
        success = await provider.updateRepresentative(representative);
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.representative == null
                    ? 'تم إضافة $_selectedType بنجاح'
                    : 'تم تحديث $_selectedType بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ، الرجاء المحاولة مرة أخرى'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
