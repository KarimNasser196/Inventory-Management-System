// lib/main.dart (UPDATED)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/providers/maintenance_provider.dart';
import 'package:soundtry/providers/navigation_provider.dart';
import 'package:soundtry/screens/login_screen.dart';
import 'package:soundtry/services/password_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/product_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    throw UnsupportedError('This app is only supported on Windows desktop');
  }
  // تهيئة كلمة السر
  await PasswordService.initializePassword();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'نظام إدارة المخزون',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
          fontFamily: 'Arial',
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 14)),
        ),
        locale: const Locale('ar', 'SA'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SA')],
        home:
            const LoginScreen(), // تغيير الشاشة الرئيسية إلى شاشة تسجيل الدخول
      ),
    );
  }
}
