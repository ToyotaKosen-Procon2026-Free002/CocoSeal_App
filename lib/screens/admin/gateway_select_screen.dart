import 'package:flutter/material.dart';

import '../../models/gateway.dart';

class GatewaySelectScreen extends StatelessWidget {
  final List<Gateway> gateways;
  final String? selectedGatewayId;

  const GatewaySelectScreen({
    super.key,
    required this.gateways,
    this.selectedGatewayId,
  });

  static const Color _purple = Color(0xFF7447C8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('親機を切り替える'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: gateways.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final gateway = gateways[index];
          final selected = gateway.id == selectedGatewayId ||
              (selectedGatewayId == null && index == 0);

          return Card(
            child: ListTile(
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _purple,
              ),
              title: Text(
                gateway.name.trim().isEmpty ? '名称未設定の親機' : gateway.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'ID: ${gateway.id}\n'
                '${gateway.latitude == 0 && gateway.longitude == 0 ? "設置場所：未登録" : "設置場所：登録済み"}',
              ),
              isThreeLine: true,
              onTap: () => Navigator.pop(context, gateway),
            ),
          );
        },
      ),
    );
  }
}
