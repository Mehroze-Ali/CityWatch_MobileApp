class UserModel {
  final String id;
  final String email;
  final String? passwordHash;
  final String name;
  final DateTime? createdAt; // Made optional

  UserModel({
    required this.id,
    required this.email,
    this.passwordHash,
    required this.name,
    this.createdAt, // Optional now
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(), // Convert to string since backend returns int
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String?,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : json['date_joined'] != null
          ? DateTime.parse(json['date_joined'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
