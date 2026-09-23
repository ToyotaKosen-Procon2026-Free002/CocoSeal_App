import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/nearby_communication.dart';

class PassbyCheckScreen extends StatefulWidget {
  final String deviceId;

  const PassbyCheckScreen({super.key, required this.deviceId});

  @override
  State<PassbyCheckScreen> createState() => _PassbyCheckScreenState();
}

class _PassbyCheckScreenState extends State<PassbyCheckScreen> {
  late Future<List<NearbyCommunication>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final endAt = DateTime.now();
    setState(() {
      _logsFuture = ApiService.fetchNearbyCommunications(
        deviceId: widget.deviceId,
        startAt: endAt.subtract(const Duration(days: 30)),
        endAt: endAt,
      );
    });
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  void _showDetailDialog(NearbyCommunication log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            _popupRow(
              log.partnerIsGateway ? '通過した親機' : 'すれちがった相手',
              log.partnerId,
            ),
            _popupRow('すれちがった時間', _formatDate(log.timeStamp)),
            _popupRow('もらったシール', log.receiveSealId ?? 'なし'),
            _popupRow('渡したシール', log.sendSealId ?? 'なし'),
          ],
        ),
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Container(width: 1, height: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれちがいりれき'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<NearbyCommunication>>(
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
                  Text('履歴を取得できませんでした\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _reload, child: const Text('再試行')),
                ],
              ),
            );
          }
          final logs = snapshot.data ?? const <NearbyCommunication>[];
          logs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
          if (logs.isEmpty) {
            return const Center(child: Text('過去30日間のすれちがい履歴はありません'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                child: ListTile(
                  onTap: () => _showDetailDialog(log),
                  leading: Icon(
                    log.partnerIsGateway ? Icons.location_on : Icons.people,
                    color: Colors.pinkAccent,
                  ),
                  title: Text(log.partnerId),
                  subtitle: Text(_formatDate(log.timeStamp)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
