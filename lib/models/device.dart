class Device {
  final String id;
  final String? owner;
  final String name;
  final int coins;
  final double battery;
  final String lastTimestamp;

  Device({
    required this.id,
    this.owner,
    required this.name,
    required this.coins,
    required this.battery,
    required this.lastTimestamp,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      owner: json['owner'] as String?,
      name: json['name'] as String? ?? 'ななし',
      coins: json['coins'] as int? ?? 0,
      battery: (json['battery'] as num?)?.toDouble() ?? 0.0,
      lastTimestamp: json['last_timestamp'] as String? ?? '',
    );
  }

  Device copyWith({
    String? name,
    int? coins,
    double? battery,
  }) {
    return Device(
      id: id,
      owner: owner,
      name: name ?? this.name,
      coins: coins ?? this.coins,
      battery: battery ?? this.battery,
      lastTimestamp: lastTimestamp,
    );
  }
}
