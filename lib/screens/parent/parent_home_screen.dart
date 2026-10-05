import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../api_service.dart';
import '../../app_config.dart';
import '../../auth_navigation.dart';
import '../../models/device.dart';
import '../../models/nearby_communication.dart';
import 'child_profile_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  static const Color _purple = Color(0xFF7447C8);
  static const Color _darkPurple = Color(0xFF3E2465);
  static const Color _background = Color(0xFFF7F3FF);
  static const Color _softPurple = Color(0xFFE9DEFF);

  bool _isApproachNotifEnabled = true;
  bool _isBatteryNotifEnabled = false; // デザイン仕様に合わせて初期値を調整
  late Future<_ActivityLogData> _logsFuture;
  String? _selectedDeviceId;

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

  Future<_ActivityLogData> _loadLogs() async {
    final devices = await ApiService.fetchUserDevices();
    final endAt = DateTime.now();
    final startAt = endAt.subtract(const Duration(days: 7));
    final logs = <_ChildActivityLog>[];
    for (final device in devices) {
      final deviceLogs = await ApiService.fetchNearbyCommunications(
        deviceId: device.id,
        startAt: startAt,
        endAt: endAt,
      );
      logs.addAll(
        deviceLogs.map(
          (log) => _ChildActivityLog(device: device, log: log),
        ),
      );
    }
    if (AppConfig.useDemoData && devices.isNotEmpty) {
      logs.add(
        _ChildActivityLog.sos(
          device: devices.first,
          timeStamp: endAt.subtract(const Duration(minutes: 18)),
        ),
      );
    }
    logs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return _ActivityLogData(devices: devices, logs: logs);
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
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 保護者・こども画面で表記を統一したメニュー切り替えボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => logoutAndReturnToLogin(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('ログアウト'),
                    style: TextButton.styleFrom(foregroundColor: _darkPurple),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChildProfileScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'メニューきりかえ',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 通知設定ボタン
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _showNotificationDialog(context),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.hovered)
                          ? _purple
                          : _softPurple,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.hovered)
                          ? Colors.white
                          : _darkPurple,
                    ),
                    elevation: const WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      ),
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
                  decoration: BoxDecoration(
                    color: _softPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '行動ログ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: FutureBuilder<_ActivityLogData>(
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
                              final data = snapshot.data ?? const _ActivityLogData();
                              final selectedDeviceId = data.devices.any(
                                (device) => device.id == _selectedDeviceId,
                              )
                                  ? _selectedDeviceId
                                  : null;
                              final logs = selectedDeviceId == null
                                  ? data.logs
                                  : data.logs
                                      .where(
                                        (item) =>
                                            item.device.id == selectedDeviceId,
                                      )
                                      .toList();
                              if (logs.isEmpty) {
                                return Column(
                                  children: [
                                    if (data.devices.isNotEmpty)
                                      _ChildSelector(
                                        devices: data.devices,
                                        selectedDeviceId: selectedDeviceId,
                                        onSelected: (deviceId) {
                                          setState(() {
                                            _selectedDeviceId = deviceId;
                                          });
                                        },
                                      ),
                                    const Expanded(
                                      child: Center(
                                        child: Text('過去7日間の行動ログはありません'),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _ChildSelector(
                                    devices: data.devices,
                                    selectedDeviceId: selectedDeviceId,
                                    onSelected: (deviceId) {
                                      setState(() {
                                        _selectedDeviceId = deviceId;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: RefreshIndicator(
                                      onRefresh: () async => _reloadLogs(),
                                      child: ListView.separated(
                                        itemCount: logs.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 24),
                                        itemBuilder: (context, index) {
                                          final item = logs[index];
                                          final log = item.log;
                                          final local = item.timeStamp.toLocal();
                                          final month = local.month
                                              .toString()
                                              .padLeft(2, '0');
                                          final day = local.day
                                              .toString()
                                              .padLeft(2, '0');
                                          final hour = local.hour
                                              .toString()
                                              .padLeft(2, '0');
                                          final minute = local.minute
                                              .toString()
                                              .padLeft(2, '0');
                                          final text = item.isSos
                                              ? 'SOSを受信しました'
                                              : log!.partnerIsGateway
                                                  ? '${log.partnerId}を通過'
                                                  : '${log.partnerId}さんとすれ違い';
                                          return _LogItem(
                                            date: '$month/$day',
                                            time: '$hour:$minute',
                                            childName: item.device.name,
                                            text: text,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
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
                        Expanded(
                          child: Text(
                            '親機通過時の自動通知',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isApproachNotifEnabled ? Colors.black87 : Colors.black38,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isApproachNotifEnabled,
                            activeTrackColor: _softPurple,
                            activeColor: _purple,
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
                        Expanded(
                          child: Text(
                            'バッテリー残量低下（２０％以下）の警告通知',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isBatteryNotifEnabled ? Colors.black87 : Colors.black38,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isBatteryNotifEnabled,
                            activeTrackColor: _softPurple,
                            activeColor: _purple,
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
  final String date;
  final String time;
  final String childName;
  final String text;

  const _LogItem({
    required this.date,
    required this.time,
    required this.childName,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF7447C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                childName,
                style: const TextStyle(
                  color: Color(0xFF3E2465),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildSelector extends StatelessWidget {
  final List<Device> devices;
  final String? selectedDeviceId;
  final ValueChanged<String?> onSelected;

  const _ChildSelector({
    required this.devices,
    required this.selectedDeviceId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _SelectorChip(
            label: '全員',
            selected: selectedDeviceId == null,
            onTap: () => onSelected(null),
          ),
          for (final device in devices) ...[
            const SizedBox(width: 8),
            _SelectorChip(
              label: device.name,
              selected: selectedDeviceId == device.id,
              onTap: () => onSelected(device.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7447C8) : const Color(0xFFF1EBFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3E2465),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActivityLogData {
  final List<Device> devices;
  final List<_ChildActivityLog> logs;

  const _ActivityLogData({
    this.devices = const <Device>[],
    this.logs = const <_ChildActivityLog>[],
  });
}

class _ChildActivityLog {
  final Device device;
  final NearbyCommunication? log;
  final DateTime timeStamp;
  final bool isSos;

  _ChildActivityLog({required this.device, required NearbyCommunication log})
      : log = log,
        timeStamp = log.timeStamp,
        isSos = false;

  const _ChildActivityLog.sos({
    required this.device,
    required this.timeStamp,
  })  : log = null,
        isSos = true;
}
