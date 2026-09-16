import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'weekly_mission_manager.dart';

class MissionScreen extends StatefulWidget {
  final String childId;

  const MissionScreen({super.key, this.childId = 'ESP-0001'});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final WeeklyMissionManager _missionManager = WeeklyMissionManager();

  // 選択中の回答を保持
  final Map<String, String> _selectedOption = {};
  // メッセージ判定結果
  final Map<String, String> _quizFeedback = {};

  @override
  void initState() {
    super.initState();
    _missionManager.checkAndRefreshWeeklyMissions(widget.childId);
  }

  // ★ コインを加算する関数
  Future<void> _addCoinsToChild(int rewardAmount) async {
    if (rewardAmount <= 0) return;

    final childRef = FirebaseFirestore.instance.collection('children').doc(widget.childId);

    // FieldValue.increment を使うことで、現在の値に安全に加算できます
    await childRef.set({
      'coins': FieldValue.increment(rewardAmount),
    }, SetOptions(merge: true));
  }

  // 通常ミッションの報酬受け取り処理
  Future<void> _claimReward(String docId, Map<String, dynamic> mission) async {
    final int reward = mission['reward'] ?? 0;

    // 1. ミッションをクリア済みに更新
    await FirebaseFirestore.instance
        .collection('children')
        .doc(widget.childId)
        .collection('missions')
        .doc(docId)
        .update({'isCompleted': true});

    // 2. 子供のコイン数を加算
    await _addCoinsToChild(reward);

    if (!mounted) return;
    _showRewardDialog(reward);
  }

  // クイズの「こたえる」ボタン押下時の判定処理
  Future<void> _submitQuizAnswer(String docId, Map<String, dynamic> mission) async {
    final String? selected = _selectedOption[docId];
    if (selected == null) return;

    final String correctAnswer = (mission['correctAnswer'] ?? '').toString().trim();
    final String userChoice = selected.trim();
    final int reward = mission['reward'] ?? 0;

    if (userChoice == correctAnswer) {
      // 1. 正解処理（ミッション更新）
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .collection('missions')
          .doc(docId)
          .update({
        'current': 1,
        'isCompleted': true,
      });

      // 2. コインを加算
      await _addCoinsToChild(reward);

      setState(() {
        _quizFeedback[docId] = '🎉 せいかい！';
      });

      if (!mounted) return;
      _showRewardDialog(reward);
    } else {
      // 不正解処理
      setState(() {
        _quizFeedback[docId] = '❌ ざんねん！もういちど かんがえてみてね';
      });
    }
  }

  // ダイアログ表示
  void _showRewardDialog(int reward) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 ミッションたっせい！',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'ごほうびとして\n🪙 $reward 枚 のコインをゲット！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC0CB),
                    elevation: 0,
                  ),
                  child: const Text('やったー！', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ウィークリーミッション',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .doc(widget.childId)
            .collection('missions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('ミッションを準備中...'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final mission = doc.data() as Map<String, dynamic>;

              final String docId = doc.id;
              final String type = mission['type'] ?? '';
              final int current = mission['current'] ?? 0;
              final int max = mission['max'] ?? 1;
              final bool isCompleted = current >= max;
              final bool isClaimed = mission['isCompleted'] ?? false;
              final List<dynamic> options = mission['options'] ?? [];
              final String explanation = mission['explanation'] ?? '';

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
                    // ヘッダー（タイトル＆報酬枚数）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mission['title'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        Text(
                          '🪙 ${mission['reward'] ?? 0}枚',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // クイズタイプの場合の表示
                    if (type == 'quiz' && options.isNotEmpty) ...[
                      Column(
                        children: options.map((option) {
                          final String optionStr = option.toString();
                          final bool isSelected = _selectedOption[docId] == optionStr;

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              onPressed: isClaimed
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedOption[docId] = optionStr;
                                        _quizFeedback[docId] = '';
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                backgroundColor: isSelected ? Colors.orange.shade50 : Colors.white,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: Text(
                                optionStr,
                                style: TextStyle(
                                  color: isSelected ? Colors.orange.shade900 : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // 「こたえる」ボタン
                      if (!isClaimed && _selectedOption[docId] != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _submitQuizAnswer(docId, mission),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'こたえる',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],

                      // 判定フィードバック
                      if (_quizFeedback[docId] != null && _quizFeedback[docId]!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            _quizFeedback[docId]!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _quizFeedback[docId]!.contains('せいかい')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],

                      // クリア時解説
                      if (isClaimed && explanation.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '💡 かいせつ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                explanation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 8),

                    // フッター
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'しんちょく: $current / $max',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        if (type != 'quiz')
                          _buildActionButton(
                            isCompleted: isCompleted,
                            isClaimed: isClaimed,
                            onPressed: () => _claimReward(docId, mission),
                          )
                        else if (isClaimed)
                          _buildCompletedBadge(),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required bool isCompleted,
    required bool isClaimed,
    required VoidCallback onPressed,
  }) {
    if (isClaimed) {
      return _buildCompletedBadge();
    }

    if (isCompleted) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC0CB),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: const Text('ごほうびをもらう！', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('ちょうせんちゅう', style: TextStyle(fontSize: 12, color: Colors.black45)),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('クリアずみ', style: TextStyle(fontSize: 12, color: Colors.black54)),
    );
  }
}