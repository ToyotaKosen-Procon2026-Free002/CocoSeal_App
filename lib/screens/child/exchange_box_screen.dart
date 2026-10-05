import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';

class ExchangeBoxScreen extends StatefulWidget {
  final String deviceId;

  const ExchangeBoxScreen({super.key, required this.deviceId});

  @override
  State<ExchangeBoxScreen> createState() => _ExchangeBoxScreenState();
}

class _ExchangeBoxScreenState extends State<ExchangeBoxScreen> {
  static const Color _purple = Color(0xFF7447C8);
  static const int _capacity = 20;
  static final Map<String, List<String>> _demoSelections = {};

  late Future<SealCollection> _collectionFuture;
  final List<String> _selectedDeviceSealIds = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _collectionFuture = ApiService.fetchSealCollection(widget.deviceId);
  }

  void _initializeSelection(SealCollection collection) {
    if (_initialized) return;
    _initialized = true;
    final remembered = _demoSelections[widget.deviceId];
    if (remembered != null) {
      final validIds = collection.owned.map((item) => item.id).toSet();
      _selectedDeviceSealIds.addAll(remembered.where(validIds.contains));
    } else {
      _selectedDeviceSealIds.addAll(
        collection.owned.where((item) => item.statusId == 1).map((item) => item.id),
      );
    }
  }

  void _remember() {
    _demoSelections[widget.deviceId] = List<String>.from(_selectedDeviceSealIds);
  }

  void _addSeal(String sealId, SealCollection collection) {
    if (_selectedDeviceSealIds.length >= _capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('こうかんボックスは20枚までだよ')),
      );
      return;
    }
    for (final item in collection.owned) {
      if (item.sealId == sealId && !_selectedDeviceSealIds.contains(item.id)) {
        setState(() => _selectedDeviceSealIds.add(item.id));
        _remember();
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このシールは全部ボックスに入っているよ')),
    );
  }

  void _removeSeal(String deviceSealId) {
    setState(() => _selectedDeviceSealIds.remove(deviceSealId));
    _remember();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('こうかんボックス', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<SealCollection>(
        future: _collectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }
          if (snapshot.hasError) {
            return Center(child: Text('シールを取得できませんでした\n${snapshot.error}', textAlign: TextAlign.center));
          }

          final collection = snapshot.data!;
          _initializeSelection(collection);
          final catalogById = {for (final seal in collection.catalog) seal.id: seal};
          final ownedById = {for (final item in collection.owned) item.id: item};
          final selected = _selectedDeviceSealIds
              .map((id) => ownedById[id])
              .whereType<DeviceSeal>()
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
                children: [
                  const Text('したのシールを ここへドラッグしよう！', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _purple)),
                  const SizedBox(height: 14),
                  DragTarget<String>(
                    onWillAcceptWithDetails: (_) => _selectedDeviceSealIds.length < _capacity,
                    onAcceptWithDetails: (details) => _addSeal(details.data, collection),
                    builder: (context, candidateData, rejectedData) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: candidateData.isEmpty ? const Color(0xFFF1EAFF) : const Color(0xFFE3D5FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _purple, width: candidateData.isEmpty ? 2 : 4),
                        boxShadow: candidateData.isEmpty
                            ? const []
                            : [BoxShadow(color: _purple.withValues(alpha: 0.25), blurRadius: 18)],
                      ),
                      child: Column(
                        children: [
                          const Text('こうかんにだすシール', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _purple)),
                          Text('${selected.length} / $_capacityまい', style: const TextStyle(fontWeight: FontWeight.bold, color: _purple)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 170,
                            child: GridView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _capacity,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 82,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemBuilder: (context, index) {
                                if (index >= selected.length) return const _EmptySlot();
                                final item = selected[index];
                                final seal = catalogById[item.sealId];
                                if (seal == null) return const _EmptySlot();
                                return _SelectedSealTile(
                                  seal: seal,
                                  onRemove: () => _removeSeal(item.id),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz_rounded, color: _purple),
                              SizedBox(width: 7),
                              Flexible(child: Text('ここに入れたシールを すれちがいでこうかんするよ', textAlign: TextAlign.center, style: TextStyle(color: _purple, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OwnedSealPanel(
                    collection: collection,
                    selectedIds: _selectedDeviceSealIds,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFE9DEFF), borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: _purple),
                        SizedBox(width: 8),
                        Flexible(child: Text('なが押しして、そのまま上へうごかしてね', style: TextStyle(color: _purple, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
            ),
          );
        },
      ),
    );
  }
}

class _OwnedSealPanel extends StatelessWidget {
  static const Color _purple = Color(0xFF7447C8);
  final SealCollection collection;
  final List<String> selectedIds;

  const _OwnedSealPanel({required this.collection, required this.selectedIds});

  @override
  Widget build(BuildContext context) {
    final catalogById = {for (final seal in collection.catalog) seal.id: seal};
    final remainingCount = <String, int>{};
    for (final item in collection.owned) {
      if (!selectedIds.contains(item.id)) {
        remainingCount[item.sealId] = (remainingCount[item.sealId] ?? 0) + 1;
      }
    }
    final sealIds = remainingCount.keys.where(catalogById.containsKey).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: _purple),
              const SizedBox(width: 8),
              const Expanded(child: Text('もっているシール', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _purple))),
              Text('${remainingCount.values.fold<int>(0, (sum, value) => sum + value)}まい', style: const TextStyle(color: _purple, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (sealIds.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('のこっているシールはないよ')))
          else
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sealIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final sealId = sealIds[index];
                  final seal = catalogById[sealId]!;
                  return LongPressDraggable<String>(
                    data: sealId,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.12,
                        child: _OwnedSealTile(seal: seal, count: remainingCount[sealId]!),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _OwnedSealTile(seal: seal, count: remainingCount[sealId]!),
                    ),
                    child: _OwnedSealTile(seal: seal, count: remainingCount[sealId]!),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnedSealTile extends StatelessWidget {
  final Seal seal;
  final int count;

  const _OwnedSealTile({required this.seal, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 122,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8C5FF)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Expanded(child: SealImage(seal: seal, size: 76)),
          Text(seal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text('×$count', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7447C8))),
        ],
      ),
    );
  }
}

class _SelectedSealTile extends StatelessWidget {
  final Seal seal;
  final VoidCallback onRemove;

  const _SelectedSealTile({required this.seal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: SealImage(seal: seal, size: 72),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Color(0xFF7447C8),
              child: Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDB9F4)),
      ),
      child: const Icon(Icons.add_rounded, color: Color(0xFFC1ACEA)),
    );
  }
}
