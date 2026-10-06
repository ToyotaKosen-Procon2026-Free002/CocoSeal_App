import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
            .where((g) =>
                g.latitude != null &&
                g.longitude != null &&
                g.latitude != 0 &&
                g.longitude != 0)
            .toList();
        _seals = {for (final seal in seals) seal.id: seal};
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

  Set<Marker> get _markers {
    return _gateways.map((gateway) {
      final seal = _seals[gateway.distributeSealId];
      return Marker(
        markerId: MarkerId(gateway.id),
        position: LatLng(gateway.latitude!, gateway.longitude!),
        infoWindow: InfoWindow(
          title: gateway.name.trim().isEmpty ? 'レアシールスポット' : gateway.name,
          snippet: seal == null ? '配布シール：未設定' : '配布シール：${seal.name}',
        ),
      );
    }).toSet();
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
              child: CircularProgressIndicator(color: _purple),
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
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _gateways.isEmpty
                            ? _defaultCenter
                            : LatLng(
                                _gateways.first.latitude!,
                                _gateways.first.longitude!,
                              ),
                        zoom: _gateways.isEmpty ? 12 : 14,
                      ),
                      markers: _markers,
                      zoomControlsEnabled: true,
                    ),
                    if (_gateways.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
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
