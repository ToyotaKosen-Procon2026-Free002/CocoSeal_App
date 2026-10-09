import 'dart:async';

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../api_service.dart';

import '../../app_config.dart';

import '../../auth_navigation.dart';

import '../../models/gateway.dart';

import '../../models/seal.dart';

import '../../widgets/seal_image.dart';

import 'seal_register_screen.dart';

import 'gateway_location_screen.dart';

import 'gateway_select_screen.dart';

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

  String? _selectedGatewayId;

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

    // 現在選択中の親機を使ってオリジナルシールを取得する。
    // 親機未選択時だけ一覧の1台目を使う。
    List<Seal> originals = const <Seal>[];

    if (gateways.isNotEmpty) {
      Gateway selectedGateway = gateways.first;

      if (_selectedGatewayId != null) {
        for (final gateway in gateways) {
          if (gateway.id == _selectedGatewayId) {
            selectedGateway = gateway;
            break;
          }
        }
      }

      try {
        originals = await ApiService.fetchOriginalSeals(selectedGateway.id);
      } catch (error) {
        debugPrint(
          'オリジナルシールの取得に失敗しました '
          '(gatewayId: ${selectedGateway.id}): $error',
        );
      }
    }

    final sealsById = <String, Seal>{
      for (final seal in catalog) seal.id: seal,
      for (final seal in originals) seal.id: seal,
    };

    return _AdminData(gateways: gateways, seals: sealsById.values.toList());
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

      _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessage,
      );

      final initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null) _handleMessage(initialMessage);
    } catch (error) {
      debugPrint('通知の初期化に失敗しました: $error');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? message.data['event'] ?? '')
        .toString()
        .toLowerCase();

    final title = (message.notification?.title ?? '').toLowerCase();

    if (!type.contains('sos') && !title.contains('sos')) return;

    if (!mounted) return;

    setState(() {
      _sosActive = true;

      _sosChildName =
          (message.data['child_name'] ??
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

  Future<void> _registerGateway() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _GatewayRegisterScreen()),
    );

    if (registered == true && mounted) {
      setState(_reload);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('親機を登録しました')));
    }
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

  Future<void> _selectGateway() async {
    try {
      final gateways = await ApiService.fetchUserGateways();

      if (!mounted || gateways.isEmpty) return;

      final selected = await Navigator.push<Gateway>(
        context,

        MaterialPageRoute(
          builder: (_) => GatewaySelectScreen(
            gateways: gateways,

            selectedGatewayId: _selectedGatewayId,
          ),
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedGatewayId = selected.id;

          _reload();
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('親機一覧を取得できませんでした: $e')));
    }
  }

  Future<void> _configureGatewayWifi(Gateway gateway) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _GatewayRegisterScreen(gateway: gateway),
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${gateway.name} のWi-Fi設定を更新しました')),
      );
    }
  }

  Future<void> _editGatewayLocation() async {
    try {
      final gateways = await ApiService.fetchUserGateways();

      if (!mounted || gateways.isEmpty) return;

      Gateway gateway = gateways.first;

      if (_selectedGatewayId != null) {
        for (final item in gateways) {
          if (item.id == _selectedGatewayId) {
            gateway = item;

            break;
          }
        }
      }

      final changed = await Navigator.push<bool>(
        context,

        MaterialPageRoute(
          builder: (_) => GatewayLocationScreen(gateway: gateway),
        ),
      );

      if (changed == true && mounted) {
        setState(_reload);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('親機情報を取得できませんでした: $e')));
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
        title: Text(
          _sosActive ? 'SOSアラート' : '親機ステータス・管理画面',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        backgroundColor: _sosActive ? Colors.transparent : _purple,

        foregroundColor: _sosActive ? Colors.black87 : Colors.white,

        elevation: 0,

        leadingWidth: 118,
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
        ),

        actions: [
          IconButton(
            onPressed: _sosActive ? null : _selectGateway,

            icon: const Icon(Icons.swap_horiz_rounded),

            tooltip: '親機を切り替える',
          ),

          IconButton(
            onPressed: _sosActive ? null : _editGatewayLocation,

            icon: const Icon(Icons.location_on_outlined),

            tooltip: '設置場所を登録・変更',
          ),

          IconButton(
            onPressed: _sosActive
                ? null
                : () async {
                    try {
                      final gateways = await ApiService.fetchUserGateways();
                      if (!mounted || gateways.isEmpty) return;

                      Gateway gateway = gateways.first;
                      if (_selectedGatewayId != null) {
                        for (final item in gateways) {
                          if (item.id == _selectedGatewayId) {
                            gateway = item;
                            break;
                          }
                        }
                      }

                      await _configureGatewayWifi(gateway);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('親機情報を取得できませんでした: $e')),
                      );
                    }
                  },
            icon: const Icon(Icons.wifi_rounded),
            tooltip: 'Wi-Fi設定',
          ),

          TextButton.icon(
            onPressed: _sosActive ? null : _registerGateway,

            icon: Icon(
              Icons.add_circle_outline_rounded,

              size: 18,

              color: _sosActive ? Colors.black87 : Colors.white,
            ),

            label: Text(
              '親機を登録',

              softWrap: false,

              style: TextStyle(
                color: _sosActive ? Colors.black87 : Colors.white,

                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: FutureBuilder<_AdminData>(
          future: _dataFuture,

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _purple),
              );
            }

            if (snapshot.hasError) {
              return _ErrorView(
                error: snapshot.error,

                onRetry: () => setState(_reload),

                onRegister: _registerGateway,
              );
            }

            final data = snapshot.data!;

            if (data.gateways.isEmpty) {
              return _EmptyGatewayView(onRegister: _registerGateway);
            }

            Gateway gateway = data.gateways.first;

            if (_selectedGatewayId != null) {
              for (final item in data.gateways) {
                if (item.id == _selectedGatewayId) {
                  gateway = item;

                  break;
                }
              }
            }

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
                : _StatusBody(
                    gateway: gateway,
                    seal: selectedSeal,
                    onEdit: () => _openEditor(gateway),
                  );
          },
        ),
      ),
    );
  }
}

