// lib/screens/representative_details_screen.dart - نسخة Responsive

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:soundtry/screens/add_payment_screen.dart';
import 'package:soundtry/utils/responsive.dart';
import 'package:intl/intl.dart';

class RepresentativeDetailsScreen extends StatefulWidget {
  final Representative representative;

  const RepresentativeDetailsScreen({super.key, required this.representative});

  @override
  State<RepresentativeDetailsScreen> createState() =>
      _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState
    extends State<RepresentativeDetailsScreen> {
  List<RepresentativeTransaction> _transactions = [];
  bool _isLoading = true;
  late Representative _currentRepresentative;

  @override
  void initState() {
    super.initState();
    _currentRepresentative = widget.representative;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Responsive.init(context);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final provider =
        Provider.of<RepresentativeProvider>(context, listen: false);

    await provider.loadRepresentatives();

    final updatedRep =
        provider.getRepresentativeById(widget.representative.id!);

    if (updatedRep != null) {
      _currentRepresentative = updatedRep;
    }

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
        title: Text(
          _currentRepresentative.name,
          style: TextStyle(fontSize: Responsive.font(18)),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: Responsive.icon(22)),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.edit, size: Responsive.icon(22)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRepresentativeScreen(
                    representative: _currentRepresentative,
                  ),
                ),
              );
              if (result == true && mounted) {
                await _loadData();
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, size: Responsive.icon(22)),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildCompactAccountSummary(),
                  _buildActionButtons(),
                  Divider(height: Responsive.height(1), thickness: 1),
                  Expanded(
                    child: _transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
                  ),
                ],
              ),
      ),
    );
  }

  // ملخص الحساب مضغوط
  Widget _buildCompactAccountSummary() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');
    final hasDebt = _currentRepresentative.hasDebt;

    return Container(
      margin: Responsive.paddingAll(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDebt
              ? [Colors.red.shade50, Colors.red.shade100]
              : [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: Responsive.paddingAll(16),
        child: Column(
          children: [
            // الصف الأول - الأيقونة والمعلومات الأساسية
            Row(
              children: [
                CircleAvatar(
                  radius: Responsive.radius(30),
                  backgroundColor: _currentRepresentative.type == 'مندوب'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    _currentRepresentative.type == 'مندوب'
                        ? Icons.person
                        : Icons.people,
                    size: Responsive.icon(32),
                    color: _currentRepresentative.type == 'مندوب'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                SizedBox(width: Responsive.width(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentRepresentative.name,
                        style: TextStyle(
                          fontSize: Responsive.font(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.height(2)),
                      Container(
                        padding: Responsive.paddingSym(h: 8, v: 2),
                        decoration: BoxDecoration(
                          color: _currentRepresentative.type == 'مندوب'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(Responsive.radius(4)),
                        ),
                        child: Text(
                          _currentRepresentative.type,
                          style: TextStyle(fontSize: Responsive.font(11)),
                        ),
                      ),
                      if (_currentRepresentative.phone != null) ...[
                        SizedBox(height: Responsive.height(4)),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: Responsive.icon(12),
                                color: Colors.grey.shade600),
                            SizedBox(width: Responsive.width(4)),
                            Text(
                              _currentRepresentative.phone!,
                              style: TextStyle(
                                fontSize: Responsive.font(11),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // المتبقي بشكل كبير
                Container(
                  padding: Responsive.paddingAll(12),
                  decoration: BoxDecoration(
                    color: hasDebt ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'المتبقي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.font(10),
                        ),
                      ),
                      Text(
                        numberFormat
                            .format(_currentRepresentative.remainingDebt),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.font(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hasDebt ? 'دين' : 'مسدد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.font(9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.height(12)),
            Divider(height: Responsive.height(1)),
            SizedBox(height: Responsive.height(12)),

            // الصف الثاني - الإحصائيات
            Row(
              children: [
                Expanded(
                  child: _buildCompactStat(
                    'إجمالي الديون',
                    numberFormat.format(_currentRepresentative.totalDebt),
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
                Container(
                  height: Responsive.height(40),
                  width: Responsive.width(1),
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildCompactStat(
                    'إجمالي المدفوع',
                    numberFormat.format(_currentRepresentative.totalPaid),
                    Icons.payment,
                    Colors.green,
                  ),
                ),
                Container(
                  height: Responsive.height(40),
                  width: Responsive.width(1),
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildCompactStat(
                    'المعاملات',
                    _transactions.length.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: Responsive.icon(20)),
        SizedBox(height: Responsive.height(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.font(14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.font(10),
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: Responsive.paddingSym(h: 12, v: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentRepresentative.hasDebt
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPaymentScreen(
                            representative: _currentRepresentative,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        await _loadData();
                      }
                    }
                  : null,
              icon: Icon(Icons.payment, size: Responsive.icon(18)),
              label: Text(
                'إضافة دفعة',
                style: TextStyle(fontSize: Responsive.font(13)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: Responsive.paddingSym(v: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.width(8)),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _printStatement,
              icon: Icon(Icons.print, size: Responsive.icon(18)),
              label: Text(
                'كشف حساب',
                style: TextStyle(fontSize: Responsive.font(13)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: Responsive.paddingSym(v: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
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
          Icon(Icons.receipt_long,
              size: Responsive.icon(80), color: Colors.grey.shade400),
          SizedBox(height: Responsive.height(16)),
          Text(
            'لا توجد معاملات',
            style: TextStyle(
              fontSize: Responsive.font(18),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: Responsive.height(8)),
          Text(
            'سيتم عرض جميع المعاملات هنا',
            style: TextStyle(
              fontSize: Responsive.font(14),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return ListView.builder(
      padding: Responsive.paddingSym(h: 12, v: 8),
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
          margin: Responsive.paddingOnly(bottom: 8),
          elevation: 2,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(10)),
          ),
          child: Padding(
            padding: Responsive.paddingAll(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: Responsive.radius(18),
                      backgroundColor: iconColor.withOpacity(0.2),
                      child: Icon(icon,
                          color: iconColor, size: Responsive.icon(18)),
                    ),
                    SizedBox(width: Responsive.width(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.getTypeInArabic(),
                            style: TextStyle(
                              fontSize: Responsive.font(14),
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                          Text(
                            transaction.getFormattedDateTime(),
                            style: TextStyle(
                              fontSize: Responsive.font(10),
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
                          numberFormat.format(transaction.amount),
                          style: TextStyle(
                            fontSize: Responsive.font(15),
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                        if (transaction.type == 'بيع' &&
                            transaction.paidAmount > 0) ...[
                          Text(
                            'دفع: ${numberFormat.format(transaction.paidAmount)}',
                            style: TextStyle(
                              fontSize: Responsive.font(10),
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (transaction.productsSummary != null) ...[
                  SizedBox(height: Responsive.height(8)),
                  Container(
                    padding: Responsive.paddingAll(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.radius(6)),
                    ),
                    child: Text(
                      transaction.productsSummary!,
                      style: TextStyle(fontSize: Responsive.font(12)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (transaction.notes != null) ...[
                  SizedBox(height: Responsive.height(6)),
                  Row(
                    children: [
                      Icon(Icons.note,
                          size: Responsive.icon(12),
                          color: Colors.grey.shade600),
                      SizedBox(width: Responsive.width(4)),
                      Expanded(
                        child: Text(
                          transaction.notes!,
                          style: TextStyle(
                            fontSize: Responsive.font(11),
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                Padding(
                  padding: Responsive.paddingOnly(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المتبقي:',
                        style: TextStyle(
                          fontSize: Responsive.font(11),
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: Responsive.paddingSym(h: 8, v: 2),
                        decoration: BoxDecoration(
                          color: transaction.remainingDebt > 0
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(Responsive.radius(4)),
                        ),
                        child: Text(
                          '${numberFormat.format(transaction.remainingDebt)} جنيه',
                          style: TextStyle(
                            fontSize: Responsive.font(12),
                            fontWeight: FontWeight.bold,
                            color: transaction.remainingDebt > 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
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
      SnackBar(
        content: Text(
          'سيتم إضافة ميزة طباعة كشف الحساب قريباً',
          style: TextStyle(fontSize: Responsive.font(14)),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(fontSize: Responsive.font(18)),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${_currentRepresentative.name}؟\nسيتم حذف جميع المعاملات المرتبطة.',
          style: TextStyle(fontSize: Responsive.font(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: Responsive.font(14)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<RepresentativeProvider>(context, listen: false);
              final success = await provider
                  .deleteRepresentative(_currentRepresentative.id!);
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم الحذف بنجاح',
                      style: TextStyle(fontSize: Responsive.font(14)),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: TextStyle(fontSize: Responsive.font(14)),
            ),
          ),
        ],
      ),
    );
  }
}
