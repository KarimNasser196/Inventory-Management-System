import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Settings Card
                Card(
                  elevation: isMobile ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المظهر',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return SwitchListTile(
                              title: Text(
                                'الوضع الداكن',
                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                              ),
                              subtitle: Text(
                                'تغيير مظهر التطبيق بين الوضع الفاتح والداكن',
                                style: TextStyle(fontSize: isMobile ? 12 : 13),
                              ),
                              value: themeProvider.isDarkMode,
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                              secondary: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                              ),
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Backup Card
                Card(
                  elevation: isMobile ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'النسخ الاحتياطي',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildListTile(
                          leading: Icons.backup,
                          title: 'إنشاء نسخة احتياطية',
                          subtitle: 'حفظ جميع البيانات في ملف خارجي',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إنشاء نسخة احتياطية بنجاح'),
                              ),
                            );
                          },
                          isMobile: isMobile,
                        ),
                        Divider(height: isMobile ? 12 : 16),
                        _buildListTile(
                          leading: Icons.restore,
                          title: 'استعادة من نسخة احتياطية',
                          subtitle: 'استعادة البيانات من ملف خارجي',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم استعادة البيانات بنجاح'),
                              ),
                            );
                          },
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // About Card
                Card(
                  elevation: isMobile ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حول التطبيق',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildListTile(
                          leading: Icons.info_outline,
                          title: 'إدارة مخزون أجهزة اللابتوب',
                          subtitle: 'الإصدار 1.0.0',
                          isMobile: isMobile,
                          isClickable: false,
                        ),
                        Divider(height: isMobile ? 12 : 16),
                        _buildListTile(
                          leading: Icons.code,
                          title: 'المطور',
                          subtitle: 'كريم ناصر',
                          isMobile: isMobile,
                          isClickable: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData leading,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required bool isMobile,
    bool isClickable = true,
  }) {
    return ListTile(
      leading: Icon(leading),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: isMobile ? 12 : 13)),
      onTap: isClickable ? onTap : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
