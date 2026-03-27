enum BinStatus {
  active,
  offline,
  needsAttention,
}

class Bin {
  final String id;
  final String type;
  final int filled;
  final int battery;
  final DateTime lastCollected;
  final BinLocation desktopLocation;
  final BinLocation mobileLocation;
  
  // Additional properties for enhanced detail view
  final String? name;
  final String? location;
  final bool hasAlert;
  final String? alertMessage;
  final BinStatus status;
  final int? currentVolume;
  final int? maxCapacity;
  final int? dailyProgress;
  final int? estimatedTimeRemaining;
  final bool? sensorUltrasonic;
  final bool? sensorWeight;
  final bool? sensorLid;
  final bool? sensorLedScreen;
  final bool? sensorServoMotor;
  final bool? sensorThermalPrinter;
  final bool? sensorBattery;
  final bool? sensorSolarPanel;

  Bin({
    required this.id,
    required this.type,
    required this.filled,
    required this.battery,
    required this.lastCollected,
    required this.desktopLocation,
    required this.mobileLocation,
    this.name,
    this.location,
    this.hasAlert = false,
    this.alertMessage,
    this.status = BinStatus.active,
    this.currentVolume,
    this.maxCapacity,
    this.dailyProgress,
    this.estimatedTimeRemaining,
    this.sensorUltrasonic,
    this.sensorWeight,
    this.sensorLid,
    this.sensorLedScreen,
    this.sensorServoMotor,
    this.sensorThermalPrinter,
    this.sensorBattery,
    this.sensorSolarPanel,
  });

  Bin copyWith({
    String? id,
    String? type,
    int? filled,
    int? battery,
    DateTime? lastCollected,
    BinLocation? desktopLocation,
    BinLocation? mobileLocation,
    String? name,
    String? location,
    bool? hasAlert,
    String? alertMessage,
    BinStatus? status,
    int? currentVolume,
    int? maxCapacity,
    int? dailyProgress,
    int? estimatedTimeRemaining,
    bool? sensorUltrasonic,
    bool? sensorWeight,
    bool? sensorLid,
    bool? sensorLedScreen,
    bool? sensorServoMotor,
    bool? sensorThermalPrinter,
    bool? sensorBattery,
    bool? sensorSolarPanel,
  }) {
    return Bin(
      id: id ?? this.id,
      type: type ?? this.type,
      filled: filled ?? this.filled,
      battery: battery ?? this.battery,
      lastCollected: lastCollected ?? this.lastCollected,
      desktopLocation: desktopLocation ?? this.desktopLocation,
      mobileLocation: mobileLocation ?? this.mobileLocation,
      name: name ?? this.name,
      location: location ?? this.location,
      hasAlert: hasAlert ?? this.hasAlert,
      alertMessage: alertMessage ?? this.alertMessage,
      status: status ?? this.status,
      currentVolume: currentVolume ?? this.currentVolume,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      sensorUltrasonic: sensorUltrasonic ?? this.sensorUltrasonic,
      sensorWeight: sensorWeight ?? this.sensorWeight,
      sensorLid: sensorLid ?? this.sensorLid,
      sensorLedScreen: sensorLedScreen ?? this.sensorLedScreen,
      sensorServoMotor: sensorServoMotor ?? this.sensorServoMotor,
      sensorThermalPrinter: sensorThermalPrinter ?? this.sensorThermalPrinter,
      sensorBattery: sensorBattery ?? this.sensorBattery,
      sensorSolarPanel: sensorSolarPanel ?? this.sensorSolarPanel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'filled': filled,
      'battery': battery,
      'lastCollected': lastCollected.millisecondsSinceEpoch,
      'desktopLocation': desktopLocation.toJson(),
      'mobileLocation': mobileLocation.toJson(),
    };
  }

  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      id: json['id'],
      type: json['type'],
      filled: json['filled'],
      battery: json['battery'],
      lastCollected: DateTime.fromMillisecondsSinceEpoch(json['lastCollected']),
      desktopLocation: BinLocation.fromJson(json['desktopLocation']),
      mobileLocation: BinLocation.fromJson(json['mobileLocation']),
    );
  }

  // Helper getters for compatibility with TypeScript interface
  String get nameOrId => name ?? id;
  String get locationOrId => location ?? id;
  int get fillLevel => filled;
  int get batteryLevel => battery;
  DateTime get lastEmptied => lastCollected;
  
  // Helper methods
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(lastCollected);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 48) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final past = lastCollected;
    final diffMs = now.difference(past).inMilliseconds;
    final diffHours = (diffMs / (1000 * 60 * 60)).floor();
    final diffDays = (diffHours / 24).floor();
    
    if (diffDays > 0) {
      return '${diffDays} day${diffDays > 1 ? 's' : ''} ago';
    }
    if (diffHours > 0) {
      return '${diffHours} hour${diffHours > 1 ? 's' : ''} ago';
    }
    return 'Less than an hour ago';
  }

  BatteryStatus get batteryStatus {
    if (battery >= 75) {
      return BatteryStatus.high;
    } else if (battery >= 50) {
      return BatteryStatus.medium;
    } else if (battery >= 25) {
      return BatteryStatus.medium;
    } else {
      return BatteryStatus.low;
    }
  }

  String get batteryStatusText {
    switch (batteryStatus) {
      case BatteryStatus.high:
        return 'Excellent';
      case BatteryStatus.medium:
        return battery >= 50 ? 'Good' : 'Fair';
      case BatteryStatus.low:
        return 'Low';
    }
  }
}

class BinLocation {
  final double lat;
  final double lng;

  BinLocation({required this.lat, required this.lng});

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  factory BinLocation.fromJson(Map<String, dynamic> json) {
    return BinLocation(
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }
}

enum BatteryStatus {
  high,
  medium,
  low,
}

// CollectionRecord model for tracking collection history
class CollectionRecord {
  final String id;
  final String binId;
  final DateTime collectedAt;
  final int itemsCollected;

  CollectionRecord({
    required this.id,
    required this.binId,
    required this.collectedAt,
    required this.itemsCollected,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'binId': binId,
      'collectedAt': collectedAt.millisecondsSinceEpoch,
      'itemsCollected': itemsCollected,
    };
  }

  factory CollectionRecord.fromJson(Map<String, dynamic> json) {
    return CollectionRecord(
      id: json['id'],
      binId: json['binId'],
      collectedAt: DateTime.fromMillisecondsSinceEpoch(json['collectedAt']),
      itemsCollected: json['itemsCollected'],
    );
  }
}
