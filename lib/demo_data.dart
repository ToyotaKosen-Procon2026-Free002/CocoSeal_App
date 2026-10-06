import 'models/device.dart';
import 'models/gateway.dart';
import 'models/nearby_communication.dart';
import 'models/seal.dart';

class DemoData {
  const DemoData._();

  // デモ中に変更した親機設定を、アプリを閉じるまで保持する。
  static final Map<String, Gateway> _gatewayOverrides = {};
  static final List<Seal> originalSeals = [];

  static Seal addOriginalSeal({
    required String name,
    required String description,
    required int rarity,
    required String imageDataUrl,
  }) {
    final seal = Seal(
      id: 'demo-original-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      description: description,
      rarity: rarity,
      imagePath: imageDataUrl,
    );
    originalSeals.add(seal);
    return seal;
  }

  static const int coins = 120;
  static const double battery = 86;

  // デモ中のコイン残高を子機ごとに保持する。
  static final Map<String, int> _coinBalances = {};

  static int coinsFor(String deviceId, {int initial = coins}) =>
      _coinBalances.putIfAbsent(deviceId, () => initial);

  static bool spendCoins(String deviceId, int amount) {
    final current = coinsFor(deviceId);
    if (current < amount) return false;
    _coinBalances[deviceId] = current - amount;
    return true;
  }

  // 「ほぞん」を押したシール帳だけを、画面を閉じても保持する。
  // 値は UI 型に依存しないよう Map で保存する。
  static final Map<String, List<Map<String, dynamic>>> _savedSealBooks = {};

