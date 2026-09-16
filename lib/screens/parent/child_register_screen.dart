import 'package:flutter/material.dart';
import '../../api_service.dart';

class ChildRegisterScreen extends StatefulWidget {
  final List<String> existingDevices;

  const ChildRegisterScreen({super.key, required this.existingDevices});

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final device_id = _deviceIdController.text.trim().toUpperCase();

    if (name.isEmpty || device_id.isEmpty) {
      setState(() {
        _errorMessage = '表示名とデバイスIDを入力してください';
      });
      return;
    }

    if (widget.existingDevices.contains(device_id)) {
      setState(() {
        _errorMessage = 'この子機は既に登録されています';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // サーバーAPIを呼び出してデバイス（deviceId）のみを登録
      final success = await ApiService.registerChild(device_id);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = '指定されたデバイスID（$device_id）が存在しないか、登録できません';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラーが発生しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          label: const Text('戻る', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        leadingWidth: 90,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '新しい子機を登録',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),

              const Text('こどもの表示名', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              const Text('子機のデバイスID', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'この内容で登録する',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}