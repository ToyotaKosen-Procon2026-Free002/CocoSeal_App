import 'package:flutter/material.dart';
import '../../widgets/pin_code_dialog.dart';
import '../parent/parent_home_screen.dart';
import 'exchange_box_screen.dart';
import 'mission_screen.dart';
import 'passby_check_screen.dart';
import 'rare_spot_map_screen.dart';
import 'seal_book_screen.dart';
import 'seal_dictionary_screen.dart';
import 'seal_exchange_screen.dart';

class ChildHomeScreen extends StatelessWidget {
  final String? childId;
  final String name;
  final String emoji;
  final int battery;
  final int coins;

  const ChildHomeScreen({
    super.key,
    this.childId,
    this.name = 'ななし',
    this.emoji = '👶',
    this.battery = 0,
    this.coins = 0,
  });

  // 保護者メニュー切替ダイアログ呼び出し
  Future<void> _switchToParentMenu(BuildContext context) async {
    const String myParentPin = '1234';

    final bool? isSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const PinCodeDialog(correctPin: myParentPin);
      },
    );

    if (isSuccess == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. トップヘッダー（保護者切り替え）
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _switchToParentMenu(context),
                  child: const Text(
                    '保護者メニューに切り替え',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // 2. プロフィール & ステータスバー（画面に渡された値を直接表示）
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0E0E0),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: const Color(0xFFE0E0E0),
                    child: Text(name, style: const TextStyle(fontSize: 14)),
                  ),
                  const Spacer(),
                  // バッテリー表示
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          battery > 20
                              ? Icons.battery_std
                              : Icons.battery_alert,
                          color: battery > 20 ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        Text(' $battery%',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // コイン表示
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 12)),
                        Text('${coins}枚',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. メインメニュー（レスポンシブ ＆ スクロール不可）
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth > 600;
                    final int crossAxisCount = isWide ? 3 : 2;
                    final int rowCount = isWide ? 2 : 3;

                    const double spacing = 12.0;
                    final double totalHorizontalSpacing =
                        spacing * (crossAxisCount - 1);
                    final double totalVerticalSpacing =
                        spacing * (rowCount - 1);

                    final double itemWidth =
                        (constraints.maxWidth - totalHorizontalSpacing) /
                            crossAxisCount;
                    final double itemHeight =
                        (constraints.maxHeight - totalVerticalSpacing) /
                            rowCount;

                    final double childAspectRatio =
                        (itemWidth > 0 && itemHeight > 0)
                            ? (itemWidth / itemHeight)
                            : 1.0;

                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildMenuButton(
                          context,
                          title: 'すれちがい\nかくにん',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PassbyCheckScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          context,
                          title: 'レアシール\nスポット',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RareSpotMapScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          context,
                          title: 'ウィークリー\nミッション',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MissionScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          context,
                          title: 'シールずかん\nこうかんせってい',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SealDictionaryScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          context,
                          title: 'シール帳づくり',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SealBookScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          context,
                          title: 'シールパック\nこうかん',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SealExchangeScreen()),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 4. フッター（こうかんボックス）
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExchangeBoxScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E0E0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'こうかんボックス',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ボタンパーツ
  Widget _buildMenuButton(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}