class _GatewayRegisterScreen extends StatefulWidget {
  final Gateway? gateway;

  const _GatewayRegisterScreen({this.gateway});

  @override
  State<_GatewayRegisterScreen> createState() => _GatewayRegisterScreenState();
}

class _GatewayRegisterScreenState extends State<_GatewayRegisterScreen> {
  static const Color _purple = Color(0xFF7447C8);

  static const Color _background = Color(0xFFF7F3FF);

  static final Guid _serviceUuid = Guid('42fbd1f2-b02c-1ba6-87f8-7d9ca4f3a343');

  static final Guid _configUuid = Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');

  static final Guid _statusUuid = Guid('d29ae63e-b7d3-4874-a690-3432b85e05a5');

  final TextEditingController _ssidController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final Map<String, ScanResult> _found = {};

  BluetoothDevice? _selectedDevice;

  bool _scanning = false;

  bool _submitting = false;

  bool _obscurePassword = true;

  String? _errorText;

  String _statusText = '近くの親機を検索してください';

  List<ScanResult> get _results {
    final list = _found.values.toList();

    list.sort((a, b) => b.rssi.compareTo(a.rssi));

    return list;
  }

  String _deviceName(ScanResult result) {
    final adv = result.advertisementData.advName.trim();

    if (adv.isNotEmpty) return adv;

    final platform = result.device.platformName.trim();

    return platform.isNotEmpty ? platform : 'COCO 親機';
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();

    FlutterBluePlus.stopScan();

    _ssidController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  Future<bool> _requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,

      Permission.bluetoothConnect,
    ].request();

    final granted = statuses.values.every((status) => status.isGranted);

    if (!granted && mounted) {
      setState(() {
        _errorText = 'Bluetoothの「付近のデバイス」権限を許可してください。';
      });
    }

