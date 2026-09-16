import 'package:flutter/material.dart';

class PinCodeDialog extends StatefulWidget {
  final String correctPin;

  const PinCodeDialog({super.key, required this.correctPin});

  @override
  State<PinCodeDialog> createState() => _PinCodeDialogState();
}

class _PinCodeDialogState extends State<PinCodeDialog> {
  final _pinController = TextEditingController();
  String? _errorMessage;

  void _verifyPin() {
    if (_pinController.text == widget.correctPin) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'PINコードがちがいます';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '保護者用PINコードを入力',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '4桁の数字',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('もどる', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('かくにん', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}