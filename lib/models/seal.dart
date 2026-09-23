class Seal {
  final String id;
  final String name;
  final String description;
  final int rarity;
  final String imagePath;

  const Seal({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.imagePath,
  });

  factory Seal.fromJson(Map<String, dynamic> json) {
    return Seal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rarity: (json['rarity'] as num?)?.toInt() ?? 0,
      imagePath: json['image_path']?.toString() ?? '',
    );
  }
}

class DeviceSeal {
  final String id;
  final String deviceId;
  final String sealId;
  final int statusId;
  final int? bookPage;
  final double? bookX;
  final double? bookY;
  final double? bookRotation;
  final double? bookScale;

  const DeviceSeal({
    required this.id,
    required this.deviceId,
    required this.sealId,
    required this.statusId,
    this.bookPage,
    this.bookX,
    this.bookY,
    this.bookRotation,
    this.bookScale,
  });

  factory DeviceSeal.fromJson(Map<String, dynamic> json) {
    return DeviceSeal(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      sealId: json['seal_id']?.toString() ?? '',
      statusId: (json['status_id'] as num?)?.toInt() ?? 0,
      bookPage: (json['book_page'] as num?)?.toInt(),
      bookX: (json['book_x'] as num?)?.toDouble(),
      bookY: (json['book_y'] as num?)?.toDouble(),
      bookRotation: (json['book_rotation'] as num?)?.toDouble(),
      bookScale: (json['book_scale'] as num?)?.toDouble(),
    );
  }
}

class SealCollection {
  final List<Seal> catalog;
  final List<DeviceSeal> owned;

  const SealCollection({required this.catalog, required this.owned});
}
