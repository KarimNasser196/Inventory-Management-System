// lib/screens/system_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:soundtry/screens/login_screen.dart';
import 'package:soundtry/screens/maintenance_login_screen.dart';

class SystemSelectionScreen extends StatelessWidget {
  const SystemSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue[900]!,
              Colors.blue[600]!,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 16 : 24,
              horizontal: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.business_center,
                    size: isSmallScreen ? 60 : 90,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 35),

                Text(
                  'مرحباً بك',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 26 : 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 10),
                const Text(
                  'اختر النظام الذي تريد الدخول إليه',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 30 : 50),

                // أزرار الاختيار
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSystemCard(
                      context,
                      title: 'إدارة المخزون',
                      subtitle: 'البيع والشراء والمخزون',
                      icon: Icons.inventory_2,
                      color: Colors.green,
                      isMobile: false,
                      isTablet: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(
                              systemType: 'inventory',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 30),
                    _buildSystemCard(
                      context,
                      title: 'إدارة الصيانة',
                      subtitle: 'تسجيل ومتابعة الصيانة',
                      icon: Icons.build,
                      color: Colors.orange,
                      isMobile: false,
                      isTablet: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MaintenanceLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 25 : 50),

                // معلومات الشركة
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'RiadSoft Company',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 17 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildSystemCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    // أحجام متغيرة حسب ارتفاع الشاشة
    final cardWidth = isSmallScreen ? 260.0 : 300.0;
    final cardHeight = isSmallScreen ? 300.0 : 350.0;
    final iconSize = isSmallScreen ? 55.0 : 70.0;
    final iconPadding = isSmallScreen ? 20.0 : 25.0;
    final titleSize = isSmallScreen ? 19.0 : 22.0;
    final subtitleSize = isSmallScreen ? 13.0 : 15.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // الأيقونة
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: color,
                  ),
                ),

                // العنوان
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // النص الفرعي
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 15 : 20),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // زر الدخول
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 30 : 35,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'دخول',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}
