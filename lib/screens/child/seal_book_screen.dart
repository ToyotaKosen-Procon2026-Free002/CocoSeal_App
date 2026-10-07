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
  final String id; // DeviceSeal.id を使う
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

class _BookData {
  final List<Seal> catalog;
  final List<DeviceSeal> owned;
  const _BookData({required this.catalog, required this.owned});
}

class _SealBookScreenState extends State<SealBookScreen> {
  late Future<_BookData> _dataFuture;
  final List<PlacedSticker> _placedStickers = [];
  List<DeviceSeal> _owned = const [];
  Map<String, Seal> _catalogById = const {};
  String? _selectedStickerId;
  Size _canvasSize = Size.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_BookData> _load() async {
    final collection = await ApiService.fetchSealCollection(widget.deviceId);
    final owned = AppConfig.useDemoData
        ? collection.owned
        : await ApiService.fetchMySeals(widget.deviceId);
    final catalogById = {for (final seal in collection.catalog) seal.id: seal};

    final placed = <PlacedSticker>[];
    if (AppConfig.useDemoData) {
      final saved = DemoData.loadSealBook(widget.deviceId);
      for (final item in saved) {
        final seal = catalogById[item['seal_id']?.toString()];
        if (seal == null) continue;
        placed.add(PlacedSticker(
          id: item['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
          seal: seal,
          position: Offset(
            (item['x'] as num?)?.toDouble() ?? 0,
            (item['y'] as num?)?.toDouble() ?? 0,
          ),
          size: (item['size'] as num?)?.toDouble() ?? 110,
          rotation: (item['rotation'] as num?)?.toDouble() ?? 0,
        ));
      }
    } else {
      for (final item in owned.where((item) => item.statusId == 1)) {
        final seal = catalogById[item.sealId];
        if (seal == null) continue;
        placed.add(PlacedSticker(
          id: item.id,
          seal: seal,
          position: Offset(item.bookX ?? 0, item.bookY ?? 0),
          size: 110 * (item.bookScale ?? 1),
          rotation: item.bookRotation ?? 0,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _owned = owned;
        _catalogById = catalogById;
        _placedStickers
          ..clear()
          ..addAll(placed);
      });
    }
    return _BookData(catalog: collection.catalog, owned: owned);
  }

  Set<String> get _placedDeviceSealIds => _placedStickers.map((e) => e.id).toSet();

  Future<void> _saveBook() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
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
      } else {
        final placedIds = _placedDeviceSealIds;
        // 現在貼っているシールを status=1 と位置情報付きで保存。
        for (final sticker in _placedStickers) {
          await ApiService.updateDeviceSealStatus(
            deviceId: widget.deviceId,
            deviceSealId: sticker.id,
            statusId: 1,
            bookPage: 0,
            bookX: sticker.position.dx,
            bookY: sticker.position.dy,
            bookRotation: sticker.rotation,
            bookScale: sticker.size / 110,
          );
        }
        // 以前シール帳に貼ってあったが、×で外したものは status=0 に戻す。
        for (final item in _owned.where((e) => e.statusId == 1 && !placedIds.contains(e.id))) {
          await ApiService.updateDeviceSealStatus(
            deviceId: widget.deviceId,
            deviceSealId: item.id,
            statusId: 0,
          );
        }
      }
      if (!mounted) return;
      setState(() => _selectedStickerId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('シール帳を保存しました！')),
      );
      // 保存後の状態を基準にする。
      if (!AppConfig.useDemoData) {
        _owned = await ApiService.fetchMySeals(widget.deviceId);
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addOwnedSticker(DeviceSeal ownedSeal) {
    if (_placedDeviceSealIds.contains(ownedSeal.id)) return;
    final seal = _catalogById[ownedSeal.sealId];
    if (seal == null) return;
    const initialSize = 110.0;
    final start = _canvasSize == Size.zero
        ? const Offset(100, 100)
        : Offset(
            (_canvasSize.width - initialSize) / 2,
            (_canvasSize.height - initialSize) / 2,
          );
    setState(() {
      _placedStickers.add(PlacedSticker(
        id: ownedSeal.id,
        seal: seal,
        position: start,
        size: initialSize,
      ));
      _selectedStickerId = ownedSeal.id;
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
        sticker.position.dx.clamp(0.0, math.max(0.0, _canvasSize.width - sticker.size)),
        sticker.position.dy.clamp(0.0, math.max(0.0, _canvasSize.height - sticker.size)),
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
        child: Stack(clipBehavior: Clip.none, children: [
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
                    border: selected ? Border.all(color: const Color(0xFF8C63C7), width: 2) : null,
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
              child: Column(children: [
                GestureDetector(
                  onPanUpdate: (details) => setState(() => sticker.rotation += details.delta.dx * 0.025),
                  child: _handle(Icons.rotate_right, handleSize),
                ),
                Container(width: 2, height: 12, color: const Color(0xFF8C63C7)),
              ]),
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
          ],
        ]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEFF),
      appBar: AppBar(
        title: const Text('シール帳づくり', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: _saving ? null : _saveBook,
            tooltip: 'ほぞん',
          ),
        ],
      ),
      body: FutureBuilder<_BookData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('シール帳を読み込めませんでした\n${snapshot.error}', textAlign: TextAlign.center));
          }
          final available = _owned.where((item) => item.statusId != 2 && !_placedDeviceSealIds.contains(item.id)).toList();
          return Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(builder: (context, constraints) {
                  _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedStickerId = null),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned.fill(child: Image.asset('assets/images/seal_book_background.png', fit: BoxFit.fill)),
                        if (_placedStickers.isEmpty)
                          const Center(child: Text('したのシールをタップして\n好きなところにはってみよう！', textAlign: TextAlign.center)),
                        ..._placedStickers.map(_buildPlacedSticker),
                      ]),
                    ),
                  );
                }),
              ),
            ),
            Container(
              height: 108,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: available.isEmpty
                  ? const Center(child: Text('はれるシールはありません'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ownedSeal = available[index];
                        final seal = _catalogById[ownedSeal.sealId];
                        if (seal == null) return const SizedBox.shrink();
                        return InkWell(
                          onTap: () => _addOwnedSticker(ownedSeal),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 72,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: const Color(0xFFF3EEFA), borderRadius: BorderRadius.circular(12)),
                            child: SealImage(seal: seal, size: 60),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
