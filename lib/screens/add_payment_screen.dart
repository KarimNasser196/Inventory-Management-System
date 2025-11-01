// lib/screens/add_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AddPaymentScreen extends StatefulWidget {
  final Representative representative;

  const AddPaymentScreen({super.key, required this.representative});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _payFullAmount = false;

  @override
  void initState() {
    super.initState();
    if (widget.representative.remainingDebt > 0) {
      _amountController.text =
          widget.representative.remainingDebt.toStringAsFixed(2);
      _payFullAmount = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة دفعة'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildRepresentativeInfo(numberFormat),
              const SizedBox(height: 24),
              _buildPayFullAmountSwitch(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildCalculationCard(numberFormat),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepresentativeInfo(NumberFormat numberFormat) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: widget.representative.type == 'مندوب'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    widget.representative.type == 'مندوب'
                        ? Icons.person
                        : Icons.people,
                    size: 32,
                    color: widget.representative.type == 'مندوب'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.representative.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.representative.type,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  'إجمالي الديون',
                  '${numberFormat.format(widget.representative.totalDebt)} جنيه',
                  Colors.orange,
                ),
                _buildInfoItem(
                  'المدفوع',
                  '${numberFormat.format(widget.representative.totalPaid)} جنيه',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المتبقي:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${numberFormat.format(widget.representative.remainingDebt)} جنيه',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayFullAmountSwitch() {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: const Text('دفع المبلغ الكامل'),
        subtitle: const Text('سداد كامل المديونية'),
        value: _payFullAmount,
        activeThumbColor: Colors.green,
        onChanged: (value) {
          setState(() {
            _payFullAmount = value;
            if (value) {
              _amountController.text =
                  widget.representative.remainingDebt.toStringAsFixed(2);
            }
          });
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'المبلغ المدفوع *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.payments),
        suffixText: 'جنيه',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green.shade50,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (value) {
        setState(() {
          _payFullAmount = false;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال المبلغ';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'الرجاء إدخال مبلغ صحيح';
        }
        if (amount > widget.representative.remainingDebt) {
          return 'المبلغ أكبر من المتبقي';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'ملاحظات',
        hintText: 'أي ملاحظات إضافية',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
    );
  }

  Widget _buildCalculationCard(NumberFormat numberFormat) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final remaining = widget.representative.remainingDebt - amount;

    return Card(
      elevation: 2,
      color: remaining > 0 ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'ملخص الدفعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildCalculationRow(
              'المتبقي الحالي',
              numberFormat.format(widget.representative.remainingDebt),
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildCalculationRow(
              'المبلغ المدفوع',
              numberFormat.format(amount),
              Colors.green,
            ),
            const Divider(height: 16),
            _buildCalculationRow(
              'المتبقي بعد الدفع',
              numberFormat.format(remaining.clamp(0, double.infinity)),
              remaining > 0 ? Colors.orange : Colors.green,
              isBold: true,
            ),
            if (remaining <= 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'سيتم سداد المديونية بالكامل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '$value جنيه',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _savePayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
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
          : const Text(
              'تسجيل الدفعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);

      final success = await provider.addPayment(
        representativeId: widget.representative.id!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدفعة بنجاح'),
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
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
