import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildRegisterScreen extends StatefulWidget {
  final List<String> existingDevices;

  const ChildRegisterScreen({super.key, required this.existingDevices});

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  String _selectedEmoji = '⚽';
  final List<String> _emojiOptions = ['⚽', '🍉', '🍎', '🐱', '🚗', '🍓', '🐙'];
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    // IDの表記揺れ防止のため大文字に統一 (例: esp-0001 -> ESP-0001)
    final deviceId = _deviceIdController.text.trim().toUpperCase();

    if (name.isEmpty || deviceId.isEmpty) {
      setState(() {
        _errorMessage = '表示名とデバイスIDを入力してください';
      });
      return;
    }

    if (widget.existingDevices.contains(deviceId)) {
      setState(() {
        _errorMessage = 'この子機は既に登録されています';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('children').doc(deviceId);
      final docSnapshot = await docRef.get();

      // 指定したIDのドキュメントがFirestoreに存在するかチェック
      if (!docSnapshot.exists) {
        setState(() {
          _errorMessage = '指定されたデバイスID（$deviceId）が存在しません';
          _isLoading = false;
        });
        return;
      }

      // 名前と絵文字を上書き保存（merge: true で coins など他のフィールドを保持）
      await docRef.set({
        'name': name,
        'emoji': _selectedEmoji,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = '登録に失敗しました: $e';
        _isLoading = false;
      });
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
                  hintText: 'いちろう',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              const Text('アイコンを選ぶ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedEmoji,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _emojiOptions.map((emoji) {
                  return DropdownMenuItem<String>(
                    value: emoji,
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEmoji = val);
                },
              ),

              const SizedBox(height: 20),

              const Text('子機のデバイスID', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  hintText: 'ESP-0001',
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