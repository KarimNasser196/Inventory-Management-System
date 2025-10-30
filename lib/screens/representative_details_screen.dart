// lib/screens/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:soundtry/screens/add_payment_screen.dart';
import 'package:intl/intl.dart';

class RepresentativeDetailsScreen extends StatefulWidget {
  final Representative representative;

  const RepresentativeDetailsScreen({Key? key, required this.representative})
      : super(key: key);

  @override
  State<RepresentativeDetailsScreen> createState() =>
      _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState
    extends State<RepresentativeDetailsScreen> {
  List<RepresentativeTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final provider =
        Provider.of<RepresentativeProvider>(context, listen: false);
    final transactions =
        await provider.getTransactions(widget.representative.id!);
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.representative.name),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRepresentativeScreen(
                    representative: widget.representative,
                  ),
                ),
              );
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Column(
          children: [
            _buildAccountSummary(),
            _buildActionButtons(),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSummary() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');
    final hasDebt = widget.representative.hasDebt;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: widget.representative.type == 'مندوب'
                  ? Colors.blue.shade100
                  : Colors.green.shade100,
              child: Icon(
                widget.representative.type == 'مندوب'
                    ? Icons.person
                    : Icons.people,
                size: 48,
                color: widget.representative.type == 'مندوب'
                    ? Colors.blue
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.representative.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(widget.representative.type),
              backgroundColor: widget.representative.type == 'مندوب'
                  ? Colors.blue.shade100
                  : Colors.green.shade100,
            ),
            if (widget.representative.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    widget.representative.phone!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'إجمالي الديون',
                  '${numberFormat.format(widget.representative.totalDebt)} جنيه',
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'إجمالي المدفوع',
                  '${numberFormat.format(widget.representative.totalPaid)} جنيه',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasDebt ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'المتبقي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${numberFormat.format(widget.representative.remainingDebt)} جنيه',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasDebt ? 'عليه دين' : 'مسدد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.representative.hasDebt
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPaymentScreen(
                            representative: widget.representative,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        await _loadTransactions();
                        Provider.of<RepresentativeProvider>(context,
                                listen: false)
                            .loadRepresentatives();
                      }
                    }
                  : null,
              icon: const Icon(Icons.payment),
              label: const Text('إضافة دفعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _printStatement,
              icon: const Icon(Icons.print),
              label: const Text('كشف حساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد معاملات',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم عرض جميع المعاملات هنا',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];

        Color iconColor;
        IconData icon;
        Color cardColor;

        switch (transaction.type) {
          case 'بيع':
            iconColor = Colors.blue;
            icon = Icons.shopping_cart;
            cardColor = Colors.blue.shade50;
            break;
          case 'دفعة':
            iconColor = Colors.green;
            icon = Icons.payment;
            cardColor = Colors.green.shade50;
            break;
          case 'مرتجع':
            iconColor = Colors.orange;
            icon = Icons.keyboard_return;
            cardColor = Colors.orange.shade50;
            break;
          default:
            iconColor = Colors.grey;
            icon = Icons.info;
            cardColor = Colors.grey.shade50;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.2),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.getTypeInArabic(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                          Text(
                            transaction.getFormattedDateTime(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${numberFormat.format(transaction.amount)} جنيه',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                        if (transaction.type == 'بيع' &&
                            transaction.paidAmount > 0) ...[
                          Text(
                            'دفع: ${numberFormat.format(transaction.paidAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (transaction.productsSummary != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.productsSummary!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                if (transaction.notes != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          transaction.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المتبقي بعد العملية:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${numberFormat.format(transaction.remainingDebt)} جنيه',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: transaction.remainingDebt > 0
                            ? Colors.red
                            : Colors.green,
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

  void _printStatement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة طباعة كشف الحساب قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف ${widget.representative.name}؟\nسيتم حذف جميع المعاملات المرتبطة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<RepresentativeProvider>(context, listen: false);
              final success = await provider
                  .deleteRepresentative(widget.representative.id!);
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الحذف بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
