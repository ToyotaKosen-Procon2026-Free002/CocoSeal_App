import '../../api_service.dart';

class WeeklyMission {
  final String missionId;
  final String title;
  final String description;
  final String targetType;
  final int targetValue;
  final int currentValue;
  final int rewardCoins;
  final bool isCompleted;
  final bool isClaimed;

  const WeeklyMission({
    required this.missionId,
    required this.title,
    required this.description,
    required this.targetType,
    required this.targetValue,
    required this.currentValue,
    required this.rewardCoins,
    required this.isCompleted,
    required this.isClaimed,
  });

  factory WeeklyMission.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(dynamic value) {
      if (value is bool) return value;
      final text = value?.toString().toLowerCase();
      return text == 'true' || text == '1';
    }

    return WeeklyMission(
      missionId: json['mission_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetType: json['target_type']?.toString() ?? '',
      targetValue: toInt(json['target_value']),
      currentValue: toInt(json['current_value']),
      rewardCoins: toInt(json['reward_coins']),
      isCompleted: toBool(json['is_completed']),
      isClaimed: toBool(json['is_claimed']),
    );
  }

  double get progress {
    if (targetValue <= 0) return isCompleted ? 1.0 : 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }
}

class MissionClaimResult {
  final int claimedCoins;
  final String message;

  const MissionClaimResult({
    required this.claimedCoins,
    required this.message,
  });

  factory MissionClaimResult.fromJson(Map<String, dynamic> json) {
    final value = json['claimed_coins'];
    final coins = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return MissionClaimResult(
      claimedCoins: coins,
      message: json['message']?.toString() ?? '',
    );
  }
}

class WeeklyMissionManager {
  /// 本番では週更新・ミッション生成・進捗更新・コイン付与はサーバー側で管理する。
  /// Flutter側は最新状態を取得して表示するだけ。
  Future<List<WeeklyMission>> fetchWeeklyMissions(String deviceId) async {
    final jsonList = await ApiService.fetchWeeklyMissions(deviceId);
    return jsonList.map(WeeklyMission.fromJson).toList();
  }

  /// 達成済みミッションの報酬をサーバーから受け取る。
  Future<MissionClaimResult> claimReward({
    required String deviceId,
    required String missionId,
  }) async {
    final json = await ApiService.claimMissionReward(
      deviceId: deviceId,
      missionId: missionId,
    );
    return MissionClaimResult.fromJson(json);
  }
}
