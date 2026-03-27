enum QuestTrashType {
  plastic,
  paper,
  singleStream,
  mixed,
}

extension QuestTrashTypeExtension on QuestTrashType {
  String get typeString {
    switch (this) {
      case QuestTrashType.plastic:
        return 'plastic';
      case QuestTrashType.paper:
        return 'paper';
      case QuestTrashType.singleStream:
        return 'single-stream';
      case QuestTrashType.mixed:
        return 'mixed';
    }
  }
}

class Quest {
  final String id;
  final String name;
  final QuestTrashType type;
  final String description;
  final String reward;
  final int target; // Number of items needed
  final String platform; // 'mobile', 'kiosk', or 'both'

  Quest({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.reward,
    this.target = 1,
    this.platform = 'kiosk',
  });

  Quest copyWith({
    String? id,
    String? name,
    QuestTrashType? type,
    String? description,
    String? reward,
    int? target,
    String? platform,
  }) {
    return Quest(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      target: target ?? this.target,
      platform: platform ?? this.platform,
    );
  }

  String get typeString {
    switch (type) {
      case QuestTrashType.plastic:
        return 'plastic';
      case QuestTrashType.paper:
        return 'paper';
      case QuestTrashType.singleStream:
        return 'single-stream';
      case QuestTrashType.mixed:
        return 'mixed';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case QuestTrashType.plastic:
        return 'Plastic';
      case QuestTrashType.paper:
        return 'Paper';
      case QuestTrashType.singleStream:
        return 'Single Stream';
      case QuestTrashType.mixed:
        return 'Mixed';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': name, // Also include as 'title' for compatibility
      'type': typeString,
      'description': description,
      'reward': reward,
      'target': target,
      'platform': platform,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'mixed';
    QuestTrashType questType;
    switch (typeStr) {
      case 'plastic':
        questType = QuestTrashType.plastic;
        break;
      case 'paper':
        questType = QuestTrashType.paper;
        break;
      case 'single-stream':
        questType = QuestTrashType.singleStream;
        break;
      case 'mixed':
      default:
        questType = QuestTrashType.mixed;
        break;
    }

    return Quest(
      id: json['id'],
      name: json['name'] ?? json['title'] ?? 'Quest',
      type: questType,
      description: json['description'] ?? json['desc'] ?? '',
      reward: json['reward'] ?? '',
      target: json['target'] ?? 1,
      platform: json['platform'] ?? 'kiosk',
    );
  }
}

