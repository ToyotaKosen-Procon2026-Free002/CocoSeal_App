import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api_service.dart';
import '../../models/gateway.dart';

class RareSpotMapScreen extends StatefulWidget {
  const RareSpotMapScreen({super.key});

  @override
  State<RareSpotMapScreen> createState() => _RareSpotMapScreenState();
}

class _RareSpotMapScreenState extends State<RareSpotMapScreen> {
  late Future<List<Gateway>> _gatewaysFuture;

  static const LatLng _defaultPosition = LatLng(
    35.681236,
    139.767125,
  );

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  void _loadGateways() {
    setState(() {
      _gatewaysFuture = ApiService.fetchAllGateways();
    });
  }

  Set<Marker> _createMarkers(List<Gateway> gateways) {
    return gateways
        .where(
          (gateway) =>
              gateway.latitude != null &&
              gateway.longitude != null,
        )
        .map(
          (gateway) => Marker(
            markerId: MarkerId(gateway.id),
            position: LatLng(
              gateway.latitude!,
              gateway.longitude!,
            ),
            infoWindow: InfoWindow(
              title: gateway.name,
              snippet: gateway.distributeSealId == null
                  ? '配布シール情報なし'
                  : '配布シール：${gateway.distributeSealId}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        )
        .toSet();
  }

  LatLng _initialPosition(List<Gateway> gateways) {
    for (final gateway in gateways) {
      if (gateway.latitude != null &&
          gateway.longitude != null) {
        return LatLng(
          gateway.latitude!,
          gateway.longitude!,
        );
      }
    }

    return _defaultPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レアシールスポット'),
        actions: [
          IconButton(
            onPressed: _loadGateways,
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
          ),
        ],
      ),
      body: FutureBuilder<List<Gateway>>(
        future: _gatewaysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'スポットを取得できませんでした',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGateways,
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            );
          }

          final gateways =
              snapshot.data ?? const <Gateway>[];

          final markers = _createMarkers(gateways);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition(gateways),
                  zoom: 13,
                ),
                markers: markers,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
              ),

              if (markers.isEmpty)
                Positioned(
                  top: 16,
                  left: 24,
                  right: 24,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        gateways.isEmpty
                            ? '登録されているスポットはありません'
                            : '緯度・経度が設定されたスポットはありません',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}