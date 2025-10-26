// lib/services/password_service.dart

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

class PasswordService {
  static const String _passwordKey = 'app_password';
  static const String _defaultPassword = '123456'; // كلمة السر الافتراضية

  /// تشفير كلمة السر
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// تعيين كلمة السر لأول مرة
  static Future<void> initializePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPassword = prefs.containsKey(_passwordKey);

    if (!hasPassword) {
      final hashedPassword = _hashPassword(_defaultPassword);
      await prefs.setString(_passwordKey, hashedPassword);
    }
  }

  /// التحقق من كلمة السر
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey);

    if (storedHash == null) {
      await initializePassword();
      return password == _defaultPassword;
    }

    final inputHash = _hashPassword(password);
    return inputHash == storedHash;
  }

  /// تغيير كلمة السر
  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    // التحقق من كلمة السر القديمة
    final isValid = await verifyPassword(oldPassword);
    if (!isValid) {
      return false;
    }

    // حفظ كلمة السر الجديدة
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(newPassword);
    await prefs.setString(_passwordKey, hashedPassword);

    return true;
  }

  /// إعادة تعيين كلمة السر إلى الافتراضية
  static Future<void> resetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(_defaultPassword);
    await prefs.setString(_passwordKey, hashedPassword);
  }

  /// الحصول على كلمة السر الافتراضية (للعرض فقط في حالة النسيان)
  static String getDefaultPassword() {
    return _defaultPassword;
  }
}
