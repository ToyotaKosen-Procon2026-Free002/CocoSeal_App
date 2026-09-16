import 'package:flutter/material.dart';

class SealItem {
  final String id;
  final String name;
  final String emoji;
  final String rarity;
  final bool isDiscovered;
  bool isForTrade;

  SealItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.isDiscovered,
    this.isForTrade = false,
  });
}

class SealDictionaryScreen extends StatefulWidget {
  const SealDictionaryScreen({super.key});

  @override
  State<SealDictionaryScreen> createState() => _SealDictionaryScreenState();
}

class _SealDictionaryScreenState extends State<SealDictionaryScreen> {
  final List<SealItem> _sealList = [
    SealItem(id: '1', name: 'たこまる', emoji: '🐙', rarity: 'Normal', isDiscovered: true, isForTrade: true),
    SealItem(id: '2', name: 'はとぽっぽ', emoji: '🕊️', rarity: 'Normal', isDiscovered: true, isForTrade: false),
    SealItem(id: '3', name: 'ふくろうさん', emoji: '🦉', rarity: 'Rare', isDiscovered: true, isForTrade: true),
    SealItem(id: '4', name: 'さくらちゃん', emoji: '🌸', rarity: 'Rare', isDiscovered: true, isForTrade: false),
    SealItem(id: '5', name: 'きんのとうむ', emoji: '👑', rarity: 'Super Rare', isDiscovered: true, isForTrade: false),
    SealItem(id: '6', name: 'くまさん', emoji: '🐻', rarity: 'Normal', isDiscovered: true, isForTrade: false),
    SealItem(id: '7', name: 'ほしぞら', emoji: '⭐', rarity: 'Rare', isDiscovered: false),
    SealItem(id: '8', name: 'ふうせん', emoji: '🎈', rarity: 'Normal', isDiscovered: false),
    SealItem(id: '9', name: 'にじのひかり', emoji: '🌈', rarity: 'Super Rare', isDiscovered: false),
  ];

  @override
  Widget build(BuildContext context) {
    final discoveredCount = _sealList.where((s) => s.isDiscovered).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('シールずかん・こうかんせってい', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // 進捗表示
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF5F5F5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('あつめたシール', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$discoveredCount / ${_sealList.length} 種',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _sealList.length,
              itemBuilder: (context, index) {
                final item = _sealList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // アイコン
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: item.isDiscovered ? const Color(0xFFF0E6FF) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              item.isDiscovered ? item.emoji : '❓',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 詳細
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isDiscovered ? item.name : '？？？？？',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: item.isDiscovered ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.rarity == 'Super Rare'
                                      ? Colors.amber.shade100
                                      : (item.rarity == 'Rare' ? Colors.blue.shade100 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.rarity,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.rarity == 'Super Rare' ? Colors.orange.shade900 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 交換OKスイッチ（発見済みのみ）
                        if (item.isDiscovered)
                          Column(
                            children: [
                              const Text('こうかん', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Switch(
                                value: item.isForTrade,
                                activeTrackColor: Colors.purple.shade200,
                                activeThumbColor: Colors.purple,
                                onChanged: (val) {
                                  setState(() {
                                    item.isForTrade = val;
                                  });
                                },
                            )
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}