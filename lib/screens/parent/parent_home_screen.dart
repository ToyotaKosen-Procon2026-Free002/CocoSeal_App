import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../api_service.dart';
import '../../models/nearby_communication.dart';
import 'child_profile_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _isApproachNotifEnabled = true;
  bool _isBatteryNotifEnabled = false; // デザイン仕様に合わせて初期値を調整
  late Future<List<NearbyCommunication>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _reloadLogs();
  }

  void _reloadLogs() {
    setState(() {
      _logsFuture = _loadLogs();
    });
  }

  Future<List<NearbyCommunication>> _loadLogs() async {
    final devices = await ApiService.fetchUserDevices();
    final endAt = DateTime.now();
    final startAt = endAt.subtract(const Duration(days: 7));
    final logs = <NearbyCommunication>[];
    for (final device in devices) {
      logs.addAll(await ApiService.fetchNearbyCommunications(
        deviceId: device.id,
        startAt: startAt,
        endAt: endAt,
      ));
    }
    logs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return logs;
  }

  /// FCMトークンの取得とサーバー連動処理
  Future<void> _updateNotificationToken(bool enable) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      if (enable) {
        // 通知権限の要求
        NotificationSettings settings = await messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          String? token = await messaging.getToken();
          if (token != null) {
            // API: POST /users/notify_token
            await ApiService.registerNotifyToken(token);
          }
        }
      } else {
        String? token = await messaging.getToken();
        if (token != null) {
          // API: DELETE /users/notify_token
          await ApiService.deleteNotifyToken(token);
        }
      }
    } catch (e) {
      debugPrint('通知トークン設定エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 通知設定ボタン
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _showNotificationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    '通知設定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 行動ログ領域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9D9D9),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '行動ログ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          color: Colors.white,
                          child: FutureBuilder<List<NearbyCommunication>>(
                            future: _logsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('行動ログを取得できませんでした\n${snapshot.error}',
                                          textAlign: TextAlign.center),
                                      TextButton(onPressed: _reloadLogs, child: const Text('再試行')),
                                    ],
                                  ),
                                );
                              }
                              final logs = snapshot.data ?? const <NearbyCommunication>[];
                              if (logs.isEmpty) {
                                return const Center(child: Text('過去7日間の行動ログはありません'));
                              }
                              return RefreshIndicator(
                                onRefresh: () async => _reloadLogs(),
                                child: ListView.separated(
                                  itemCount: logs.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final log = logs[index];
                                    final local = log.timeStamp.toLocal();
                                    final hour = local.hour.toString().padLeft(2, '0');
                                    final minute = local.minute.toString().padLeft(2, '0');
                                    final text = log.partnerIsGateway
                                        ? '${log.partnerId}を通過'
                                        : '${log.partnerId}さんと\nすれ違い';
                                    return _LogItem(time: '$hour : $minute', text: text);
                                  },
                                ),
                              );
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

  /// 通知設定ポップアップダイアログ
  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー（タイトル ＆ ✕ボタン）
                    Stack(
                      children: [
                        const Center(
                          child: Text(
                            '通知設定',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: -8,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 親機通過時の自動通知 Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '親機通過時の自動通知',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isApproachNotifEnabled,
                            activeTrackColor: const Color(0xFFF4B8B8),
                            activeColor: Colors.black,
                            inactiveTrackColor: Colors.grey[300],
                            inactiveThumbColor: Colors.grey[600],
                            onChanged: (val) async {
                              setDialogState(() {
                                _isApproachNotifEnabled = val;
                              });
                              setState(() {});
                              await _updateNotificationToken(val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24, thickness: 0.8),

                    // バッテリー残量低下の警告通知 Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'バッテリー残量低下（２０％以下）の警告通知',
                            style: TextStyle(fontSize: 11, color: Colors.black38),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isBatteryNotifEnabled,
                            activeTrackColor: const Color(0xFFF4B8B8),
                            activeColor: Colors.black,
                            inactiveTrackColor: Colors.grey[200],
                            inactiveThumbColor: Colors.grey[400],
                            onChanged: (val) {
                              setDialogState(() {
                                _isBatteryNotifEnabled = val;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
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
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.3,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
