import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../app_config.dart';
import '../../demo_data.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';

class SealBookScreen extends StatefulWidget {
  final String deviceId;

  const SealBookScreen({super.key, required this.deviceId});

  @override
  State<SealBookScreen> createState() => _SealBookScreenState();
}

class PlacedSticker {
  final String id;
  final Seal seal;
  Offset position;
  double size;
  double rotation;

  PlacedSticker({
    required this.id,
    required this.seal,
    required this.position,
    this.size = 110,
    this.rotation = 0,
  });
}

class _SealBookScreenState extends State<SealBookScreen> {
  late Future<List<Seal>> _myStickersFuture;
  final List<PlacedSticker> _placedStickers = [];
  String? _selectedStickerId;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _myStickersFuture = _loadOwnedSeals();
    _restoreSavedBook();
  }

  Future<void> _restoreSavedBook() async {
    if (!AppConfig.useDemoData) return;
    final seals = await _myStickersFuture;
    final byId = {for (final seal in seals) seal.id: seal};
    final saved = DemoData.loadSealBook(widget.deviceId);
    if (!mounted || saved.isEmpty) return;
    setState(() {
      _placedStickers
        ..clear()
        ..addAll(saved.map((item) {
          final seal = byId[item['seal_id']?.toString()];
          if (seal == null) return null;
          return PlacedSticker(
            id: item['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
            seal: seal,
            position: Offset(
              (item['x'] as num?)?.toDouble() ?? 0,
              (item['y'] as num?)?.toDouble() ?? 0,
            ),
            size: (item['size'] as num?)?.toDouble() ?? 110,
            rotation: (item['rotation'] as num?)?.toDouble() ?? 0,
          );
        }).whereType<PlacedSticker>());
    });
  }

  void _saveBook() {
    if (AppConfig.useDemoData) {
      DemoData.saveSealBook(
        widget.deviceId,
        _placedStickers.map((sticker) => <String, dynamic>{
          'id': sticker.id,
          'seal_id': sticker.seal.id,
          'x': sticker.position.dx,
          'y': sticker.position.dy,
          'size': sticker.size,
          'rotation': sticker.rotation,
        }).toList(),
      );
    }
    setState(() => _selectedStickerId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('シール帳を保存しました！')),
    );
  }

  Future<List<Seal>> _loadOwnedSeals() async {
    final collection = await ApiService.fetchSealCollection(widget.deviceId);
    final ownedIds = collection.owned.map((item) => item.sealId).toSet();
    return collection.catalog.where((seal) => ownedIds.contains(seal.id)).toList();
  }

  void _addStickerToPage(Seal seal) {
    const initialSize = 110.0;
    final start = _canvasSize == Size.zero
        ? const Offset(100, 100)
        : Offset(
            (_canvasSize.width - initialSize) / 2,
            (_canvasSize.height - initialSize) / 2,
          );
    final sticker = PlacedSticker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      seal: seal,
      position: start,
      size: initialSize,
    );
    setState(() {
      _placedStickers.add(sticker);
      _selectedStickerId = sticker.id;
    });
  }

  void _moveSticker(PlacedSticker sticker, Offset delta) {
    final maxX = math.max(0.0, _canvasSize.width - sticker.size);
    final maxY = math.max(0.0, _canvasSize.height - sticker.size);
    setState(() {
      sticker.position = Offset(
        (sticker.position.dx + delta.dx).clamp(0.0, maxX),
        (sticker.position.dy + delta.dy).clamp(0.0, maxY),
      );
    });
  }

  void _resizeSticker(PlacedSticker sticker, Offset delta) {
    final change = (delta.dx + delta.dy) / 2;
    setState(() {
      sticker.size = (sticker.size + change).clamp(55.0, 260.0);
      sticker.position = Offset(
        sticker.position.dx.clamp(
          0.0,
          math.max(0.0, _canvasSize.width - sticker.size),
        ),
        sticker.position.dy.clamp(
          0.0,
          math.max(0.0, _canvasSize.height - sticker.size),
        ),
      );
    });
  }

  void _removeSticker(PlacedSticker sticker) {
    setState(() {
      _placedStickers.removeWhere((item) => item.id == sticker.id);
      _selectedStickerId = null;
    });
  }

  Widget _buildPlacedSticker(PlacedSticker sticker) {
    final selected = sticker.id == _selectedStickerId;
    const handleSize = 26.0;

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: SizedBox(
        width: sticker.size,
        height: sticker.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedStickerId = sticker.id),
                onPanStart: (_) => setState(() => _selectedStickerId = sticker.id),
                onPanUpdate: (details) => _moveSticker(sticker, details.delta),
                child: Transform.rotate(
                  angle: sticker.rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      border: selected
                          ? Border.all(color: const Color(0xFF8C63C7), width: 2)
                          : null,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: SealImage(seal: sticker.seal, size: sticker.size - 10),
                  ),
                ),
              ),
            ),
            if (selected) ...[
              Positioned(
                top: -38,
                left: sticker.size / 2 - handleSize / 2,
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          sticker.rotation += details.delta.dx * 0.025;
                        });
                      },
                      child: _handle(Icons.rotate_right, handleSize),
                    ),
                    Container(width: 2, height: 12, color: const Color(0xFF8C63C7)),
                  ],
                ),
              ),
              Positioned(
                right: -handleSize / 2,
                top: -handleSize / 2,
                child: GestureDetector(
                  onTap: () => _removeSticker(sticker),
                  child: _handle(Icons.close, handleSize, color: Colors.redAccent),
                ),
              ),
              Positioned(
                right: -handleSize / 2,
                bottom: -handleSize / 2,
                child: GestureDetector(
                  onPanUpdate: (details) => _resizeSticker(sticker, details.delta),
                  child: _handle(Icons.open_in_full, handleSize),
                ),
              ),
              Positioned(left: -5, top: -5, child: _dot()),
              Positioned(left: -5, bottom: -5, child: _dot()),
              Positioned(right: -5, bottom: -5, child: _dot()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handle(IconData icon, double size, {Color color = const Color(0xFF8C63C7)}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }

  Widget _dot() => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8C63C7), width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEFF),
      appBar: AppBar(
        title: const Text(
          'シール帳づくり',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: _saveBook,
            tooltip: 'ほぞん',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedStickerId = null),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/seal_book_background.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                          if (_placedStickers.isEmpty)
                            const Center(
                              child: Text(
                                'したのシールをタップして\n好きなところにはってみよう！',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF8B7B9E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ..._placedStickers.map(_buildPlacedSticker),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'もっているシール（タップではる）',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 76,
                  child: FutureBuilder<List<Seal>>(
                    future: _myStickersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('シールを取得できませんでした: ${snapshot.error}');
                      }
                      final seals = snapshot.data ?? const <Seal>[];
                      if (seals.isEmpty) return const Text('もっているシールはありません');
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: seals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final seal = seals[index];
                          return InkWell(
                            onTap: () => _addStickerToPage(seal),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 68,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EEFA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SealImage(seal: seal, size: 58),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
