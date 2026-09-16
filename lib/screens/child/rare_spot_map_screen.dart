import 'package:flutter/material.dart';

class RareSpotMapScreen extends StatefulWidget {
  const RareSpotMapScreen({super.key});

  @override
  State<RareSpotMapScreen> createState() => _RareSpotMapScreenState();
}

class _RareSpotMapScreenState extends State<RareSpotMapScreen> {
  // 疑似マップ上のスポット一覧データ
  final List<Map<String, dynamic>> _spots = [
    {
      'name': 'セントラル公園の時計台',
      'distance': 'あと 120m',
      'sealName': 'こうえんのハトシール',
      'icon': '🕊️',
      'top': 120.0,
      'left': 80.0,
      'isVisited': false,
    },
    {
      'name': '図書館前プレイスポット',
      'distance': 'あと 450m',
      'sealName': 'ものしりフクロウ',
      'icon': '🦉',
      'top': 280.0,
      'left': 220.0,
      'isVisited': false,
    },
    {
      'name': '駅前シンボルツリー',
      'distance': 'あと 800m',
      'sealName': 'キラキラすずめ',
      'icon': '🐤',
      'top': 420.0,
      'left': 100.0,
      'isVisited': true,
    },
  ];

  // スポット詳細ダイアログ
  void _showSpotDetail(Map<String, dynamic> spot, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spot['icon'],
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  spot['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '距離: ${spot['distance']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('もらえるシール: ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      Text(
                        spot['sealName'],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!spot['isVisited'])
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _checkIn(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC0CB),
                          elevation: 0,
                        ),
                        child: const Text('チェックイン！', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ゲット済み', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        elevation: 0,
                      ),
                      child: const Text('とじる', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // チェックイン処理＆シールゲットモーダル
  void _checkIn(int index) {
    setState(() {
      _spots[index]['isVisited'] = true;
    });

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 スポット到着！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Text(_spots[index]['icon'], style: const TextStyle(fontSize: 60)),
                const SizedBox(height: 8),
                Text(
                  '「${_spots[index]['sealName']}」\nをゲットしたよ！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC0CB),
                    elevation: 0,
                  ),
                  child: const Text('やったー！', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // マップっぽいライトグリーン
      appBar: AppBar(
        title: const Text(
          'レアシールスポット',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          // 背景の格子状マップグリッド線 (subdivisions を小文字に修正)
          Positioned.fill(
            child: GridPaper(
              color: Colors.green.withAlpha(30),
              divisions: 2,
              subdivisions: 2,
            ),
          ),

          // 現在地マーク（自分）(const 位置を調整)
          Positioned(
            bottom: 40,
            left: 160,
            child: Column(
              children: [
                const Icon(Icons.my_location, color: Colors.blue, size: 36),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.white,
                  child: const Text('いまここ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ],
            ),
          ),

          // マップ上のスポットピン
          ..._spots.asMap().entries.map((entry) {
            int idx = entry.key;
            var spot = entry.value;

            return Positioned(
              top: spot['top'],
              left: spot['left'],
              child: GestureDetector(
                onTap: () => _showSpotDetail(spot, idx),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: spot['isVisited'] ? Colors.grey[300] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(spot['icon'], style: const TextStyle(fontSize: 24)),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}