import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/seal.dart';

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

  void _reload() {
    setState(() {
      _collectionFuture = ApiService.fetchSealCollection(widget.deviceId);
    });
  }

  String _rarityLabel(int rarity) {
    if (rarity >= 3) return 'Super Rare';
    if (rarity == 2) return 'Rare';
    return 'Normal';
  }

  Uri? _imageUri(String path) {
    if (path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    if (uri.hasScheme) return uri;
    return Uri.parse(ApiService.baseUrl).resolve(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シールずかん・こうかんせってい'),
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<SealCollection>(
        future: _collectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('シール情報を取得できませんでした\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _reload, child: const Text('再試行')),
                ],
              ),
            );
          }
          final collection = snapshot.data!;
          final ownedIds = collection.owned.map((item) => item.sealId).toSet();
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF5F5F5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('あつめたシール',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${ownedIds.length} / ${collection.catalog.length} 種',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: collection.catalog.length,
                  itemBuilder: (context, index) {
                    final seal = collection.catalog[index];
                    final discovered = ownedIds.contains(seal.id);
                    final imageUri = _imageUri(seal.imagePath);
                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 54,
                          height: 54,
                          child: discovered && imageUri != null
                              ? Image.network(
                                  imageUri.toString(),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.stars),
                                )
                              : Icon(discovered ? Icons.stars : Icons.help_outline),
                        ),
                        title: Text(discovered ? seal.name : '？？？？？'),
                        subtitle: Text(
                          discovered ? seal.description : _rarityLabel(seal.rarity),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: discovered
                            ? const Chip(label: Text('もっています'))
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