    return granted;
  }

  Future<void> _scan() async {
    if (_submitting || _scanning) return;

    setState(() {
      _errorText = null;

      _statusText = 'Bluetoothを確認しています…';

      _found.clear();

      _selectedDevice = null;
    });

    try {
      if (!await _requestBluetoothPermissions()) return;

      if (!await FlutterBluePlus.isSupported) {
        throw Exception('この端末はBluetooth LEに対応していません。');
      }

      if (!await FlutterBluePlus.isOn) {
        setState(() => _statusText = 'Bluetoothをオンにしてください');

        return;
      }

      await _scanSubscription?.cancel();

      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          if (!mounted) return;

          bool changed = false;

          for (final result in results) {
            final name = _deviceName(result);

            final advertisesCocoService = result.advertisementData.serviceUuids
                .any((uuid) => uuid == _serviceUuid);

            if (name.toUpperCase().startsWith('COCO-') ||
                advertisesCocoService) {
              _found[result.device.remoteId.str] = result;

              changed = true;
            }
          }

          if (changed) setState(() {});
        },

        onError: (Object error) {
          if (mounted) setState(() => _errorText = '親機の検索に失敗しました: $error');
        },
      );

      setState(() {
        _scanning = true;

        _statusText = '近くの親機を検索中…';
      });

      await FlutterBluePlus.startScan(
        withServices: [_serviceUuid],

        timeout: const Duration(seconds: 10),

        androidUsesFineLocation: false,
      );

      await FlutterBluePlus.isScanning.where((value) => value == false).first;

      if (!mounted) return;

      setState(() {
        _scanning = false;

        _statusText = _found.isEmpty
            ? '親機が見つかりませんでした。親機の電源を確認して再検索してください。'
            : '${_found.length}台の親機が見つかりました';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _scanning = false;

        _errorText = '親機の検索に失敗しました: $error';
      });
    }
  }

  BluetoothCharacteristic _findCharacteristic(
    List<BluetoothService> services,

    Guid characteristicUuid,
  ) {
    for (final service in services) {
      if (service.uuid != _serviceUuid) continue;

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == characteristicUuid) return characteristic;
      }
    }

    throw Exception('親機に必要なGATT Characteristicが見つかりません。');
  }

  Future<Map<String, dynamic>> _readStatus(
    BluetoothCharacteristic statusChar,
  ) async {
    final bytes = await statusChar.read();

    if (bytes.isEmpty) throw Exception('親機のステータスを取得できませんでした。');

    final text = utf8.decode(bytes);

    final decoded = jsonDecode(text);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('親機から不正なステータスが返されました。');
    }

    return decoded;
  }

  Future<void> _provisionAndRegister() async {
    final device = _selectedDevice;

    final ssid = _ssidController.text.trim();

    final password = _passwordController.text;

    if (device == null) {
      setState(() => _errorText = '登録する親機を選択してください。');

      return;
    }

    if (ssid.isEmpty) {
      setState(() => _errorText = 'Wi-Fi名（SSID）を入力してください。');

      return;
    }

    if (password.isEmpty) {
      setState(() => _errorText = 'Wi-Fiパスワードを入力してください。');

      return;
    }

    setState(() {
      _submitting = true;

      _errorText = null;

      _statusText = '親機に接続しています…';
    });

    try {
      await FlutterBluePlus.stopScan();

      if (device.isDisconnected) {
        await device.connect(
          timeout: const Duration(seconds: 15),

          license: License.free,
        );
      }

      if (!mounted) return;

      setState(() => _statusText = '親機の通信設定を確認しています…');

      // SSIDやWPAパスワードは20バイトを超えることがあるため、

      // Androidでは十分なMTUを確保してから1コマンドずつ送る。

      try {
        await device.requestMtu(247);
      } catch (_) {
        // 接続時に十分なMTUが既に確保されている場合などは続行する。
      }

      final services = await device.discoverServices();

      // デバッグ用：親機から見えているGATTサービスとCharacteristicを全表示

      for (final service in services) {
        debugPrint('=== SERVICE: ${service.uuid} ===');

        for (final characteristic in service.characteristics) {
          debugPrint(
            '  CHARACTERISTIC: ${characteristic.uuid} '
            'read=${characteristic.properties.read} '
            'write=${characteristic.properties.write} '
            'notify=${characteristic.properties.notify}',
          );
        }
      }

      final configChar = _findCharacteristic(services, _configUuid);

      final statusChar = _findCharacteristic(services, _statusUuid);

      if (!configChar.properties.write) {
        throw Exception('親機の設定Characteristicに書き込みできません。');
      }

      if (statusChar.properties.notify) {
        await statusChar.setNotifyValue(true);
      }

      if (!mounted) return;

      setState(() => _statusText = 'Wi-Fi情報を親機へ送信しています…');

      // 親機側はSSID→PASSの順で受け取るとWi-Fi接続を開始する。

      await configChar.write(utf8.encode('SSID:$ssid'), withoutResponse: false);

      await configChar.write(
        utf8.encode('PASS:$password'),
        withoutResponse: false,
      );

      if (!mounted) return;

      setState(() => _statusText = '親機のWi-Fi接続を確認しています…');

      Map<String, dynamic>? status;

      Object? lastStatusError;

      const wifiConnectionTimeout = Duration(seconds: 60);
      final wifiConnectionTimer = Stopwatch()..start();
      while (wifiConnectionTimer.elapsed < wifiConnectionTimeout) {
        final remaining = wifiConnectionTimeout - wifiConnectionTimer.elapsed;
        try {
          status = await _readStatus(statusChar).timeout(remaining);
          if (status['wifi_connected'] == true) break;
        } catch (error) {
          lastStatusError = error;
        }

        final pollDelay = wifiConnectionTimeout - wifiConnectionTimer.elapsed;
        if (pollDelay > Duration.zero) {
          await Future<void>.delayed(
            pollDelay < const Duration(seconds: 1)
                ? pollDelay
                : const Duration(seconds: 1),
          );
        }
      }

      if (status == null) {
        throw Exception('親機の状態を確認できませんでした。${lastStatusError ?? ''}');
      }

      if (status['wifi_connected'] != true) {
        throw Exception('60秒以内にWi-Fiに接続できませんでした。SSIDとパスワードを確認してください。');
      }

      final gatewayId = (status['station_id'] ?? '').toString().trim();

      if (gatewayId.isEmpty) {
        throw Exception('親機IDを取得できませんでした。');
      }

      if (!mounted) return;

      // 登録済み親機のWi-Fi再設定では、別の親機へ誤送信しないようIDを確認する。
      if (widget.gateway != null) {
        if (gatewayId.toUpperCase() != widget.gateway!.id.toUpperCase()) {
          throw Exception(
            '選択した親機と接続中の親機が違います。${widget.gateway!.name} を選択してください。',
          );
        }

        try {
          await device.disconnect();
        } catch (_) {}

        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      setState(() => _statusText = '親機をアカウントに登録しています…');

      // 親機自身のDB登録直後なので、サーバー反映のわずかな遅延に備えて再試行する。

      Object? registerError;

      bool registered = false;

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          await ApiService.registerGateway(gatewayId);

          registered = true;

          break;
        } catch (error) {
          registerError = error;

          if (attempt < 2) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (!registered) throw registerError ?? Exception('親機を登録できませんでした。');

      try {
        await device.disconnect();
      } catch (_) {}

      if (!mounted) return;

      try {
        final gateways = await ApiService.fetchUserGateways();

        Gateway? registeredGateway;

        for (final item in gateways) {
          if (item.id.toUpperCase() == gatewayId.toUpperCase()) {
            registeredGateway = item;

            break;
          }
        }

        if (registeredGateway != null && mounted) {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  GatewayLocationScreen(gateway: registeredGateway!),
            ),
          );
        }
      } catch (error) {
        debugPrint('設置場所画面の表示に失敗しました: $error');
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      try {
        if (device.isConnected) await device.disconnect();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _submitting = false;

        _statusText = '登録に失敗しました';

        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        title: const Text(
          '親機を登録',

          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        backgroundColor: _purple,

        foregroundColor: Colors.white,

        elevation: 0,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),

              child: Card(
                elevation: 0,

                color: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),

                  side: const BorderSide(color: Color(0xFFE9DEFF), width: 2),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(26),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      const Icon(
                        Icons.router_rounded,
                        size: 60,
                        color: _purple,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.gateway == null
                            ? '近くのココ・シール親機をBluetoothで探して、\nWi-Fi設定を送信します。'
                            : '${widget.gateway!.name} のWi-Fiを再設定します。\n近くの親機をBluetoothで探してください。',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed: (_scanning || _submitting) ? null : _scan,

                        icon: _scanning
                            ? const SizedBox(
                                width: 18,

                                height: 18,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.bluetooth_searching_rounded),

                        label: Text(_scanning ? '検索中…' : '近くの親機を探す'),

                        style: FilledButton.styleFrom(
                          backgroundColor: _purple,

                          foregroundColor: Colors.white,

                          minimumSize: const Size.fromHeight(52),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _statusText,

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: 18),

                        const Text(
                          '見つかった親機',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        ..._results.map((result) {
                          final selected =
                              _selectedDevice?.remoteId ==
                              result.device.remoteId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),

                            color: selected
                                ? const Color(0xFFF1E9FF)
                                : Colors.white,

                            child: RadioListTile<String>(
                              value: result.device.remoteId.str,

                              groupValue: _selectedDevice?.remoteId.str,

                              activeColor: _purple,

                              title: Text(
                                _deviceName(result),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Text('電波強度 ${result.rssi} dBm'),

                              onChanged: _submitting
                                  ? null
                                  : (_) => setState(() {
                                      _selectedDevice = result.device;

                                      _errorText = null;
                                    }),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 20),

                      TextField(
                        controller: _ssidController,

                        enabled: !_submitting,

                        decoration: InputDecoration(
                          labelText: 'Wi-Fi名（SSID）',

                          prefixIcon: const Icon(Icons.wifi_rounded),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _passwordController,

                        enabled: !_submitting,

                        obscureText: _obscurePassword,

                        decoration: InputDecoration(
                          labelText: 'Wi-Fiパスワード',

                          prefixIcon: const Icon(Icons.lock_outline_rounded),

                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),

                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      if (_errorText != null) ...[
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),

                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Text(
                            _errorText!,

                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 54,

                        child: FilledButton(
                          onPressed: _submitting ? null : _provisionAndRegister,

                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: _submitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    SizedBox(
                                      width: 20,

                                      height: 20,

                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),

                                    SizedBox(width: 12),

                                    Text(
                                      widget.gateway == null
                                          ? '設定・登録中…'
                                          : 'Wi-Fi設定中…',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.gateway == null
                                      ? 'Wi-Fiを設定して親機を登録'
                                      : 'Wi-Fiを設定',

                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGatewayView extends StatelessWidget {
  static const Color _purple = Color(0xFF7447C8);

  static const Color _darkPurple = Color(0xFF3E2465);

  final VoidCallback onRegister;

  const _EmptyGatewayView({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),

        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(Icons.router_rounded, size: 76, color: _purple),

              const SizedBox(height: 20),

              const Text(
                '親機が登録されていません',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: _darkPurple,

                  fontSize: 22,

                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '親機IDを入力して、このアカウントに親機を登録してください。',

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,

                height: 56,

                child: FilledButton.icon(
                  onPressed: onRegister,

                  icon: const Icon(Icons.add_rounded),

                  label: const Text(
                    '親機を登録',

                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
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


  const _StatusBody({
    required this.gateway,
    required this.seal,
    required this.onEdit,
  });

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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

  const _SosBody({
    required this.gateway,
    required this.seal,
    required this.childName,
    required this.onEdit,
    required this.onHoldStart,
    required this.onHoldCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),

      child: Column(
        children: [
          _GatewayInfo(gateway: gateway, seal: seal, compact: true),

          const SizedBox(height: 22),

          Text(
            '$childName から\nSOSアラートが届きました',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            height: 76,

            child: FilledButton(
              onPressed: onEdit,

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED6E73),
                foregroundColor: const Color(0xFF7B1518),
                shape: const RoundedRectangleBorder(),
              ),

              child: const Text(
                'シールを変更',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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

              child: const Text(
                '安全確認完了（アラート解除）\n長押し3秒',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '親機登録名',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                '配布するシール',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Container(width: 2, height: compact ? 110 : 155, color: dividerColor),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gateway.name,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 28),

              Text(seal?.name ?? '未設定'),

              const SizedBox(height: 8),

              if (seal != null)
                SealImage(seal: seal!, size: compact ? 58 : 140),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;

  final VoidCallback onRetry;

  final VoidCallback onRegister;

  const _ErrorView({
    required this.error,

    required this.onRetry,

    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('親機情報を取得できませんでした\n$error', textAlign: TextAlign.center),

            const SizedBox(height: 12),

            FilledButton(onPressed: onRegister, child: const Text('親機を登録')),

            const SizedBox(height: 10),

            OutlinedButton(onPressed: onRetry, child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}

class _AdminData {
  final List<Gateway> gateways;

  final List<Seal> seals;

  const _AdminData({required this.gateways, required this.seals});
}
