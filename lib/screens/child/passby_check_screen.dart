import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassbyCheckScreen extends StatelessWidget {
  const PassbyCheckScreen({super.key});

  // ポップアップを表示する関数
  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    // Timestampを文字列に変換
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final DateTime dateTime = timestamp?.toDate() ?? DateTime.now();
    final String formattedDate = 
        '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 8),
              _buildPopupRow('くれたともだち', data['partner_name'] ?? '不明'),
              _buildPopupRow('シールのなまえ', data['seal_name'] ?? 'なし'),
              _buildPopupRow('すれちがったじかん', formattedDate),
              _buildPopupRow('すれちがったばしょ', data['location_name'] ?? '不明'),
              _buildPopupRow('かくとくコイン', '${data['coins_earned'] ?? 0}コイン'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
          Container(width: 1, height: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれちがいりれき', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FirestoreからESP-0001のすれ違いログを取得（新しい順）
        stream: FirebaseFirestore.instance
            .collection('children')
            .doc('ESP-0001')
            .collection('actions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('すれちがいりれきがありません'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2列で表示
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () => _showDetailDialog(context, data),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // シールやアバターの画像枠（ダミーアイコン）
                        const Icon(Icons.stars, size: 50, color: Colors.pinkAccent),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(radius: 8, backgroundColor: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              data['partner_name'] ?? 'ななし',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}