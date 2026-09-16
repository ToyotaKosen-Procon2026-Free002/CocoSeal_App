class User {
  final String id;
  final String displayName;
  final String email;
  final String firebaseUid;
  final List<String> notifyTokens;
  final int roll; // 0: 保護者, 1: 親機 などの識別用

  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.firebaseUid,
    required this.notifyTokens,
    required this.roll,
  });

  // JSON (Map) から User オブジェクトを作成する
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      firebaseUid: json['firebase_uid'] ?? '',
      notifyTokens: List<String>.from(json['notify_tokens'] ?? []),
      roll: json['roll'] ?? 0,
    );
  }

  // User オブジェクトを JSON (Map) に変換する
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'firebase_uid': firebaseUid,
      'notify_tokens': notifyTokens,
      'roll': roll,
    };
  }
}