class User {
  final String username;
  final String password;
  final double points;
  final UserType type;
  final String? name;
  final String? department;
  final String? course;
  final String? idNumber;
  final List<String> simNumbers;
  final String? profilePicture;

  User({
    required this.username,
    required this.password,
    required this.points,
    required this.type,
    this.name,
    this.department,
    this.course,
    this.idNumber,
    this.simNumbers = const [],
    this.profilePicture,
  });

  User copyWith({
    String? username,
    String? password,
    double? points,
    UserType? type,
    String? name,
    String? department,
    String? course,
    String? idNumber,
    List<String>? simNumbers,
    String? profilePicture,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      points: points ?? this.points,
      type: type ?? this.type,
      name: name ?? this.name,
      department: department ?? this.department,
      course: course ?? this.course,
      idNumber: idNumber ?? this.idNumber,
      simNumbers: simNumbers ?? this.simNumbers,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'points': points,
      'type': type.toString().split('.').last,
      'name': name,
      'department': department,
      'course': course,
      'idNumber': idNumber,
      'simNumbers': simNumbers,
      'profilePicture': profilePicture,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      type: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => UserType.user,
      ),
      name: json['name'],
      department: json['department'],
      course: json['course'],
      idNumber: json['idNumber'],
      simNumbers: json['simNumbers'] != null
          ? List<String>.from(json['simNumbers'] as List)
          : [],
      profilePicture: json['profilePicture'],
    );
  }
}

enum UserType {
  user,
  admin,
  staff,
}
