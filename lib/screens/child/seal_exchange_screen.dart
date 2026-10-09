import 'dart:async';

import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/seal.dart';
import '../../widgets/seal_image.dart';

class SealExchangeScreen extends StatefulWidget {
  final String deviceId;
  final int initialCoins;
  final ValueChanged<int>? onCoinsChanged;

  const SealExchangeScreen({
    super.key,
    required this.deviceId,
    required this.initialCoins,
    this.onCoinsChanged,
  });

  @override
  State<SealExchangeScreen> createState() => _SealExchangeScreenState();
}

class _SealExchangeScreenState extends State<SealExchangeScreen> {
  static const _purple = Color(0xFF7447C8);

  late int userCoins;
  late Future<List<SealPack>> _packsFuture;
  String? _openingPackId;

  @override
  void initState() {
    super.initState();
    userCoins = widget.initialCoins;
    _packsFuture = ApiService.fetchSealPacks();
  }

  int _sealCount(SealPack pack) {
    final text = '${pack.name} ${pack.description}'.toLowerCase();
    return text.contains('スペシャル') || text.contains('special') ? 5 : 3;
  }

  Future<void> _refreshCoins() async {
    final devices = await ApiService.fetchUserDevices();

    for (final device in devices) {
      if (device.id.toLowerCase() == widget.deviceId.toLowerCase()) {
        if (!mounted) return;

        setState(() => userCoins = device.coins);
        widget.onCoinsChanged?.call(device.coins);
        return;
      }
    }
  }

  Future<void> _openPack(SealPack pack) async {
    final count = _sealCount(pack);

    // 1枚あたりの価格 × パックに入っている枚数
    final totalPrice = pack.oncePrice * count;

    if (userCoins < totalPrice) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('コインがたりないよ！'),
          content: Text(
            '必要：$totalPriceコイン　いま：$userCoinsコイン',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('もどる'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${pack.name}とこうかんしますか？'),
        content: Text(
          '$totalPriceコインで$countまいのシールをひきます',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('もどる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _openingPackId = pack.id);

    try {
      final seals = await ApiService.playSealPack(
        packId: pack.id,
        count: count,
        deviceId: widget.deviceId,
      );

      await _refreshCoins();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SealRevealDialog(
          results: seals,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingPackId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('シールパックこうかん'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Chip(
            avatar: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFB300),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: Color(0xFFD8C5FF),
            ),
            label: Text(
              '$userCoins コイン',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _purple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SealPack>>(
              future: _packsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'シールパックを取得できませんでした\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final packs =
                    snapshot.data ?? const <SealPack>[];

                if (packs.isEmpty) {
                  return const Center(
                    child: Text(
                      '開催中のシールパックはありません',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  itemCount: packs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _packCard(packs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _packCard(SealPack pack) {
    final count = _sealCount(pack);
    final totalPrice = pack.oncePrice * count;
    final busy = _openingPackId != null;

    return Card(
      color: Colors.white,
      surfaceTintColor: const Color(0xFFE8DEFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFD8C5FF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              pack.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pack.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 合計価格を表示
            Text(
              '$countまい入り・$totalPriceコイン',
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    busy ? null : () => _openPack(pack),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _openingPackId == pack.id
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'このパックとこうかんする',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealRevealDialog extends StatefulWidget {
  final List<Seal> results;

  const _SealRevealDialog({
    required this.results,
  });

  @override
  State<_SealRevealDialog> createState() =>
      _SealRevealDialogState();
}

class _SealRevealDialogState
    extends State<_SealRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  Timer? _timer;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);

    if (widget.results.isNotEmpty) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 330),
        (timer) {
          if (!mounted) return;

          if (_visibleCount >= widget.results.length) {
            timer.cancel();
            _glowController.stop();
            return;
          }

          setState(() => _visibleCount++);
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFBF9FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Column(
        children: [
          ScaleTransition(
            scale: _glowController,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 44,
              color: Color(0xFF7447C8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _visibleCount == widget.results.length
                ? 'ゲットしたシール！'
                : 'パックをオープン！',
          ),
        ],
      ),
      content: widget.results.isEmpty
          ? const Text(
              'シールを取得できませんでした',
            )
          : SizedBox(
              width: 420,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0;
                      index < _visibleCount;
                      index++)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('reveal-$index'),
                      tween: Tween(
                        begin: 0,
                        end: 1,
                      ),
                      duration:
                          const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (
                        context,
                        value,
                        child,
                      ) =>
                          Opacity(
                        opacity: value
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        child: Transform.scale(
                          scale: value,
                          child: child,
                        ),
                      ),
                      child: _RevealedSeal(
                        seal: widget.results[index],
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed:
              _visibleCount == widget.results.length
                  ? () => Navigator.pop(context)
                  : null,
          child: const Text('とじる'),
        ),
      ],
    );
  }
}

class _RevealedSeal extends StatelessWidget {
  final Seal seal;

  const _RevealedSeal({
    required this.seal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seal.rarity == 1
              ? const Color(0xFFFFC857)
              : const Color(0xFFD8C5FF),
          width: seal.rarity == 1 ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SealImage(
            seal: seal,
            size: 68,
          ),
          Text(
            seal.rarity == 1 ? '★★' : '★',
            style: const TextStyle(
              color: Color(0xFFFFB000),
            ),
          ),
          Text(
            seal.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}