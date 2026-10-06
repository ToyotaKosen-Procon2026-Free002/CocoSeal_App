import 'package:flutter/material.dart';

import '../../app_config.dart';
import 'weekly_mission_manager.dart';

class MissionScreen extends StatefulWidget {
  final String childId;
  final ValueChanged<int>? onRewardClaimed;

  const MissionScreen({
    super.key,
    this.childId = 'ESP-0001',
    this.onRewardClaimed,
  });

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final WeeklyMissionManager _missionManager = WeeklyMissionManager();

  bool _loading = true;
  String? _error;
  List<WeeklyMission> _missions = const [];
  final Set<String> _claiming = <String>{};

  @override
  void initState() {
    super.initState();
    if (AppConfig.useDemoData) {
      _loading = false;
    } else {
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final missions =
          await _missionManager.fetchWeeklyMissions(widget.childId);
      if (!mounted) return;
      setState(() {
        _missions = missions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _claimReward(WeeklyMission mission) async {
    if (!mission.isCompleted ||
        mission.isClaimed ||
        _claiming.contains(mission.missionId)) {
      return;
    }

    setState(() => _claiming.add(mission.missionId));

    try {
      final result = await _missionManager.claimReward(
        deviceId: widget.childId,
        missionId: mission.missionId,
      );

      if (!mounted) return;

      widget.onRewardClaimed?.call(result.claimedCoins);
      _showRewardDialog(
        result.claimedCoins,
        message: result.message,
      );

      // 受取済み状態・最新進捗をサーバーから再取得する。
      await _loadMissions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ごほうびを受け取れませんでした。\n$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _claiming.remove(mission.missionId));
      }
    }
  }

  void _showRewardDialog(int reward, {String message = ''}) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 ミッションたっせい！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ごほうびとして\n🪙 $reward 枚 のコインをゲット！',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (message.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC0CB),
                  elevation: 0,
                ),
                child: const Text(
                  'やったー！',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ウィークリーミッション',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!AppConfig.useDemoData)
            IconButton(
              tooltip: '更新',
              onPressed: _loading ? null : _loadMissions,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: AppConfig.useDemoData
          ? _DemoWeeklyMissionView(
              onRewardClaimed: widget.onRewardClaimed,
            )
          : _buildProductionBody(),
    );
  }

  Widget _buildProductionBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ミッションを取得できませんでした',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMissions,
                child: const Text('もう一度読み込む'),
              ),
            ],
          ),
        ),
      );
    }

    if (_missions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMissions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('今週のミッションはありません')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          final mission = _missions[index];
          return _missionCard(mission);
        },
      ),
    );
  }

  Widget _missionCard(WeeklyMission mission) {
    final claiming = _claiming.contains(mission.missionId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🪙 ${mission.rewardCoins}枚',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          if (mission.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: mission.progress,
            minHeight: 7,
            color: const Color(0xFFE47AB1),
            backgroundColor: const Color(0xFFF0E7F5),
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'しんちょく: ${mission.currentValue} / ${mission.targetValue}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              _buildActionButton(
                mission: mission,
                claiming: claiming,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required WeeklyMission mission,
    required bool claiming,
  }) {
    if (mission.isClaimed) {
      return _buildCompletedBadge();
    }

    if (mission.isCompleted) {
      return ElevatedButton(
        onPressed: claiming ? null : () => _claimReward(mission),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC0CB),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
        ),
        child: Text(
          claiming ? 'うけとり中...' : 'ごほうびをもらう！',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'ちょうせんちゅう',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'うけとり済み',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _DemoWeeklyMissionView extends StatefulWidget {
  final ValueChanged<int>? onRewardClaimed;

  const _DemoWeeklyMissionView({
    this.onRewardClaimed,
  });

  @override
  State<_DemoWeeklyMissionView> createState() =>
      _DemoWeeklyMissionViewState();
}

class _DemoWeeklyMissionViewState
    extends State<_DemoWeeklyMissionView> {
  final List<Map<String, dynamic>> _missions = [
    {
      'title': 'おともだちと 10回すれちがおう！',
      'current': 7,
      'max': 10,
      'reward': 10,
      'claimed': false,
    },
    {
      'title': 'バッテリーを まんたんにしよう！',
      'current': 1,
      'max': 1,
      'reward': 5,
      'claimed': false,
    },
    {
      'title': '親機のちかくを 5回とおろう！',
      'current': 5,
      'max': 5,
      'reward': 50,
      'claimed': false,
    },
  ];

  void _claim(int index) {
    final mission = _missions[index];
    if ((mission['current'] as int) < (mission['max'] as int) ||
        mission['claimed'] == true) {
      return;
    }

    setState(() => mission['claimed'] = true);

    final reward = mission['reward'] as int;
    widget.onRewardClaimed?.call(reward);
    _showReward(reward);
  }

  void _showReward(int coins) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ミッションたっせい！'),
        content: Text('$coins枚のコインをゲット！'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('やったー！'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < _missions.length; index++)
          _missionCard(index),
      ],
    );
  }

  Widget _missionCard(int index) {
    final mission = _missions[index];
    final current = mission['current'] as int;
    final max = mission['max'] as int;
    final complete = current >= max;
    final claimed = mission['claimed'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('🪙 ${mission['reward']}枚'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: max <= 0
                  ? 0
                  : (current / max).clamp(0.0, 1.0).toDouble(),
              color: const Color(0xFFE47AB1),
              backgroundColor: const Color(0xFFF0E7F5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$current / $max'),
                const Spacer(),
                FilledButton(
                  onPressed:
                      complete && !claimed ? () => _claim(index) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE47AB1),
                  ),
                  child: Text(
                    claimed ? 'うけとり済み' : 'うけとる',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
