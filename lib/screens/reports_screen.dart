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
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<LaptopProvider>(
          builder: (context, laptopProvider, child) {
            if (laptopProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(laptopProvider),
                const SizedBox(height: 24),

                // Charts
                _buildCharts(laptopProvider),
                const SizedBox(height: 24),

                // Recent transactions
                _buildRecentTransactions(laptopProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(LaptopProvider laptopProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'الأجهزة المتاحة',
            count: laptopProvider.availableLaptopsCount,
            icon: Icons.laptop,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'الأجهزة المباعة',
            count: laptopProvider.soldLaptopsCount,
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'الأجهزة المرتجعة',
            count: laptopProvider.returnedLaptopsCount,
            icon: Icons.replay,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(LaptopProvider laptopProvider) {
    final availableCount = laptopProvider.availableLaptopsCount;
    final soldCount = laptopProvider.soldLaptopsCount;
    final returnedCount = laptopProvider.returnedLaptopsCount;
    final total = availableCount + soldCount + returnedCount;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الأجهزة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  // Pie chart
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
                            radius: 100,
                          ),
                          PieChartSectionData(
                            value: soldCount.toDouble(),
                            title:
                                '${((soldCount / total) * 100).toStringAsFixed(1)}%',
                            color: Colors.blue,
                            radius: 100,
                          ),
                          PieChartSectionData(
                            value: returnedCount.toDouble(),
                            title:
                                '${((returnedCount / total) * 100).toStringAsFixed(1)}%',
                            color: Colors.orange,
                            radius: 100,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),

                  // Legend
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('متاح', Colors.green),
                        const SizedBox(height: 16),
                        _buildLegendItem('مباع', Colors.blue),
                        const SizedBox(height: 16),
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
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildRecentTransactions(LaptopProvider laptopProvider) {
    final recentSales = laptopProvider.getRecentSales();
    final recentReturns = laptopProvider.getRecentReturns();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر العمليات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Recent sales
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخر عمليات البيع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (recentSales.isEmpty)
                  const Text('لا توجد عمليات بيع حديثة')
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

                      return ListTile(
                        leading: const Icon(
                          Icons.shopping_cart,
                          color: Colors.blue,
                        ),
                        title: Text(laptop.name),
                        subtitle: Text('المشتري: ${sale.customerName}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${sale.price} جنيه',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(sale.date),
                              style: const TextStyle(fontSize: 12),
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
        const SizedBox(height: 16),

        // Recent returns
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخر عمليات الاسترجاع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (recentReturns.isEmpty)
                  const Text('لا توجد عمليات استرجاع حديثة')
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

                      return ListTile(
                        leading: const Icon(Icons.replay, color: Colors.orange),
                        title: Text(laptop.name),
                        subtitle: Text('السبب: ${returnData.reason}'),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd').format(returnData.date),
                          style: const TextStyle(fontSize: 12),
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
