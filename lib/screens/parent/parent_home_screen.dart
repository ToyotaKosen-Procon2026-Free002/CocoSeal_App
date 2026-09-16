import 'package:flutter/material.dart';
import '../../models/nearby_communication.dart';
import 'child_profile_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _isApproachNotifEnabled = true;
  bool _isBatteryNotifEnabled = true;

  // ダミーデータリスト
  final List<NearbyCommunication> _sampleLogs = [
    NearbyCommunication(
      eventId: 'evt_001',
      myId: 'child_01',
      partnerId: '〇✕塾',
      partnerIsGateway: true, // 親機
      timeStamp: DateTime(2026, 9, 16, 15, 0),
    ),
    NearbyCommunication(
      eventId: 'evt_002',
      myId: 'child_01',
      partnerId: 'child_02',
      partnerIsGateway: false, // 子機
      timeStamp: DateTime(2026, 9, 16, 15, 30),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // こどもメニューに切り替えボタン
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildProfileScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'こどもメニューに切り替え',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 通知設定ボタン
              ElevatedButton(
                onPressed: () => _showNotificationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '通知設定',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // 行動ログ領域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          '行動ログ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            itemCount: _sampleLogs.length,
                            // 画像のレイアウトに合わせて余白を設定（線は引かない）
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final log = _sampleLogs[index];

                              // ① 時間を「15 : 0 0」のフォーマットに変換
                              final hour = log.timeStamp.hour.toString().padLeft(2, '0');
                              final minute = log.timeStamp.minute.toString().padLeft(2, '0');
                              final timeStr = '$hour : $minute';

                              final text = log.partnerIsGateway
                                  ? '${log.partnerId}を通過'
                                  : '${log.partnerId}さんと\nすれ違い';

                              return _LogItem(time: timeStr, text: text);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('通知設定', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('親機接近時の自動通知', style: TextStyle(fontSize: 12)),
                    value: _isApproachNotifEnabled,
                    activeTrackColor: Colors.pinkAccent,
                    activeColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                    inactiveThumbColor: Colors.grey[600],
                    onChanged: (val) {
                      setDialogState(() {
                        _isApproachNotifEnabled = val;
                      });
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('バッテリー残量低下（20%以下）の緊急通知', style: TextStyle(fontSize: 12)),
                    value: _isBatteryNotifEnabled,
                    activeTrackColor: Colors.pinkAccent,
                    activeColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                    inactiveThumbColor: Colors.grey[600],
                    onChanged: (val) {
                      setDialogState(() {
                        _isBatteryNotifEnabled = val;
                      });
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  final String time;
  final String text;

  const _LogItem({required this.time, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2, // 画像のような文字間隔
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }
}