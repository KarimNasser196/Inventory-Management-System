// lib/widgets/password_dialog.dart

import 'package:flutter/material.dart';
import 'package:soundtry/services/password_service.dart';

class PasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  
  const PasswordDialog({
    super.key,
    this.title = 'تأكيد العملية',
    this.message = 'الرجاء إدخال كلمة المرور للمتابعة',
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال كلمة المرور';
        _isLoading = false;
      });
      return;
    }

    final isValid = await PasswordService.verifyOperationPassword(password);
    
    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true); // تم التحقق بنجاح
      }
    } else {
      setState(() {
        _errorMessage = 'كلمة المرور غير صحيحة';
        _isLoading = false;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('تأكيد'),
        ),
      ],
    );
  }
}

// دالة مساعدة لعرض Dialog
Future<bool> showPasswordDialog(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PasswordDialog(
      title: title ?? 'تأكيد العملية',
      message: message ?? 'الرجاء إدخال كلمة المرور للمتابعة',
    ),
  );
  return result ?? false;
}
