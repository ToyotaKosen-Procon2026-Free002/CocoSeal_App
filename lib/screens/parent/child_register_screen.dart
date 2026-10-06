import 'package:flutter/material.dart';

import '../../api_service.dart';

class ChildRegisterScreen extends StatefulWidget {
  final List<String> existingDevices;

  const ChildRegisterScreen({
    super.key,
    required this.existingDevices,
  });


  @override
  State<ChildRegisterScreen> createState() =>
      _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();

    // UUIDは大文字へ変換せず、サーバーに登録された値のまま送信する。
    final deviceId = _deviceIdController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (name.isEmpty || deviceId.isEmpty) {
      setState(() {
        _errorMessage = '表示名とデバイスIDを入力してください';
      });
      return;
    }

    final alreadyRegistered = widget.existingDevices.any(
      (id) => id.trim() == deviceId,
    );

    if (alreadyRegistered) {
      setState(() {
        _errorMessage = 'この子機は既に登録されています';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.registerChildWithName(
        deviceId: deviceId,
        name: name,
      );

      if (!mounted) return;

      // 前の画面で子機一覧をAPIから再取得する。
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '通信中にエラーが発生しました: $error';
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
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7447C8),
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Colors.white,
          ),
          label: const Text(
            '戻る',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '新しい子機を登録',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'こどもの表示名',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: '例：たろう',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '子機のデバイスID',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _deviceIdController,
                enabled: !_isLoading,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _handleRegister();
                  }
                },
                decoration: InputDecoration(
                  hintText: '子機のデバイスIDを入力',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7447C8),
                    disabledBackgroundColor: const Color(0xFFB39DDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
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
