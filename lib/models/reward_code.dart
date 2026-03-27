class RewardCode {
  final String id;
  final String code; // 4-digit code
  final double points; // Number of points
  final bool isRedeemed; // Whether the code has been redeemed
  final bool isAssigned; // Whether the code has been assigned/displayed in kiosk
  final String? redeemedBy; // User ID who redeemed it
  final DateTime? redeemedAt; // When it was redeemed

  RewardCode({
    required this.id,
    required this.code,
    required this.points,
    this.isRedeemed = false,
    this.isAssigned = false,
    this.redeemedBy,
    this.redeemedAt,
  });

  RewardCode copyWith({
    String? id,
    String? code,
    double? points,
    bool? isRedeemed,
    bool? isAssigned,
    String? redeemedBy,
    DateTime? redeemedAt,
  }) {
    return RewardCode(
      id: id ?? this.id,
      code: code ?? this.code,
      points: points ?? this.points,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      isAssigned: isAssigned ?? this.isAssigned,
      redeemedBy: redeemedBy ?? this.redeemedBy,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'points': points,
      'isRedeemed': isRedeemed,
      'isAssigned': isAssigned,
      'redeemedBy': redeemedBy,
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }

  factory RewardCode.fromJson(Map<String, dynamic> json) {
    DateTime? redeemedAt;
    if (json['redeemedAt'] != null) {
      if (json['redeemedAt'].toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        final timestamp = json['redeemedAt'];
        if (timestamp is Map && timestamp['_seconds'] != null) {
          redeemedAt = DateTime.fromMillisecondsSinceEpoch(
              timestamp['_seconds'] * 1000);
        }
      } else if (json['redeemedAt'] is String) {
        redeemedAt = DateTime.parse(json['redeemedAt']);
      }
    }

    return RewardCode(
      id: json['id'],
      code: json['code'],
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      isRedeemed: json['isRedeemed'] ?? false,
      isAssigned: json['isAssigned'] ?? false,
      redeemedBy: json['redeemedBy'],
      redeemedAt: redeemedAt,
    );
  }
}

