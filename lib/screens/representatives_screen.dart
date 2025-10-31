// lib/screens/representatives_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/representative_details_screen.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:intl/intl.dart';

class RepresentativesScreen extends StatefulWidget {
  const RepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<RepresentativesScreen> createState() => _RepresentativesScreenState();
}

class _RepresentativesScreenState extends State<RepresentativesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Representative> _filteredList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepresentativeProvider>(context, listen: false)
          .loadRepresentatives();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المندوبين والعملاء'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<RepresentativeProvider>(context, listen: false)
                  .loadRepresentatives();
            },
          ),
        ],
      ),
      body: Consumer<RepresentativeProvider>(
        builder: (context, provider, child) {
          _filteredList = _searchController.text.isEmpty
              ? provider.representatives
              : provider.searchRepresentatives(_searchController.text);

          return Column(
            children: [
              _buildStatisticsCard(provider),
              _buildFiltersRow(provider),
              _buildSearchBar(),
              Expanded(
                child: _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildRepresentativesList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRepresentativeScreen(),
            ),
          );
          if (result == true) {
            Provider.of<RepresentativeProvider>(context, listen: false)
                .loadRepresentatives();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة جديد'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatisticsCard(RepresentativeProvider provider) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'المندوبين',
                  provider.totalMandoubs.toString(),
                  Icons.person,
                  Colors.blue,
                ),
                _buildStatItem(
                  'العملاء',
                  provider.totalCustomers.toString(),
                  Icons.people,
                  Colors.green,
                ),
                _buildStatItem(
                  'الإجمالي',
                  provider.totalRepresentatives.toString(),
                  Icons.groups,
                  Colors.orange,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMoneyStatItem(
                  'إجمالي الديون',
                  numberFormat.format(provider.totalDebts),
                  Colors.red,
                ),
                _buildMoneyStatItem(
                  'إجمالي المدفوع',
                  numberFormat.format(provider.totalPaid),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMoneyStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '$value جنيه',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(RepresentativeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'الكل', label: Text('الكل')),
                ButtonSegment(value: 'مندوب', label: Text('مندوبين')),
                ButtonSegment(value: 'عميل', label: Text('عملاء')),
              ],
              selected: {provider.filterType},
              onSelectionChanged: (Set<String> selection) {
                provider.setFilterType(selection.first);
              },
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('المديونين فقط'),
            selected: provider.showOnlyWithDebt,
            onSelected: (_) => provider.toggleShowOnlyWithDebt(),
            selectedColor: Colors.red.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو رقم الهاتف...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مندوبين أو عملاء',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على زر "إضافة جديد" للبدء',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativesList() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final rep = _filteredList[index];
        final hasDebt = rep.hasDebt;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasDebt
                ? const BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: rep.type == 'مندوب'
                  ? Colors.blue.shade100
                  : Colors.green.shade100,
              child: Icon(
                rep.type == 'مندوب' ? Icons.person : Icons.people,
                color: rep.type == 'مندوب' ? Colors.blue : Colors.green,
                size: 32,
              ),
            ),
            title: Text(
              rep.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(rep.type),
                if (rep.phone != null)
                  Text('📞 ${rep.phone}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المتبقي',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${numberFormat.format(rep.remainingDebt)} جنيه',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasDebt ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المدفوع',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${numberFormat.format(rep.totalPaid)} جنيه',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RepresentativeDetailsScreen(representative: rep),
                ),
              );

              // ⭐ تحديث البيانات دايماً بعد الرجوع
              if (mounted) {
                final provider =
                    Provider.of<RepresentativeProvider>(context, listen: false);
                await provider.loadRepresentatives();
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
