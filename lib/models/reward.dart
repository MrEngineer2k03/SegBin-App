enum RewardStatus {
  locked,
  available,
  redeemed,
}

enum RewardPlatform {
  mobile,
  kiosk,
  both,
}

class Reward {
  final String id;
  final String name;
  final String description;
  final int minimumRequirement; // Number of trash disposals or points needed
  final String? redeemCode; // Optional redeem code
  final RewardStatus status;
  final double currentProgress;
  final RewardPlatform platform; // Platform where reward is available

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumRequirement,
    this.redeemCode,
    this.status = RewardStatus.locked,
    this.currentProgress = 0.0,
    this.platform = RewardPlatform.both,
  });

  Reward copyWith({
    String? id,
    String? name,
    String? description,
    int? minimumRequirement,
    String? redeemCode,
    RewardStatus? status,
    double? currentProgress,
    RewardPlatform? platform,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minimumRequirement: minimumRequirement ?? this.minimumRequirement,
      redeemCode: redeemCode ?? this.redeemCode,
      status: status ?? this.status,
      currentProgress: currentProgress ?? this.currentProgress,
      platform: platform ?? this.platform,
    );
  }

  double get progressPercentage {
    if (minimumRequirement == 0) return 1.0;
    return (currentProgress / minimumRequirement).clamp(0.0, 1.0);
  }

  bool get isUnlocked => currentProgress >= minimumRequirement;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minimumRequirement': minimumRequirement,
      'redeemCode': redeemCode,
      'status': status.toString().split('.').last,
      'currentProgress': currentProgress,
      'platform': platform.toString().split('.').last,
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    final platformStr = json['platform'] as String? ?? 'both';
    return Reward(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      minimumRequirement: json['minimumRequirement'],
      redeemCode: json['redeemCode'],
      status: RewardStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RewardStatus.locked,
      ),
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      platform: RewardPlatform.values.firstWhere(
        (e) => e.toString().split('.').last == platformStr,
        orElse: () => RewardPlatform.both,
      ),
    );
  }
}

