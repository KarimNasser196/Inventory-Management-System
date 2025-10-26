// lib/screens/maintenance_screen.dart (نسخة محدثة مع كود الصيانة)

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Column(
        children: [
          _buildStatisticsBar(context, isMobile),
          _buildToolbar(context, isMobile),
          Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: 'الكل'),
                Tab(icon: Icon(Icons.build), text: 'قيد الإصلاح'),
                Tab(icon: Icon(Icons.check_circle), text: 'جاهز للاستلام'),
                Tab(icon: Icon(Icons.done_all), text: 'تم التسليم'),
                Tab(icon: Icon(Icons.cancel), text: 'ملغي'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(null, isMobile),
                _buildRecordsList('قيد الإصلاح', isMobile),
                _buildRecordsList('جاهز للاستلام', isMobile),
                _buildRecordsList('تم التسليم', isMobile),
                _buildRecordsList('ملغي', isMobile),
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

  Widget _buildStatisticsBar(BuildContext context, bool isMobile) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'المجموع',
                            '${provider.totalRecords}',
                            Icons.list_alt,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatItem(
                            'قيد العمل',
                            '${provider.pendingRecords}',
                            Icons.pending,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'جاهز',
                            '${provider.readyForPickup}',
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatItem(
                            'الإيرادات',
                            '${provider.totalRevenue.toStringAsFixed(0)} ج',
                            Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                        'الإيرادات',
                        '${provider.totalRevenue.toStringAsFixed(2)} جنيه',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'المتبقي',
                        '${provider.totalRemaining.toStringAsFixed(2)} جنيه',
                        Icons.pending_actions,
                      ),
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

  Widget _buildToolbar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث (الاسم، نوع الجهاز، كود الصيانة...)',
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
        ],
      ),
    );
  }

  Widget _buildRecordsList(String? status, bool isMobile) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var records = status == null
            ? provider.maintenanceRecords
            : provider.getRecordsByStatus(status);

        if (_searchQuery.isNotEmpty) {
          records = provider.searchRecords(_searchQuery);
          if (status != null) {
            records = records.where((r) => r.status == status).toList();
          }
        }

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'لا توجد نتائج للبحث'
                      : 'لا توجد سجلات صيانة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return isMobile
            ? _buildMobileList(records)
            : _buildDesktopGrid(records);
      },
    );
  }

  Widget _buildMobileList(List<MaintenanceRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecordCard(record, true),
        );
      },
    );
  }

  Widget _buildDesktopGrid(List<MaintenanceRecord> records) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordCard(record, false);
      },
    );
  }

  Widget _buildRecordCard(MaintenanceRecord record, bool isMobile) {
    Color statusColor = _getStatusColor(record.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(record.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${record.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          record.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: record.repairCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم نسخ الكود: ${record.repairCode}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 20,
                              color: Colors.blue[900],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'كود: ${record.repairCode}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy, size: 16, color: Colors.blue[700]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.devices, record.deviceType),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.description,
                      record.problemDescription,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCostItem('التكلفة', record.cost, Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCostItem(
                      'المدفوع',
                      record.paidAmount,
                      Colors.green,
                    ),
                  ),
                  if (!record.isFullyPaid) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCostItem(
                        'المتبقي',
                        record.remainingAmount,
                        Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'استلام: ${DateFormat('yyyy-MM-dd').format(record.receivedDate)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (record.deliveryDate != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تسليم: ${DateFormat('yyyy-MM-dd HH:mm').format(record.deliveryDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecordDetails(record),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('عرض', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(record),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        'تحديث',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCostItem(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
          Text(
            '${amount.toStringAsFixed(0)}',
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
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'قيد الإصلاح':
        return Icons.build;
      case 'جاهز للاستلام':
        return Icons.check_circle;
      case 'تم التسليم':
        return Icons.done_all;
      case 'ملغي':
        return Icons.cancel;
      default:
        return Icons.help;
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
