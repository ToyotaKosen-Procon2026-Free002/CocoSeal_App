class Gateway {
  final String id;
  final String name;
  final String? distributeSealId;
  final String? userId;
  final double? latitude;
  final double? longitude;

  const Gateway({
    required this.id,
    required this.name,
    this.distributeSealId,
    this.userId,
    this.latitude,
    this.longitude,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) {
    return Gateway(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '名称未設定',
      distributeSealId: json['distribute_seal_id']?.toString(),
      userId: json['user_id']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}