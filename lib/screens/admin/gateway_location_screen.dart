import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api_service.dart';
import '../../models/gateway.dart';

class GatewayLocationScreen extends StatefulWidget {
  final Gateway gateway;

  const GatewayLocationScreen({super.key, required this.gateway});

  @override
  State<GatewayLocationScreen> createState() => _GatewayLocationScreenState();
}

class _GatewayLocationScreenState extends State<GatewayLocationScreen> {
  static const Color _purple = Color(0xFF7447C8);
  static const LatLng _defaultCenter = LatLng(35.0824, 137.1563);

  late final TextEditingController _nameController;
  LatLng? _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gateway.name);
    final lat = widget.gateway.latitude;
    final lng = widget.gateway.longitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      _selected = LatLng(lat, lng);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final point = _selected;
    final name = _nameController.text.trim();

    if (point == null) {
      setState(() => _error = '地図をタップして設置場所を選んでください。');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = '親機の場所名を入力してください。');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.updateGateway(
        gatewayId: widget.gateway.id,
        name: name,
        distributeSealId: widget.gateway.distributeSealId ?? '',
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _selected ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('親機の設置場所'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '場所名・親機名',
                hintText: '例：豊田高専',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('地図をタップして、親機を設置する場所を選んでください。'),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: _selected == null ? 13 : 16,
              ),
              onTap: (point) => setState(() {
                _selected = point;
                _error = null;
              }),
              markers: {
                if (_selected != null)
                  Marker(
                    markerId: const MarkerId('gateway_location'),
                    position: _selected!,
                    infoWindow: InfoWindow(
                      title: _nameController.text.trim().isEmpty
                          ? '親機'
                          : _nameController.text.trim(),
                    ),
                  ),
              },
              zoomControlsEnabled: true,
            ),
          ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                '緯度 ${_selected!.latitude.toStringAsFixed(6)} / '
                '経度 ${_selected!.longitude.toStringAsFixed(6)}',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: _purple),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.location_on_rounded),
                label: Text(_saving ? '保存中…' : 'この場所に登録'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
