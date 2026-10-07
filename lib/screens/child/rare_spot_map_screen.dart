import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../api_service.dart';
import '../../models/gateway.dart';
import '../../models/seal.dart';

class RareSpotScreen extends StatefulWidget {
  const RareSpotScreen({super.key});

  @override
  State<RareSpotScreen> createState() => _RareSpotScreenState();
}

class _RareSpotScreenState extends State<RareSpotScreen> {
  static const Color _purple = Color(0xFF7447C8);
  static const LatLng _defaultCenter = LatLng(35.0824, 137.1563);

  bool _loading = true;
  String? _error;

  List<Gateway> _gateways = const [];
  Map<String, Seal> _seals = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.fetchAllGateways(),
        ApiService.fetchSeals(),
      ]);

      final gateways = results[0] as List<Gateway>;
      final seals = results[1] as List<Seal>;

      if (!mounted) return;

      setState(() {
        _gateways = gateways
            .where(
              (g) =>
                  g.latitude != null &&
                  g.longitude != null &&
                  g.latitude != 0 &&
                  g.longitude != 0,
            )
            .toList();

        _seals = {
          for (final seal in seals) seal.id: seal,
        };

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Marker> get _markers {
    return _gateways.map((gateway) {
      final seal = _seals[gateway.distributeSealId];

      final gatewayName = gateway.name.trim().isEmpty
          ? 'レアシールスポット'
          : gateway.name;

      final sealName =
          seal == null ? '未設定' : seal.name;

      return Marker(
        point: LatLng(
          gateway.latitude!,
          gateway.longitude!,
        ),
        width: 70,
        height: 70,
        child: Tooltip(
          message: '$gatewayName\n配布シール：$sealName',
          child: GestureDetector(
            onTap: () {
              _showSpotInfo(
                gatewayName: gatewayName,
                sealName: sealName,
              );
            },
            child: const Icon(
              Icons.location_on_rounded,
              color: _purple,
              size: 52,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showSpotInfo({
    required String gatewayName,
    required String sealName,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _purple,
                  size: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  gatewayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '配布シール：$sealName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レアシールスポット'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '最新の親機情報を取得',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _purple,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '親機情報を取得できませんでした。\n$_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                          ),
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: _gateways.isEmpty
                            ? _defaultCenter
                            : LatLng(
                                _gateways.first.latitude!,
                                _gateways.first.longitude!,
                              ),
                        initialZoom:
                            _gateways.isEmpty ? 12 : 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.coco',
                        ),

                        MarkerLayer(
                          markers: _markers,
                        ),

                        RichAttributionWidget(
                          attributions: const [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (_gateways.isEmpty)
                      const Positioned(
                        left: 16,
                        right: 16,
                        top: 16,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text(
                              '設置場所が登録されている親機はまだありません。',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}