  static void saveSealBook(String deviceId, List<Map<String, dynamic>> placements) {
    _savedSealBooks[deviceId] = placements
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<Map<String, dynamic>> loadSealBook(String deviceId) =>
      (_savedSealBooks[deviceId] ?? const <Map<String, dynamic>>[])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  static List<Device> devices() => [
        Device(
          id: 'sample-device-cocone',
          name: 'ここね',
          coins: coinsFor('sample-device-cocone'),
          battery: battery,
          lastTimestamp: DateTime.now().toUtc().toIso8601String(),
        ),
        Device(
          id: 'sample-device-taro',
          name: 'たろう',
          coins: coinsFor('sample-device-taro', initial: 95),
          battery: 76,
          lastTimestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      ];

  static const List<SealPack> sealPacks = [
    SealPack(
      id: 'demo-pack-normal',
      name: 'ノーマルパック',
      description: 'シールが3枚入ってるよ',
      oncePrice: 10,
      imagePath: '',
    ),
    SealPack(
      id: 'demo-pack-special',
      name: 'スペシャルパック',
      description: 'Rシールがかならず1枚入ってるよ',
      oncePrice: 30,
      imagePath: '',
    ),
  ];

  static const Seal neighborhoodAssociationChairSeal = Seal(
    id: 'demo-seal-neighborhood-chair',
    name: '町内会会長',
    description: '町のみんなを見守っている特別なシールだよ',
    rarity: 1,
    imagePath: 'assets/images/seals/neighborhood_association_chair.png',
    bookNumber: 13,
  );

  static const List<Seal> seals = [
    Seal(
      id: 'demo-seal-001',
      name: 'うさぎ',
      description: '大きな耳と広い視野で敵をいち早く察知できるよ',
      rarity: 0,
      imagePath: 'assets/images/seals/rabbit.png',
      bookNumber: 1,
    ),
    Seal(
      id: 'demo-seal-002',
      name: 'スターうさぎ',
      description: 'かがやくステージに立ってるぞ！',
      rarity: 1,
      imagePath: 'assets/images/seals/star_rabbit.png',
      bookNumber: 2,
    ),
    Seal(
      id: 'demo-seal-003',
      name: 'ねむねむうさぎ',
      description: '寝ている時は鼻のヒクヒクがとまるよ',
      rarity: 0,
      imagePath: 'assets/images/seals/sleeping_rabbit.png',
      bookNumber: 3,
    ),
    Seal(
      id: 'demo-seal-004',
      name: 'しば',
      description: '柴犬は国の天然記念物にも指定されてるよ',
      rarity: 0,
      imagePath: 'assets/images/seals/shiba.png',
      bookNumber: 4,
    ),
    Seal(
      id: 'demo-seal-005',
      name: 'すやしば',
      description: '急所であるお腹を隠して眠っているよ',
      rarity: 1,
      imagePath: 'assets/images/seals/fuse_shiba.png',
      bookNumber: 5,
    ),
    Seal(
      id: 'demo-seal-006',
      name: 'ふせしば',
      description: 'オオカミに最も近い犬種って言われてるよ',
      rarity: 0,
      imagePath: 'assets/images/seals/fuse_shiba.png',
      bookNumber: 6,
    ),
    Seal(
      id: 'demo-seal-007',
      name: 'ねこ',
      description: '1日のうち12時間〜16時間を睡眠に使うよ',
      rarity: 0,
      imagePath: 'assets/images/seals/cat.png',
      bookNumber: 7,
    ),
    Seal(
      id: 'demo-seal-008',
      name: 'パンダ',
      description: '生まれたばかりの赤ちゃんは100〜150gくらいしかないよ',
      rarity: 0,
      imagePath: 'assets/images/seals/panda.png',
      bookNumber: 8,
    ),
    Seal(
      id: 'demo-seal-009',
      name: 'はむはむ',
      description: '前歯が一生伸び続けるよ',
      rarity: 0,
      imagePath: 'assets/images/seals/hamuhamu.png',
      bookNumber: 9,
    ),
    Seal(
      id: 'demo-seal-010',
      name: 'はむはむスター',
      description: '超がつくほどの一匹狼。1ケージに1匹が鉄則だよ',
      rarity: 1,
      imagePath: 'assets/images/seals/hamuhamu_star.png',
      bookNumber: 10,
    ),
    Seal(
      id: 'demo-seal-011',
      name: 'トリケラトプス',
      description: '何百本もの歯をもってるよ',
      rarity: 1,
      imagePath: 'assets/images/seals/triceratops.png',
      bookNumber: 11,
    ),
    Seal(
      id: 'demo-seal-012',
      name: 'スター',
      description: '一番熱い星は青色だよ！',
      rarity: 0,
      imagePath: 'assets/images/seals/star.png',
      bookNumber: 12,
    ),
  ];

  static String sealName(String? id) {
    if (id == null) return 'なし';
    for (final seal in seals) {
      if (seal.id == id) return seal.name;
    }
    return id;
  }

  static List<DeviceSeal> ownedSeals(String deviceId) {
    final now = DateTime.now();
    return [
      DeviceSeal(id: 'demo-owned-1', deviceId: deviceId, sealId: seals[0].id, statusId: 0, acquiredPlace: 'さくら公園', acquiredAt: now.subtract(const Duration(days: 4))),
      DeviceSeal(id: 'demo-owned-2', deviceId: deviceId, sealId: seals[0].id, statusId: 0, acquiredPlace: '駅前ひろば', acquiredAt: now.subtract(const Duration(hours: 2))),
      DeviceSeal(id: 'demo-owned-3', deviceId: deviceId, sealId: seals[1].id, statusId: 0, acquiredPlace: '東京駅レアスポット', acquiredAt: now.subtract(const Duration(days: 1, hours: 3))),
      DeviceSeal(id: 'demo-owned-4', deviceId: deviceId, sealId: seals[3].id, statusId: 0, acquiredPlace: '学校の正門', acquiredAt: now.subtract(const Duration(days: 2))),
      DeviceSeal(id: 'demo-owned-5', deviceId: deviceId, sealId: seals[5].id, statusId: 0, acquiredPlace: 'みどり児童館', acquiredAt: now.subtract(const Duration(days: 3))),
    ];
  }

  /// サーバーから取得した最新のシールカタログに合わせて、
  /// デモ用の所持シールを作る。
  ///
  /// サーバーのUUIDをそのまま使うため、図鑑とシール帳の両方で
  /// 「所持しているシール」として正しく対応付けられる。
  static List<DeviceSeal> ownedSealsForCatalog(
    String deviceId,
    List<Seal> catalog,
  ) {
    if (catalog.isEmpty) return const <DeviceSeal>[];

    final now = DateTime.now();
    final sortedCatalog = [...catalog]
      ..sort(
        (a, b) =>
            (a.bookNumber ?? 9999).compareTo(b.bookNumber ?? 9999),
      );
    final oddNumberedSeals = <Seal>[
      for (var index = 0; index < sortedCatalog.length; index++)
        if (((sortedCatalog[index].bookNumber ?? index + 1) % 2) == 1)
          sortedCatalog[index],
    ];
    const places = <String>[
      'さくら公園',
      '駅前ひろば',
      '東京駅レアスポット',
      '学校の正門',
      'みどり児童館',
      '中央図書館',
      '商店街',
      '上野公園レアスポット',
    ];

    return <DeviceSeal>[
      for (var index = 0; index < oddNumberedSeals.length; index++)
        DeviceSeal(
          id: 'demo-owned-catalog-$index',
          deviceId: deviceId,
          sealId: oddNumberedSeals[index].id,
          statusId: 0,
          acquiredPlace: places[index % places.length],
          acquiredAt: now.subtract(Duration(hours: 5 + index * 11)),
        ),
    ];
  }

  static List<NearbyCommunication> nearbyCommunications(
    String deviceId,
    List<Seal> catalog,
  ) {
    final now = DateTime.now();
    final isTaro = deviceId == 'sample-device-taro';
    String sealId(int index) =>
        catalog.isEmpty ? '' : catalog[index % catalog.length].id;
    return [
      NearbyCommunication(
        eventId: '$deviceId-event-001',
        myId: deviceId,
        partnerId: isTaro ? 'そうた' : 'ゆうき',
        partnerIsGateway: false,
        sendSealId: sealId(0),
        receiveSealId: sealId(3),
        timeStamp: now.subtract(Duration(hours: isTaro ? 1 : 2)),
      ),
      NearbyCommunication(
        eventId: '$deviceId-event-002',
        myId: deviceId,
        partnerId: isTaro ? '豊田高専' : '駅前レアスポット',
        partnerIsGateway: true,
        receiveSealId: sealId(1),
        timeStamp: now.subtract(
          Duration(days: 1, hours: isTaro ? 1 : 3),
        ),
      ),
      NearbyCommunication(
        eventId: '$deviceId-event-003',
        myId: deviceId,
        partnerId: isTaro ? 'はると' : 'みお',
        partnerIsGateway: false,
        sendSealId: sealId(6),
        receiveSealId: sealId(8),
        timeStamp: now.subtract(Duration(days: isTaro ? 2 : 3)),
      ),
    ];
  }

  static const List<Gateway> gateways = [
    Gateway(
      id: 'demo-gateway-001',
      name: '豊田高専',
      distributeSealId: 'demo-seal-002',
      latitude: 35.681236,
      longitude: 139.767125,
    ),
    Gateway(
      id: 'demo-gateway-002',
      name: '上野公園レアスポット',
      distributeSealId: 'demo-seal-008',
      latitude: 35.714765,
      longitude: 139.773431,
    ),
    Gateway(
      id: 'demo-gateway-003',
      name: '渋谷駅レアスポット',
      distributeSealId: 'demo-seal-007',
      latitude: 35.658034,
      longitude: 139.701636,
    ),
  ];

  static List<Gateway> gatewaysFor(List<Seal> catalog) {
    String? sealId(int index) =>
        catalog.isEmpty ? null : catalog[index % catalog.length].id;
    final defaults = [
      Gateway(
        id: 'demo-gateway-001',
        name: '豊田高専',
        distributeSealId: neighborhoodAssociationChairSeal.id,
        latitude: 35.681236,
        longitude: 139.767125,
      ),
      Gateway(
        id: 'demo-gateway-002',
        name: '上野公園レアスポット',
        distributeSealId: sealId(7),
        latitude: 35.714765,
        longitude: 139.773431,
      ),
      Gateway(
        id: 'demo-gateway-003',
        name: '渋谷駅レアスポット',
        distributeSealId: sealId(6),
        latitude: 35.658034,
        longitude: 139.701636,
      ),
    ];
    return [
      for (final gateway in defaults)
        _gatewayOverrides[gateway.id] ?? gateway,
    ];
  }

  static void updateGateway({
    required String gatewayId,
    required String name,
    required String distributeSealId,
    required double latitude,
    required double longitude,
  }) {
    _gatewayOverrides[gatewayId] = Gateway(
      id: gatewayId,
      name: name,
      distributeSealId: distributeSealId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
