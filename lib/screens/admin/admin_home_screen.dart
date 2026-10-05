import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../app_config.dart';
import '../../auth_navigation.dart';
import '../../models/gateway.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';
import 'seal_register_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const Color _purple = Color(0xFF7447C8);
  static const Color _darkPurple = Color(0xFF3E2465);
  static const Color _background = Color(0xFFF7F3FF);

  late Future<_AdminData> _dataFuture;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Timer? _dismissTimer;
  bool _sosActive = false;
  String _sosChildName = '子機';

  @override
  void initState() {
    super.initState();
    _reload();
    _startNotifications();
  }

  void _reload() {
    _dataFuture = _loadData();
  }

  Future<_AdminData> _loadData() async {
    final gateways = await ApiService.fetchUserGateways();
    final catalog = await ApiService.fetchSeals();
    final originals = gateways.isEmpty
        ? const <Seal>[]
        : await ApiService.fetchOriginalSeals(gateways.first.id);
    final sealsById = <String, Seal>{
      for (final seal in catalog) seal.id: seal,
      for (final seal in originals) seal.id: seal,
    };
    return _AdminData(
      gateways: gateways,
      seals: sealsById.values.toList(),
    );
  }

  Future<void> _startNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('親機の通知権限が許可されていません');
        return;
      }
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.registerNotifyToken(token);
      }
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        ApiService.registerNotifyToken(newToken).catchError((error) {
          debugPrint('更新された通知トークンの登録に失敗しました: $error');
        });
      });
      _messageSubscription = FirebaseMessaging.onMessage.listen(_handleMessage);
      _openedMessageSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleMessage(initialMessage);
    } catch (error) {
      debugPrint('通知の初期化に失敗しました: $error');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? message.data['event'] ?? '').toString().toLowerCase();
    final title = (message.notification?.title ?? '').toLowerCase();
    if (!type.contains('sos') && !title.contains('sos')) return;
    if (!mounted) return;
    setState(() {
      _sosActive = true;
      _sosChildName = (message.data['child_name'] ??
              message.data['device_name'] ??
              message.data['child_id'] ??
              '子機')
          .toString();
    });
  }

  void _beginDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sosActive = false);
    });
  }

  void _cancelDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  Future<void> _openEditor(Gateway gateway) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SealRegisterScreen(gateway: gateway)),
    );
    if (changed == true && mounted) {
      setState(() {
        _reload();
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosActive ? const Color(0xFFFF7B81) : _background,
      appBar: AppBar(
        title: Text(_sosActive ? 'SOSアラート' : '親機ステータス・管理画面', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _sosActive ? Colors.transparent : _purple,
        foregroundColor: _sosActive ? Colors.black87 : Colors.white,
        elevation: 0,
        leadingWidth: 132,
        leading: TextButton.icon(
          onPressed: () => logoutAndReturnToLogin(context),
          icon: Icon(
            Icons.logout_rounded,
            size: 18,
            color: _sosActive ? Colors.black87 : Colors.white,
          ),
          label: Text(
            'ログアウト',
            softWrap: false,
            style: TextStyle(
              color: _sosActive ? Colors.black87 : Colors.white,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_AdminData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _purple));
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error, onRetry: () => setState(_reload));
            }
            final data = snapshot.data!;
            if (data.gateways.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('このアカウントに親機が登録されていません', textAlign: TextAlign.center)));
            }
            final gateway = data.gateways.first;
            Seal? selectedSeal;
            for (final seal in data.seals) {
              if (seal.id == gateway.distributeSealId) selectedSeal = seal;
            }
            return _sosActive
                ? _SosBody(
                    gateway: gateway,
                    seal: selectedSeal,
                    childName: _sosChildName,
                    onEdit: () => _openEditor(gateway),
                    onHoldStart: _beginDismiss,
                    onHoldCancel: _cancelDismiss,
                  )
                : _StatusBody(gateway: gateway, seal: selectedSeal, onEdit: () => _openEditor(gateway));
          },
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  static const Color _purple = Color(0xFF7447C8);
  static const Color _darkPurple = Color(0xFF3E2465);
  static const Color _softPurple = Color(0xFFE9DEFF);

  final Gateway gateway;
  final Seal? seal;
  final VoidCallback onEdit;

  const _StatusBody({required this.gateway, required this.seal, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 34),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _softPurple, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x167447C8),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: _GatewayInfo(
                  gateway: gateway,
                  seal: seal,
                  accentColor: _darkPurple,
                  dividerColor: _softPurple,
                ),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'シールを変更',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosBody extends StatelessWidget {
  final Gateway gateway;
  final Seal? seal;
  final String childName;
  final VoidCallback onEdit;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;

  const _SosBody({required this.gateway, required this.seal, required this.childName, required this.onEdit, required this.onHoldStart, required this.onHoldCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
      child: Column(
        children: [
          _GatewayInfo(gateway: gateway, seal: seal, compact: true),
          const SizedBox(height: 22),
          Text('$childName から\nSOSアラートが届きました', textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 76,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFED6E73), foregroundColor: const Color(0xFF7B1518), shape: const RoundedRectangleBorder()),
              child: const Text('シールを変更', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
          Listener(
            onPointerDown: (_) => onHoldStart(),
            onPointerUp: (_) => onHoldCancel(),
            onPointerCancel: (_) => onHoldCancel(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFE4E4E4)),
              child: const Text('安全確認完了（アラート解除）\n長押し3秒', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayInfo extends StatelessWidget {
  final Gateway gateway;
  final Seal? seal;
  final bool compact;
  final Color accentColor;
  final Color dividerColor;

  const _GatewayInfo({
    required this.gateway,
    required this.seal,
    this.compact = false,
    this.accentColor = Colors.black87,
    this.dividerColor = Colors.black26,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('親機登録名', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 22),
            Text('すれ違い　 今日\n　　　　　 累計', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            Text('配布するシール', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          ]),
        ),
        Container(width: 2, height: compact ? 150 : 190, color: dividerColor),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gateway.name, style: TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
            const SizedBox(height: 22),
            Text(
              AppConfig.useDemoData ? '8 回\n127 回' : '— 回\n— 回',
            ),
            const SizedBox(height: 22),
            Text(seal?.name ?? '未設定'),
            const SizedBox(height: 8),
            if (seal != null) SealImage(seal: seal!, size: compact ? 58 : 140),
          ]),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('親機情報を取得できませんでした\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('再試行')),
        ]),
      ),
    );
  }
}

class _AdminData {
  final List<Gateway> gateways;
  final List<Seal> seals;

  const _AdminData({required this.gateways, required this.seals});
}
