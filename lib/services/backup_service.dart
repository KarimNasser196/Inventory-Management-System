import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class BackupService {
  /// إنشاء نسخة احتياطية
  Future<void> createBackup(String destinationPath) async {
    try {
      // الحصول على مسار قاعدة البيانات الحالية
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // تأكد من فتح قاعدة البيانات

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final currentDbPath = join(
        documentsDirectory.path,
        'inventory_management.db',
      );

      debugPrint('Current database path: $currentDbPath');
      debugPrint('Backup destination path: $destinationPath');

      // التحقق من وجود قاعدة البيانات
      final dbFile = File(currentDbPath);
      if (!await dbFile.exists()) {
        throw Exception('قاعدة البيانات غير موجودة');
      }

      // نسخ ملف قاعدة البيانات
      await dbFile.copy(destinationPath);

      debugPrint('Backup created successfully');
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// استعادة نسخة احتياطية
  Future<void> restoreBackup(String backupPath) async {
    try {
      debugPrint('Starting restore from: $backupPath');

      // التحقق من وجود ملف النسخة الاحتياطية
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('ملف النسخة الاحتياطية غير موجود');
      }

      // التحقق من صحة ملف قاعدة البيانات
      final fileSize = await backupFile.length();
      if (fileSize < 1024) {
        // أقل من 1 كيلوبايت
        throw Exception('ملف النسخة الاحتياطية تالف أو فارغ');
      }

      // إغلاق قاعدة البيانات الحالية
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.close();

      // الحصول على مسار قاعدة البيانات
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final currentDbPath = join(
        documentsDirectory.path,
        'inventory_management.db',
      );

      debugPrint('Target database path: $currentDbPath');

      // إنشاء نسخة احتياطية من قاعدة البيانات الحالية (للأمان)
      final currentDbFile = File(currentDbPath);
      if (await currentDbFile.exists()) {
        final backupBeforeRestorePath = join(
          documentsDirectory.path,
          'inventory_management_before_restore.db',
        );
        await currentDbFile.copy(backupBeforeRestorePath);
        debugPrint('Created safety backup at: $backupBeforeRestorePath');
      }

      // حذف قاعدة البيانات الحالية
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
        debugPrint('Deleted current database');
      }

      // نسخ ملف النسخة الاحتياطية إلى مكان قاعدة البيانات
      await backupFile.copy(currentDbPath);
      debugPrint('Copied backup to database location');

      // إعادة فتح قاعدة البيانات
      await dbHelper.database;
      debugPrint('Database reopened successfully');

      debugPrint('Restore completed successfully');
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  /// الحصول على معلومات عن نسخة احتياطية
  Future<Map<String, dynamic>> getBackupInfo(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw Exception('الملف غير موجود');
      }

      final fileStat = await backupFile.stat();
      final fileSize = fileStat.size;
      final modifiedDate = fileStat.modified;

      return {
        'size': fileSize,
        'sizeInMB': (fileSize / (1024 * 1024)).toStringAsFixed(2),
        'modifiedDate': modifiedDate,
        'path': backupPath,
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      rethrow;
    }
  }

  /// حذف النسخ الاحتياطية القديمة (اختياري)
  Future<void> deleteOldBackups(String backupDirectory, int daysToKeep) async {
    try {
      final directory = Directory(backupDirectory);

      if (!await directory.exists()) {
        return;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysToKeep));

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.db')) {
          final fileStat = await entity.stat();

          if (fileStat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            debugPrint('Deleted old backup: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting old backups: $e');
    }
  }

  /// التحقق من صحة ملف نسخة احتياطية
  Future<bool> validateBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        return false;
      }

      // التحقق من حجم الملف
      final fileSize = await backupFile.length();
      if (fileSize < 1024) {
        // أقل من 1 كيلوبايت
        return false;
      }

      // قراءة أول بضعة بايتات للتحقق من تنسيق SQLite
      final bytes = await backupFile.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes);

      if (!header.startsWith('SQLite format 3')) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating backup: $e');
      return false;
    }
  }
}
