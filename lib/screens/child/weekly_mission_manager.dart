import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyMissionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// アプリ起動時などに呼び出すチェック処理
  Future<void> checkAndRefreshWeeklyMissions(String childId) async {
    final childDocRef = _firestore.collection('children').doc(childId);
    final childSnap = await childDocRef.get();

    if (!childSnap.exists) return;

    final data = childSnap.data();
    final Timestamp? lastUpdated = data?['lastMissionUpdate'] as Timestamp?;

    final DateTime now = DateTime.now();
    bool shouldRefresh = false;

    if (lastUpdated == null) {
      // 初回実行時は更新する
      shouldRefresh = true;
    } else {
      final DateTime lastDate = lastUpdated.toDate();
      // 前回更新から7日以上経過しているかチェック
      final differenceInDays = now.difference(lastDate).inDays;
      if (differenceInDays >= 7) {
        shouldRefresh = true;
      }
    }

    // 7日以上経っていれば新しい一週間ミッションを生成！
    if (shouldRefresh) {
      await _generateNewWeeklyMissions(childId);
      // 最終更新日を「今日」に更新
      await childDocRef.update({
        'lastMissionUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 一週間分のミッションを生成する処理
  Future<void> _generateNewWeeklyMissions(String childId) async {
    final childMissionsRef = _firestore
        .collection('children')
        .doc(childId)
        .collection('missions');

    // --------------------------------------------------
    // 一週間目標の設定（週の目標値を少し高めに設定）
    // --------------------------------------------------
    int weeklyPassTarget = 10;   // 今週は10回すれ違い！（例: 10枚）
    int weeklyParentTarget = 5;   // 今週は親機を5回通過！（例: 50枚）

    // 1. すれ違いミッション（回数 × 1枚）
    await childMissionsRef.doc('mission_pass').set({
      'title': 'おともだちと $weeklyPassTarget 回すれちがおう！',
      'type': 'pass',
      'current': 0,
      'max': weeklyPassTarget,
      'reward': weeklyPassTarget * 1, // 10枚
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. 充電満タンミッション（5枚）
    await childMissionsRef.doc('mission_battery').set({
      'title': 'バッテリーを まんたんにしよう！',
      'type': 'battery',
      'current': 0,
      'max': 1,
      'reward': 5,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. 親機を通るミッション（回数 × 10枚）
    await childMissionsRef.doc('mission_parent').set({
      'title': 'おうち（親機）の ちかくを $weeklyParentTarget 回とおろう！',
      'type': 'parent_station',
      'current': 0,
      'max': weeklyParentTarget,
      'reward': weeklyParentTarget * 10, // 50枚
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
