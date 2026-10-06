import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/gateway.dart';

class SealRegisterScreen extends StatefulWidget {
  final Gateway gateway;

  const SealRegisterScreen({super.key, required this.gateway});

  @override
  State<SealRegisterScreen> createState() => _SealRegisterScreenState();
}

class _SealRegisterScreenState extends State<SealRegisterScreen> {
  static const _purple = Color(0xFF7447C8);
  late final TextEditingController _gatewayNameController;
  final _sealNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String _imageMimeType = 'image/png';
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _gatewayNameController = TextEditingController(text: widget.gateway.name);
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final extension = file.extension?.toLowerCase();
      setState(() {
        _imageBytes = bytes;
        _imageMimeType = extension == 'jpg' || extension == 'jpeg'
            ? 'image/jpeg'
            : extension == 'webp'
                ? 'image/webp'
                : 'image/png';
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = '画像を読み込めませんでした: $error');
      }
    }
  }

  Future<void> _save() async {
    final gatewayName = _gatewayNameController.text.trim();
    final sealName = _sealNameController.text.trim();
    final description = _descriptionController.text.trim();
    if (gatewayName.isEmpty || sealName.isEmpty || description.isEmpty || _imageBytes == null) {
      setState(() => _errorMessage = 'すべての項目を入力し、画像を選んでください');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final seal = await ApiService.addOriginalSeal(
        name: sealName,
        description: description,
        // 親機が登録するオリジナルシールは、必ず O レアとして登録する。
        rarity: 2,
        imageBytes: _imageBytes!,
        imageMimeType: _imageMimeType,
        owner: widget.gateway.id,
      );
      await ApiService.updateGateway(
        gatewayId: widget.gateway.id,
        name: gatewayName,
        distributeSealId: seal.id,
        latitude: widget.gateway.latitude ?? 0,
        longitude: widget.gateway.longitude ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('シールを登録しました！')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = '登録に失敗しました: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _gatewayNameController.dispose();
    _sealNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8C5FF)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('シール登録', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('親機の表示名'),
                TextField(
                  controller: _gatewayNameController,
                  enabled: !_saving,
                  decoration: _decoration('例：豊田高専'),
                ),
                const SizedBox(height: 18),
                const _Label('シール名'),
                TextField(
                  controller: _sealNameController,
                  enabled: !_saving,
                  decoration: _decoration('シールの名前を入力'),
                ),
                const SizedBox(height: 18),
                const _Label('シールの説明'),
                TextField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: _decoration('シールの説明を入力'),
                ),
                const SizedBox(height: 18),
                const _Label('レア度'),
                InputDecorator(
                  decoration: _decoration(''),
                  child: const Row(
                    children: [
                      Text(
                        'O　★★★',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        '自動設定',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _Label('シール画像'),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('端末から画像を選ぶ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 190,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD8C5FF)),
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFB59BDD)),
                            SizedBox(height: 8),
                            Text('選んだ画像がここに表示されます', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('この内容で登録する', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF3E2465), fontWeight: FontWeight.bold),
        ),
      );
}
