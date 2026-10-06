import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';

class SealDictionaryScreen extends StatefulWidget {
  final String deviceId;

  const SealDictionaryScreen({super.key, required this.deviceId});

  @override
  State<SealDictionaryScreen> createState() => _SealDictionaryScreenState();
}

class _SealDictionaryScreenState extends State<SealDictionaryScreen> {
  late Future<SealCollection> _collectionFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() {
        _collectionFuture = ApiService.fetchSealCollection(widget.deviceId);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('シールずかん', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2EAFF), Color(0xFFFFF8FC), Color(0xFFE9DEFF)],
          ),
        ),
        child: FutureBuilder<SealCollection>(
          future: _collectionFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error, onRetry: _reload);
          }

          final collection = snapshot.data!;
          // Oシールは親機が配布するオリジナルシールのため、
          // 通常シールの図鑑・達成率・番号送りには含めない。
          final catalog = collection.catalog.where((seal) => seal.rarity != 2).toList()
            ..sort((a, b) => (a.bookNumber ?? 9999).compareTo(b.bookNumber ?? 9999));
          final catalogIds = catalog.map((seal) => seal.id).toSet();
          final ownedIds = collection.owned
              .map((item) => item.sealId)
              .where(catalogIds.contains)
              .toSet();
          final percent = catalog.isEmpty ? 0 : (ownedIds.length * 100 / catalog.length).floor();

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 3 : 2;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProgressHeader(owned: ownedIds.length, total: catalog.length, percent: percent),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 3 ? 0.88 : 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: catalog.length,
                        (context, index) {
                          final seal = catalog[index];
                          return _SealCard(
                            seal: seal,
                            number: seal.bookNumber ?? index + 1,
                            discovered: ownedIds.contains(seal.id),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (_) => _SealDetailDialog(
                                catalog: catalog,
                                owned: collection.owned,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          },
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int owned;
  final int total;
  final int percent;

  const _ProgressHeader({required this.owned, required this.total, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8C5FF)),
      ),
      child: Row(
        children: [
          const Expanded(child: Text('あつめたシール', style: TextStyle(fontWeight: FontWeight.bold))),
          Text('$owned / $total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7447C8))),
          const SizedBox(width: 12),
          Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SealCard extends StatelessWidget {
  final Seal seal;
  final int number;
  final bool discovered;
  final VoidCallback onTap;

  const _SealCard({required this.seal, required this.number, required this.discovered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = SealImage(seal: seal, size: 110);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text('No.${number.toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Center(
                  child: discovered
                      ? image
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(Color(0xFFB9B9B9), BlendMode.srcIn),
                          child: Opacity(opacity: 0.75, child: image),
                        ),
                ),
              ),
              Text(discovered ? seal.name : '？？？', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(_stars(seal.rarity), style: const TextStyle(color: Color(0xFFFFB000), fontSize: 18, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SealDetailDialog extends StatefulWidget {
  final List<Seal> catalog;
  final List<DeviceSeal> owned;
  final int initialIndex;

  const _SealDetailDialog({required this.catalog, required this.owned, required this.initialIndex});

  @override
  State<_SealDetailDialog> createState() => _SealDetailDialogState();
}

class _SealDetailDialogState extends State<_SealDetailDialog> {
  late int _index = widget.initialIndex;

  void _move(int amount) => setState(() {
        _index = (_index + amount + widget.catalog.length) % widget.catalog.length;
      });

  @override
  Widget build(BuildContext context) {
    final seal = widget.catalog[_index];
    final copies = widget.owned.where((item) => item.sealId == seal.id).toList()
      ..sort((a, b) => (b.acquiredAt ?? DateTime(0)).compareTo(a.acquiredAt ?? DateTime(0)));
    final discovered = copies.isNotEmpty;
    final latest = discovered ? copies.first : null;
    final number = seal.bookNumber ?? _index + 1;
    final image = SealImage(seal: seal, size: 180);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('No.${number.toString().padLeft(3, '0')}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                    Expanded(
                      child: discovered
                          ? image
                          : ColorFiltered(
                              colorFilter: const ColorFilter.mode(Color(0xFFB9B9B9), BlendMode.srcIn),
                              child: image,
                            ),
                    ),
                    IconButton(onPressed: () => _move(1), icon: const Icon(Icons.arrow_forward_ios_rounded)),
                  ],
                ),
              ),
              Text(discovered ? seal.name : '？？？', textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(_stars(seal.rarity), style: const TextStyle(color: Color(0xFFFFB000), fontSize: 22)),
              const SizedBox(height: 10),
              Text(discovered ? seal.description : 'まだ見つけていないシールだよ', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF4EFFF), borderRadius: BorderRadius.circular(14)),
                child: discovered
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('もっている枚数：${copies.length}枚', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 7),
                          Text('さいしんの場所：${latest?.acquiredPlace ?? '情報なし'}'),
                          const SizedBox(height: 4),
                          Text('さいしんの時刻：${_formatDateTime(latest?.acquiredAt)}'),
                        ],
                      )
                    : const Text('手に入れると、場所と時刻が表示されるよ', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('シール情報を取得できませんでした\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}

String _stars(int rarity) => rarity == 1 ? '★★' : rarity == 2 ? '★★★' : '★';

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '情報なし';
  final local = dateTime.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
