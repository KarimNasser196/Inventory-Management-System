// lib/screens/representatives_screen.dart - نسخة Responsive

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/representative_details_screen.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:soundtry/utils/responsive.dart';
import 'package:intl/intl.dart';

class RepresentativesScreen extends StatefulWidget {
  const RepresentativesScreen({super.key});

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    Responsive.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المندوبين والعملاء',
          style: TextStyle(fontSize: Responsive.font(18)),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: Responsive.icon(24)),
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
              _buildCompactStatistics(provider),
              _buildFiltersRow(provider),
              _buildSearchBar(),
              Expanded(
                child: _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildRepresentativesGrid(),
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
          if (result == true && mounted) {
            Provider.of<RepresentativeProvider>(context, listen: false)
                .loadRepresentatives();
          }
        },
        icon: Icon(Icons.add, size: Responsive.icon(20)),
        label:
            Text('إضافة جديد', style: TextStyle(fontSize: Responsive.font(14))),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // تصميم مضغوط للإحصائيات
  Widget _buildCompactStatistics(RepresentativeProvider provider) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Container(
      margin: Responsive.paddingAll(12),
      padding: Responsive.paddingSym(h: 16, v: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
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
      child: Row(
        children: [
          // الأعداد
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactStatItem(
                  'مندوبين',
                  provider.totalMandoubs.toString(),
                  Icons.person,
                  Colors.blue,
                ),
                Container(
                  height: Responsive.height(30),
                  width: Responsive.width(1),
                  color: Colors.grey.shade300,
                ),
                _buildCompactStatItem(
                  'عملاء',
                  provider.totalCustomers.toString(),
                  Icons.people,
                  Colors.green,
                ),
                Container(
                  height: Responsive.height(30),
                  width: Responsive.width(1),
                  color: Colors.grey.shade300,
                ),
                _buildCompactStatItem(
                  'الكل',
                  provider.totalRepresentatives.toString(),
                  Icons.groups,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // خط فاصل
          Container(
            height: Responsive.height(40),
            width: Responsive.width(2),
            margin: Responsive.paddingSym(h: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade400,
                  Colors.transparent
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // المبالغ المالية
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    numberFormat.format(provider.totalDebts),
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: Responsive.width(4)),
                  Text(
                    'ديون',
                    style: TextStyle(
                      fontSize: Responsive.font(11),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.height(4)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    numberFormat.format(provider.totalPaid),
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: Responsive.width(4)),
                  Text(
                    'مدفوع',
                    style: TextStyle(
                      fontSize: Responsive.font(11),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: Responsive.icon(20)),
        SizedBox(height: Responsive.height(2)),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.font(16),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.font(10),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(RepresentativeProvider provider) {
    return Padding(
      padding: Responsive.paddingSym(h: 12, v: 6),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'الكل',
                  label: Text('الكل',
                      style: TextStyle(fontSize: Responsive.font(12))),
                ),
                ButtonSegment(
                  value: 'مندوب',
                  label: Text('مندوبين',
                      style: TextStyle(fontSize: Responsive.font(12))),
                ),
                ButtonSegment(
                  value: 'عميل',
                  label: Text('عملاء',
                      style: TextStyle(fontSize: Responsive.font(12))),
                ),
              ],
              selected: {provider.filterType},
              onSelectionChanged: (Set<String> selection) {
                provider.setFilterType(selection.first);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  Responsive.paddingSym(h: 8, v: 6),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.width(8)),
          FilterChip(
            label: Text('المديونين',
                style: TextStyle(fontSize: Responsive.font(11))),
            selected: provider.showOnlyWithDebt,
            onSelected: (_) => provider.toggleShowOnlyWithDebt(),
            selectedColor: Colors.red.shade100,
            padding: Responsive.paddingSym(h: 8, v: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: Responsive.paddingSym(h: 12, v: 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو رقم الهاتف...',
          hintStyle: TextStyle(fontSize: Responsive.font(13)),
          prefixIcon: Icon(Icons.search, size: Responsive.icon(20)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: Responsive.icon(20)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
          contentPadding: Responsive.paddingSym(h: 12, v: 8),
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
          Icon(Icons.person_off,
              size: Responsive.icon(80), color: Colors.grey.shade400),
          SizedBox(height: Responsive.height(16)),
          Text(
            'لا يوجد مندوبين أو عملاء',
            style: TextStyle(
              fontSize: Responsive.font(18),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: Responsive.height(8)),
          Text(
            'اضغط على زر "إضافة جديد" للبدء',
            style: TextStyle(
              fontSize: Responsive.font(14),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // عرض الشبكة (Grid) بدل القائمة - متجاوب حسب حجم الشاشة
  Widget _buildRepresentativesGrid() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    // ⭐ حساب عدد الأعمدة بناءً على عرض الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth >= 1600) {
      crossAxisCount = 5; // شاشات كبيرة جداً
      childAspectRatio = 1.8;
    } else if (screenWidth >= 1200) {
      crossAxisCount = 4; // شاشات كبيرة
      childAspectRatio = 1.7;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3; // شاشات متوسطة
      childAspectRatio = 1.6;
    } else {
      crossAxisCount = 2; // شاشات صغيرة
      childAspectRatio = 1.5;
    }

    return GridView.builder(
      padding: Responsive.paddingAll(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: Responsive.width(12),
        mainAxisSpacing: Responsive.height(12),
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final rep = _filteredList[index];
        final hasDebt = rep.hasDebt;

        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RepresentativeDetailsScreen(representative: rep),
              ),
            );

            if (mounted) {
              final provider =
                  Provider.of<RepresentativeProvider>(context, listen: false);
              await provider.loadRepresentatives();
            }
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              side: hasDebt
                  ? BorderSide(color: Colors.red, width: Responsive.width(2))
                  : BorderSide.none,
            ),
            child: Container(
              padding: Responsive.paddingAll(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                gradient: LinearGradient(
                  colors: rep.type == 'مندوب'
                      ? [Colors.blue.shade50, Colors.white]
                      : [Colors.green.shade50, Colors.white],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الصف الأول - الأيقونة والاسم
                  Row(
                    children: [
                      CircleAvatar(
                        radius: Responsive.radius(18),
                        backgroundColor: rep.type == 'مندوب'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        child: Icon(
                          rep.type == 'مندوب' ? Icons.person : Icons.people,
                          color:
                              rep.type == 'مندوب' ? Colors.blue : Colors.green,
                          size: Responsive.icon(18),
                        ),
                      ),
                      SizedBox(width: Responsive.width(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rep.name,
                              style: TextStyle(
                                fontSize: Responsive.font(14),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              rep.type,
                              style: TextStyle(
                                fontSize: Responsive.font(10),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.height(8)),

                  // رقم الهاتف
                  if (rep.phone != null && rep.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone,
                            size: Responsive.icon(12),
                            color: Colors.grey.shade600),
                        SizedBox(width: Responsive.width(4)),
                        Expanded(
                          child: Text(
                            rep.phone!,
                            style: TextStyle(fontSize: Responsive.font(11)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // المبالغ المالية
                  Container(
                    padding: Responsive.paddingSym(h: 8, v: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.radius(8)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // المتبقي
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'متبقي',
                                style: TextStyle(
                                  fontSize: Responsive.font(9),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                numberFormat.format(rep.remainingDebt),
                                style: TextStyle(
                                  fontSize: Responsive.font(13),
                                  fontWeight: FontWeight.bold,
                                  color: hasDebt ? Colors.red : Colors.green,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // خط فاصل
                        Container(
                          height: Responsive.height(20),
                          width: Responsive.width(1),
                          color: Colors.grey.shade300,
                          margin: Responsive.paddingSym(h: 6),
                        ),

                        // المدفوع
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مدفوع',
                                style: TextStyle(
                                  fontSize: Responsive.font(9),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                numberFormat.format(rep.totalPaid),
                                style: TextStyle(
                                  fontSize: Responsive.font(11),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
