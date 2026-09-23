import 'package:coco/models/device.dart';
import 'package:coco/models/nearby_communication.dart';
import 'package:coco/models/seal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Device parses an API response', () {
    final device = Device.fromJson({
      'id': 'ESP-0001',
      'owner': 'user-1',
      'name': 'そな',
      'coins': 12,
      'battery': 87.5,
      'last_timestamp': '2026-09-21T10:05:02.226Z',
    });

    expect(device.id, 'ESP-0001');
    expect(device.coins, 12);
    expect(device.battery, 87.5);
  });

  test('NearbyCommunication accepts the Swagger timestamp field', () {
    final log = NearbyCommunication.fromJson({
      'event_id': 'event-1',
      'my_id': 'ESP-0001',
      'partner_id': 'gateway-1',
      'partner_is_gateway': true,
      'send_seal_id': null,
      'receive_seal_id': 'seal-1',
      'timestamp': '2026-09-21T10:05:02.230Z',
    });

    expect(log.partnerIsGateway, isTrue);
    expect(log.receiveSealId, 'seal-1');
    expect(log.timeStamp.isUtc, isTrue);
  });

  test('Seal and DeviceSeal parse API responses', () {
    final seal = Seal.fromJson({
      'id': 'seal-1',
      'name': 'ココシール',
      'description': 'テスト用',
      'rarity': 2,
      'image_path': '/images/seal-1.png',
    });
    final owned = DeviceSeal.fromJson({
      'id': 'owned-1',
      'device_id': 'ESP-0001',
      'seal_id': 'seal-1',
      'status_id': 0,
      'book_page': null,
      'book_x': null,
      'book_y': null,
      'book_rotation': null,
      'book_scale': null,
    });

    expect(seal.rarity, 2);
    expect(owned.sealId, seal.id);
  });
}
