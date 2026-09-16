class NearbyCommunication {
  final String eventId;
  final String myId;
  final String partnerId;
  final bool partnerIsGateway;
  final String? sendSealId;
  final String? receiveSealId;
  final DateTime timeStamp;

  NearbyCommunication({
    required this.eventId,
    required this.myId,
    required this.partnerId,
    required this.partnerIsGateway,
    this.sendSealId,
    this.receiveSealId,
    required this.timeStamp,
  });

  // サーバーから届いたJSON（Map）をDartのオブジェクトに変換する処理
  factory NearbyCommunication.fromJson(Map<String, dynamic> json) {
    return NearbyCommunication(
      eventId: json['event_id'] as String,
      myId: json['my_id'] as String,
      partnerId: json['partner_id'] as String,
      partnerIsGateway: json['partner_is_gateway'] as bool,
      sendSealId: json['send_seal_id'] as String?,
      receiveSealId: json['receive_seal_id'] as String?,
      timeStamp: DateTime.parse(json['time_stamp'] as String),
    );
  }
}