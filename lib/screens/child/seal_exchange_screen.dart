import 'package:flutter/material.dart';

class SealExchangeScreen extends StatefulWidget {
  const SealExchangeScreen({super.key});

  @override
  State<SealExchangeScreen> createState() => _SealExchangeScreenState();
}

class _SealExchangeScreenState extends State<SealExchangeScreen> {
  // 所持コイン数（Stateで管理）
  int userCoins = 38;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'シールパックこうかん',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 所持コイン表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 18)),
                  Text(
                    '$userCoins枚',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // パック一覧
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPackCard(
                    title: '♡  おともだちパック',
                    description: 'ノーマルシールが３枚入ってるよ',
                    requiredCoins: 10,
                    itemCount: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildPackCard(
                    title: '★  キラキラパック',
                    description: 'めったに手に入らないレアシールが\nかならず１枚当たる！',
                    requiredCoins: 50, // コイン不足のテスト用（50枚）
                    itemCount: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // パック表示カード
  Widget _buildPackCard({
    required String title,
    required String description,
    required int requiredCoins,
    required int itemCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          Text('$itemCountまい入り : 必要なコイン 🪙 $requiredCoins枚', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showExchangeDialog(title, requiredCoins),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC0CB), // ピンク
                elevation: 0,
              ),
              child: const Text('このパックとこうかんする', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 交換確認モーダル（コイン不足判定＆ボタン色切り替え付き）
  void _showExchangeDialog(String packTitle, int cost) {
    bool hasEnoughCoins = userCoins >= cost;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$costコインで$packTitleと\nこうかんしますか？',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                // コイン不足時のアラート表示
                if (!hasEnoughCoins) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'コインがたりないよ！',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ダイアログを閉じる
                        if (hasEnoughCoins) {
                          setState(() {
                            userCoins -= cost; // コイン減算
                          });
                          _showResultDialog(); // 獲得結果モーダルを表示
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        // コインが足りない時は「もどる」と同じグレー色にする
                        backgroundColor: hasEnoughCoins
                            ? const Color(0xFFFFC0CB)
                            : const Color(0xFFE0E0E0),
                        elevation: 0,
                      ),
                      child: const Text('はい', style: TextStyle(color: Colors.black87)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        elevation: 0,
                      ),
                      child: const Text('もどる', style: TextStyle(color: Colors.black87)),
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

  // 獲得結果モーダル
  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ゲットしたシール', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return const Column(
                      children: [
                        Text('🪼', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 4),
                        Text('★★★', style: TextStyle(fontSize: 10, color: Colors.amber)),
                        Text('ぶかぶかくらげ', style: TextStyle(fontSize: 10, color: Colors.black87)),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 20),
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
          ),
        );
      },
    );
  }
}