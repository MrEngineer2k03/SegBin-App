class Feedback {
  final String id;
  final String message;
  final DateTime feedbackTime;
  final String? userId;
  final String? name;
  final String? subject;
  final String? category; // 'Support', 'Bugs', 'Ideas'
  final String? email;
  final String? idNumber;
  final String? profilePicture;

  Feedback({
    required this.id,
    required this.message,
    required this.feedbackTime,
    this.userId,
    this.name,
    this.subject,
    this.category,
    this.email,
    this.idNumber,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'feedbackTime': feedbackTime.toIso8601String(),
      'userId': userId,
      'name': name,
      'subject': subject,
      'category': category,
      'email': email,
      'idNumber': idNumber,
      'profilePicture': profilePicture,
    };
  }

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      feedbackTime: DateTime.parse(json['feedbackTime']),
      userId: json['userId'],
      name: json['name'],
      subject: json['subject'],
      category: json['category'],
      email: json['email'],
      idNumber: json['idNumber'],
      profilePicture: json['profilePicture'],
    );
  }

  Feedback copyWith({
    String? id,
    String? message,
    DateTime? feedbackTime,
    String? userId,
    String? name,
    String? subject,
    String? category,
    String? email,
    String? idNumber,
    String? profilePicture,
  }) {
    return Feedback(
      id: id ?? this.id,
      message: message ?? this.message,
      feedbackTime: feedbackTime ?? this.feedbackTime,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      email: email ?? this.email,
      idNumber: idNumber ?? this.idNumber,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
