import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/laptop.dart';
import '../models/sale.dart';
import '../models/return.dart';
import '../providers/laptop_provider.dart';
import '../utils/constants.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Consumer<LaptopProvider>(
          builder: (context, laptopProvider, child) {
            if (laptopProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(laptopProvider, isMobile, isTablet),
                const SizedBox(height: 20),

                // Charts
                _buildCharts(laptopProvider, isMobile, isTablet),
                const SizedBox(height: 20),

                // Recent transactions
                _buildRecentTransactions(laptopProvider, isMobile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    LaptopProvider laptopProvider,
    bool isMobile,
    bool isTablet,
  ) {
    final cards = [
      (
        title: 'الأجهزة المتاحة',
        count: laptopProvider.availableLaptopsCount,
        icon: Icons.laptop,
        color: Colors.green,
      ),
      (
        title: 'الأجهزة المباعة',
        count: laptopProvider.soldLaptopsCount,
        icon: Icons.shopping_cart,
        color: Colors.blue,
      ),
      (
        title: 'الأجهزة المرتجعة',
        count: laptopProvider.returnedLaptopsCount,
        icon: Icons.replay,
        color: Colors.orange,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSummaryCard(
                  title: card.title,
                  count: card.count,
                  icon: card.icon,
                  color: card.color,
                  isMobile: true,
                ),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _buildSummaryCard(
              title: cards[i].title,
              count: cards[i].count,
              icon: cards[i].icon,
              color: cards[i].color,
              isMobile: false,
            ),
          ),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(
    LaptopProvider laptopProvider,
    bool isMobile,
    bool isTablet,
  ) {
    final availableCount = laptopProvider.availableLaptopsCount;
    final soldCount = laptopProvider.soldLaptopsCount;
    final returnedCount = laptopProvider.returnedLaptopsCount;
    final total = availableCount + soldCount + returnedCount;

    if (total == 0) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Text(
              'لا توجد بيانات',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الأجهزة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isMobile)
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: availableCount.toDouble(),
                            title:
                                '${((availableCount / total) * 100).toStringAsFixed(1)}%',
                            color: Colors.green,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: soldCount.toDouble(),
                            title:
                                '${((soldCount / total) * 100).toStringAsFixed(1)}%',
                            color: Colors.blue,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: returnedCount.toDouble(),
                            title:
                                '${((returnedCount / total) * 100).toStringAsFixed(1)}%',
                            color: Colors.orange,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('متاح', Colors.green),
                      _buildLegendItem('مباع', Colors.blue),
                      _buildLegendItem('مرتجع', Colors.orange),
                    ],
                  ),
                ],
              )
            else
              SizedBox(
                height: 280,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: availableCount.toDouble(),
                              title:
                                  '${((availableCount / total) * 100).toStringAsFixed(1)}%',
                              color: Colors.green,
                              radius: 80,
                            ),
                            PieChartSectionData(
                              value: soldCount.toDouble(),
                              title:
                                  '${((soldCount / total) * 100).toStringAsFixed(1)}%',
                              color: Colors.blue,
                              radius: 80,
                            ),
                            PieChartSectionData(
                              value: returnedCount.toDouble(),
                              title:
                                  '${((returnedCount / total) * 100).toStringAsFixed(1)}%',
                              color: Colors.orange,
                              radius: 80,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('متاح', Colors.green),
                          const SizedBox(height: 12),
                          _buildLegendItem('مباع', Colors.blue),
                          const SizedBox(height: 12),
                          _buildLegendItem('مرتجع', Colors.orange),
                        ],
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentTransactions(
    LaptopProvider laptopProvider,
    bool isMobile,
  ) {
    final recentSales = laptopProvider.getRecentSales();
    final recentReturns = laptopProvider.getRecentReturns();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر العمليات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Recent sales
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخر عمليات البيع',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentSales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'لا توجد عمليات بيع حديثة',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentSales.length,
                    itemBuilder: (context, index) {
                      final sale = recentSales[index];
                      final laptop = laptopProvider.laptops.firstWhere(
                        (l) => l.id == sale.laptopId,
                        orElse: () => Laptop(
                          name: 'غير معروف',
                          serialNumber: '',
                          model: '',
                          price: 0,
                          status: '',
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_cart,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    laptop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'المشتري: ${sale.customerName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${sale.price} جنيه',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(sale.date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recent returns
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخر عمليات الاسترجاع',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentReturns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'لا توجد عمليات استرجاع حديثة',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentReturns.length,
                    itemBuilder: (context, index) {
                      final returnData = recentReturns[index];
                      final laptop = laptopProvider.laptops.firstWhere(
                        (l) => l.id == returnData.laptopId,
                        orElse: () => Laptop(
                          name: 'غير معروف',
                          serialNumber: '',
                          model: '',
                          price: 0,
                          status: '',
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.replay,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    laptop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'السبب: ${returnData.reason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd').format(returnData.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
