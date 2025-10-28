// lib/services/password_service.dart

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PasswordService {
  static const String _passwordKey = 'app_password';
  static const String _maintenancePasswordKey = 'maintenance_password';
  static const String _defaultPassword = '123456'; // كلمة السر الافتراضية للمخزون
  static const String _defaultMaintenancePassword = '654321'; // كلمة السر الافتراضية للصيانة

  /// تشفير كلمة السر
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// تعيين كلمة السر لأول مرة
  static Future<void> initializePassword() async {
    final prefs = await SharedPreferences.getInstance();
    
    // كلمة سر المخزون
    final hasPassword = prefs.containsKey(_passwordKey);
    if (!hasPassword) {
      final hashedPassword = _hashPassword(_defaultPassword);
      await prefs.setString(_passwordKey, hashedPassword);
    }

    // كلمة سر الصيانة
    final hasMaintenancePassword = prefs.containsKey(_maintenancePasswordKey);
    if (!hasMaintenancePassword) {
      final hashedPassword = _hashPassword(_defaultMaintenancePassword);
      await prefs.setString(_maintenancePasswordKey, hashedPassword);
    }
  }

  /// التحقق من كلمة السر مع دعم أنواع مختلفة
  static Future<bool> verifyPassword(
    String password, [
    String type = 'warehouse',
  ]) async {
    final prefs = await SharedPreferences.getInstance();

    // تحديد المفتاح بناءً على النوع
    final key = type == 'maintenance' ? _maintenancePasswordKey : _passwordKey;
    final defaultPw =
        type == 'maintenance' ? _defaultMaintenancePassword : _defaultPassword;

    final storedHash = prefs.getString(key);

    if (storedHash == null) {
      await initializePassword();
      return password == defaultPw;
    }

    final inputHash = _hashPassword(password);
    return inputHash == storedHash;
  }

  /// التحقق من كلمة سر المخزون (للتوافق مع الكود القديم)
  static Future<bool> verifyWarehousePassword(String password) async {
    return verifyPassword(password, 'warehouse');
  }

  /// التحقق من كلمة سر الصيانة
  static Future<bool> verifyMaintenancePassword(String password) async {
    return verifyPassword(password, 'maintenance');
  }

  /// تغيير كلمة السر (المخزون)
  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    // التحقق من كلمة السر القديمة
    final isValid = await verifyPassword(oldPassword, 'warehouse');
    if (!isValid) {
      return false;
    }

    // حفظ كلمة السر الجديدة
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(newPassword);
    await prefs.setString(_passwordKey, hashedPassword);

    return true;
  }

  /// تغيير كلمة سر الصيانة
  static Future<bool> changeMaintenancePassword(
    String oldPassword,
    String newPassword,
  ) async {
    // التحقق من كلمة السر القديمة
    final isValid = await verifyPassword(oldPassword, 'maintenance');
    if (!isValid) {
      return false;
    }

    // حفظ كلمة السر الجديدة
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(newPassword);
    await prefs.setString(_maintenancePasswordKey, hashedPassword);

    return true;
  }

  /// التحقق من كلمة سر للتعديل أو الحذف (تستخدم كلمة سر المخزون)
  static Future<bool> verifyOperationPassword(String password) async {
    return await verifyPassword(password, 'warehouse');
  }

  /// إعادة تعيين كلمة السر إلى الافتراضية
  static Future<void> resetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(_defaultPassword);
    await prefs.setString(_passwordKey, hashedPassword);
  }

  /// إعادة تعيين كلمة سر الصيانة إلى الافتراضية
  static Future<void> resetMaintenancePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(_defaultMaintenancePassword);
    await prefs.setString(_maintenancePasswordKey, hashedPassword);
  }

  /// الحصول على كلمة السر الافتراضية (للعرض فقط في حالة النسيان)
  static String getDefaultPassword() {
    return _defaultPassword;
  }

  /// الحصول على كلمة سر الصيانة الافتراضية
  static String getDefaultMaintenancePassword() {
    return _defaultMaintenancePassword;
  }
}
