import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/nearby_communication.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';

class PassbyCheckScreen extends StatefulWidget {
  final String deviceId;
  const PassbyCheckScreen({super.key, required this.deviceId});

  @override
  State<PassbyCheckScreen> createState() => _PassbyCheckScreenState();
}

class _PassbyData {
  final List<NearbyCommunication> logs;
  final Map<String, Seal> seals;
  const _PassbyData({required this.logs, required this.seals});
}

class _PassbyCheckScreenState extends State<PassbyCheckScreen> {
  static const _purple = Color(0xFF7447C8);
  late Future<_PassbyData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  void _reload() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<_PassbyData> _loadData() async {
    final endAt = DateTime.now();
    final results = await Future.wait<dynamic>([
      ApiService.fetchNearbyCommunications(
        deviceId: widget.deviceId,
        startAt: endAt.subtract(const Duration(days: 30)),
        endAt: endAt,
      ),
      ApiService.fetchSeals(),
    ]);
    final logs = results[0] as List<NearbyCommunication>;
    final catalog = results[1] as List<Seal>;
    logs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return _PassbyData(logs: logs, seals: {for (final seal in catalog) seal.id: seal});
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _placeFor(NearbyCommunication log) {
    if (log.partnerIsGateway) return log.partnerId;
    const places = <String, String>{
      'ゆうき': 'さくら公園',
      'みお': '豊田高専 正門前',
      'そうた': '駅前ひろば',
      'はると': '中央図書館',
    };
    return places[log.partnerId] ?? 'みどり児童館';
  }

  void _showDetail(NearbyCommunication log, Seal? seal) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ),
              if (seal != null) SealImage(seal: seal, size: 130),
              const SizedBox(height: 12),
              _DetailRow(
                label: log.partnerIsGateway ? 'とおった親機' : 'くれたともだち',
                value: log.partnerId,
              ),
              _DetailRow(label: 'シールのなまえ', value: seal?.name ?? 'シールなし'),
              _DetailRow(label: 'すれちがったじかん', value: _formatDate(log.timeStamp)),
              _DetailRow(
                label: 'すれちがったばしょ',
                value: _placeFor(log),
              ),
              const _DetailRow(label: 'かくとくコイン', value: '1コイン'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('すれちがいかくにん'),
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<_PassbyData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('履歴を取得できませんでした\n${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _reload, child: const Text('再試行')),
              ]),
            );
          }
          final data = snapshot.data!;
          if (data.logs.isEmpty) {
            return const Center(child: Text('過去30日間のすれちがい履歴はありません'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(22),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              mainAxisExtent: 190,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: data.logs.length,
            itemBuilder: (context, index) {
              final log = data.logs[index];
              final seal = data.seals[log.receiveSealId];
              return InkWell(
                onTap: () => _showDetail(log, seal),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8C5FF)),
                    boxShadow: const [BoxShadow(color: Color(0x14654391), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (seal != null)
                      SealImage(seal: seal, size: 105)
                    else
                      const Icon(Icons.card_giftcard_rounded, size: 90, color: Color(0xFFD8C5FF)),
                    const SizedBox(height: 8),
                    Text(
                      seal?.name ?? 'シールなし',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _purple),
                    ),
                    Text(
                      log.partnerId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 125, child: Text(label, style: const TextStyle(fontSize: 12))),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
