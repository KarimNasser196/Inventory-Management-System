// lib/screens/maintenance_screen.dart (محدث مع إحصائيات مالية وفلترة)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/maintenance_provider.dart';
import '../models/maintenance_record.dart';
import 'add_maintenance_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _dateFilter = 'الكل';
  String _financialFilter = 'الكل'; // فلتر مالي جديد

  final List<String> _dateFilterOptions = [
    'الكل',
    'اليوم',
    'الأمس',
    'هذا الأسبوع',
    'هذا الشهر',
    'تاريخ محدد',
  ];

  final List<String> _financialFilterOptions = [
    'الكل',
    'اليوم',
    'هذا الأسبوع',
    'هذا الشهر',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildStatisticsBar(context),
          _buildDailyStatistics(context),
          _buildToolbar(context),
          Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: 'الكل'),
                Tab(icon: Icon(Icons.build), text: 'قيد الإصلاح'),
                Tab(icon: Icon(Icons.check_circle), text: 'جاهز للاستلام'),
                Tab(icon: Icon(Icons.done_all), text: 'تم التسليم'),
                Tab(icon: Icon(Icons.cancel), text: 'ملغي'),
                Tab(icon: Icon(Icons.block), text: 'مرفوض'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(null),
                _buildRecordsList('قيد الإصلاح'),
                _buildRecordsList('جاهز للاستلام'),
                _buildRecordsList('تم التسليم'),
                _buildRecordsList('ملغي'),
                _buildRecordsList('مرفوض'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMaintenance(context),
        icon: const Icon(Icons.add),
        label: const Text('سجل صيانة جديد'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatisticsBar(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        // حساب الإيرادات والمتبقي حسب الفلتر المالي
        Map<String, double> financialStats =
            provider.getFinancialStatistics(_financialFilter);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // الصف الأول: الإحصائيات العامة
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'إجمالي السجلات',
                      '${provider.totalRecords}',
                      Icons.list_alt,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'قيد العمل',
                      '${provider.pendingRecords}',
                      Icons.pending,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'جاهز للاستلام',
                      '${provider.readyForPickup}',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'مكتمل',
                      '${provider.completedRecords}',
                      Icons.done_all,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'مرفوض',
                      '${provider.rejectedRecords}',
                      Icons.block,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialStatItem(
                      'الإيرادات',
                      financialStats['revenue']!,
                      Icons.attach_money,
                      Colors.green[300]!,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialStatItem(
                      'المتبقي',
                      financialStats['remaining']!,
                      Icons.pending_actions,
                      Colors.orange[300]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // الصف الثاني: فلتر الإيرادات
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'فترة الإيرادات:',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _financialFilter,
                          dropdownColor: Colors.blue[700],
                          underline: Container(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          items: _financialFilterOptions.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _financialFilter = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStatItem(
    String label,
    double value,
    IconData icon,
    Color highlightColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlightColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: highlightColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${value.toStringAsFixed(2)} ج',
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatistics(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        final todayStats = provider.getTodayStatistics();
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green[50],
          child: Row(
            children: [
              Icon(Icons.today, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'إحصائيات اليوم: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(width: 16),
              _buildMiniStat('مستلم', todayStats['received']!, Colors.blue),
              const SizedBox(width: 12),
              _buildMiniStat(
                  'قيد الإصلاح', todayStats['inProgress']!, Colors.orange),
              const SizedBox(width: 12),
              _buildMiniStat('جاهز', todayStats['ready']!, Colors.green),
              const SizedBox(width: 12),
              _buildMiniStat('مُسَلّم', todayStats['delivered']!, Colors.grey),
              const SizedBox(width: 12),
              _buildMiniStat('مرفوض', todayStats['rejected']!, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث (الاسم، رقم الهاتف، نوع الجهاز، كود الصيانة...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // فلتر التاريخ
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _dateFilter,
              decoration: InputDecoration(
                labelText: 'تصفية بالتاريخ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              items: _dateFilterOptions.map((filter) {
                return DropdownMenuItem(value: filter, child: Text(filter));
              }).toList(),
              onChanged: (value) async {
                if (value == 'تاريخ محدد') {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dateFilter = value!;
                      _selectedDate = date;
                    });
                  }
                } else {
                  setState(() {
                    _dateFilter = value!;
                    _selectedDate = null;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // زر الطباعة
          ElevatedButton.icon(
            onPressed: () => _printRepairReport(context),
            icon: const Icon(Icons.print),
            label: const Text('طباعة تقرير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(String? status) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var records = status == null
            ? provider.maintenanceRecords
            : provider.getRecordsByStatus(status);

        // تطبيق فلتر البحث
        if (_searchQuery.isNotEmpty) {
          records = provider.searchRecords(_searchQuery);
          if (status != null) {
            records = records.where((r) => r.status == status).toList();
          }
        }

        // تطبيق فلتر التاريخ
        records = _applyDateFilter(records);

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _dateFilter != 'الكل'
                      ? 'لا توجد نتائج'
                      : 'لا توجد سجلات صيانة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(7),
          child: Card(
            elevation: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 70,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                  columns: const [
                    DataColumn(label: Text('رقم الطلب')),
                    DataColumn(label: Text('كود الصيانة')),
                    DataColumn(label: Text('العميل')),
                    DataColumn(label: Text('رقم الهاتف')),
                    DataColumn(label: Text('الجهاز')),
                    DataColumn(label: Text('العطل')),
                    DataColumn(label: Text('تاريخ الاستلام')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: records.map((record) {
                    Color statusColor = _getStatusColor(record.status);
                    return DataRow(
                      cells: [
                        DataCell(Text('#${record.id}')),
                        DataCell(
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: record.repairCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم نسخ الكود: ${record.repairCode}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 16,
                                    color: Colors.blue[900],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.repairCode,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy,
                                      size: 12, color: Colors.blue[700]),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              record.customerName,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: record.customerPhone),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم نسخ الرقم: ${record.customerPhone}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone,
                                      size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.customerPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              record.deviceType,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              record.problemDescription,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(record.receivedDate),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'عرض التفاصيل',
                                child: InkWell(
                                  onTap: () => _showRecordDetails(record),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Icon(
                                      Icons.visibility,
                                      size: 18,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'تحديث الحالة',
                                child: InkWell(
                                  onTap: () => _showStatusUpdateDialog(record),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange[200]!),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<MaintenanceRecord> _applyDateFilter(List<MaintenanceRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilter) {
      case 'اليوم':
        return records.where((r) {
          final date = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return date == today;
        }).toList();

      case 'الأمس':
        final yesterday = today.subtract(const Duration(days: 1));
        return records.where((r) {
          final date = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return date == yesterday;
        }).toList();

      case 'هذا الأسبوع':
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return records.where((r) => r.receivedDate.isAfter(weekStart)).toList();

      case 'هذا الشهر':
        final monthStart = DateTime(now.year, now.month, 1);
        return records
            .where((r) => r.receivedDate.isAfter(monthStart))
            .toList();

      case 'تاريخ محدد':
        if (_selectedDate != null) {
          final targetDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
          return records.where((r) {
            final date = DateTime(
              r.receivedDate.year,
              r.receivedDate.month,
              r.receivedDate.day,
            );
            return date == targetDate;
          }).toList();
        }
        return records;

      default:
        return records;
    }
  }

  void _printRepairReport(BuildContext context) {
    final provider = Provider.of<MaintenanceProvider>(context, listen: false);
    final inRepairRecords = provider.getRecordsByStatus('قيد الإصلاح');

    if (inRepairRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أجهزة تحت الصيانة حالياً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // إنشاء التقرير
    final report = StringBuffer();
    report.writeln('═══════════════════════════════════════════');
    report.writeln('           تقرير الأجهزة تحت الصيانة');
    report.writeln('═══════════════════════════════════════════');
    report.writeln(
        'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    report.writeln('عدد الأجهزة: ${inRepairRecords.length}');
    report.writeln('═══════════════════════════════════════════\n');

    int index = 1;
    for (var record in inRepairRecords) {
      report.writeln('[$index] ────────────────────────────────');
      report.writeln('  الكود: ${record.repairCode}');
      report.writeln('  العميل: ${record.customerName}');
      report.writeln('  الهاتف: ${record.customerPhone}');
      report.writeln('  الجهاز: ${record.deviceType}');
      report.writeln('  العطل: ${record.problemDescription}');
      report.writeln(
          '  تاريخ الاستلام: ${DateFormat('yyyy-MM-dd').format(record.receivedDate)}');
      report.writeln('');
      index++;
    }

    report.writeln('═══════════════════════════════════════════');
    report.writeln('            نهاية التقرير');
    report.writeln('═══════════════════════════════════════════');

    // عرض التقرير
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقرير الصيانة'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              report.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ التقرير للحافظة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('نسخ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الإصلاح':
        return Colors.orange;
      case 'جاهز للاستلام':
        return Colors.green;
      case 'تم التسليم':
        return Colors.grey;
      case 'ملغي':
        return Colors.red;
      case 'مرفوض':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  void _navigateToAddMaintenance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMaintenanceScreen()),
    );
  }

  void _showRecordDetails(MaintenanceRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaintenanceScreen(record: record),
      ),
    );
  }

  void _showStatusUpdateDialog(MaintenanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث الحالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('قيد الإصلاح'),
              leading: Radio<String>(
                value: 'قيد الإصلاح',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('جاهز للاستلام'),
              leading: Radio<String>(
                value: 'جاهز للاستلام',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('تم التسليم'),
              leading: Radio<String>(
                value: 'تم التسليم',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('ملغي'),
              leading: Radio<String>(
                value: 'ملغي',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('مرفوض'),
              leading: Radio<String>(
                value: 'مرفوض',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      final provider = Provider.of<MaintenanceProvider>(context, listen: false);
      await provider.updateStatus(id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الحالة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
