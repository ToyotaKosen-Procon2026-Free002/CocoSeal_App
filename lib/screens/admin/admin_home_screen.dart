import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // 画面に表示するダミーデータ（将来的にFirebase等から取得する部分）
  final String parentName = 'とよたこうばん';
  final int todayCount = 5;
  final int totalCount = 155;
  final String stickerName = 'いるか';
  final String stickerImageUrl = ''; // 画像URLやアセットパスを指定

  // 「設定・シールを変更」ボタンが押された時の処理
  void _navigateToEditScreen() {
    // 3-16 シール登録（編集）画面への遷移処理
    // 例: Navigator.push(context, MaterialPageRoute(builder: (_) => const StickerRegisterScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('シール登録・設定画面へ移動します')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '親機ステータス・管理画面',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            children: [
              // ----------------------------------------------------
              // ① 上部〜中央：ステータス＆シール情報エリア（左右分割）
              // ----------------------------------------------------
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 左側：項目ラベル群 ---
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '親機登録名',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'すれ違い',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('今日', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                  SizedBox(height: 4),
                                  Text('累計', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            '配布するシール',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    // --- 中央：縦の区切り線 ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: VerticalDivider(
                        color: Colors.grey[400],
                        thickness: 1,
                      ),
                    ),

                    // --- 右側：データ表示群 ---
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 親機登録名
                          Text(
                            parentName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 回数（今日・累計）
                          Text(
                            '$todayCount 回',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCount 回',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),

                          const SizedBox(height: 24),

                          // 配布シール名
                          Text(
                            stickerName,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),

                          const SizedBox(height: 12),

                          // シールのイラスト表示
                          stickerImageUrl.isNotEmpty
                              ? Image.network(
                                  stickerImageUrl,
                                  height: 80,
                                  fit: BoxFit.contain,
                                )
                              : const Icon(
                                  Icons.pets, // いるか/シャチっぽい仮アイコン
                                  size: 80,
                                  color: Colors.black87,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ----------------------------------------------------
              // ② 画面下部：「設定・シールを変更」ボタン
              // ----------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 100,
                child: ElevatedButton(
                  onPressed: _navigateToEditScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9), // 画像の薄いグレー
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 画像に合わせて四角ボタン
                    ),
                  ),
                  child: const Text(
                    '設定・シールを変更',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}