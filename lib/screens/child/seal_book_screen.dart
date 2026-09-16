import 'package:flutter/material.dart';

class SealBookScreen extends StatefulWidget {
  const SealBookScreen({super.key});

  @override
  State<SealBookScreen> createState() => _SealBookScreenState();
}

class PlacedSticker {
  final String id;
  final String emoji;
  Offset position;

  PlacedSticker({required this.id, required this.emoji, required this.position});
}

class _SealBookScreenState extends State<SealBookScreen> {
  final List<String> _myStickers = ['🐙', '🕊️', '🦉', '🌸', '👑', '🐻', '⭐', '🎈'];
  final List<PlacedSticker> _placedStickers = [];
  Color _pageBgColor = const Color(0xFFFFF8E1); // 淡いクリーム色

  void _addStickerToPage(String emoji) {
    setState(() {
      _placedStickers.add(
        PlacedSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          emoji: emoji,
          position: const Offset(120, 180),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シール帳づくり', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              setState(() {
                if (_pageBgColor == const Color(0xFFFFF8E1)) {
                  _pageBgColor = const Color(0xFFE1F5FE); // 淡い水色
                } else if (_pageBgColor == const Color(0xFFE1F5FE)) {
                  _pageBgColor = const Color(0xFFF3E5F5); // 淡い紫
                } else {
                  _pageBgColor = const Color(0xFFFFF8E1);
                }
              });
            },
            tooltip: '背景色チェンジ',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('シール帳を保存しました！')),
              );
            },
            tooltip: 'ほぞん',
          ),
        ],
      ),
      body: Column(
        children: [
          // シール帳の台紙エリア
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _pageBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Stack(
                children: [
                  if (_placedStickers.isEmpty)
                    const Center(
                      child: Text(
                        'したのシールをタップして\nここに はってみよう！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ..._placedStickers.map((sticker) {
                    return Positioned(
                      left: sticker.position.dx,
                      top: sticker.position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            sticker.position += details.delta;
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _placedStickers.removeWhere((s) => s.id == sticker.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('シールをはがしました'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Text(
                          sticker.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 下部：持っているシール一覧（引き出し）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, -2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'もっているシール（タップで はる / なが押しで はがす）',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _myStickers.length,
                    itemBuilder: (context, index) {
                      final emoji = _myStickers[index];
                      return GestureDetector(
                        onTap: () => _addStickerToPage(emoji),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 32)),
                          ),
                        ),
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