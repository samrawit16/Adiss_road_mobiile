class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isVerified;
  final DateTime? createdAt;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isVerified = false,
    this.createdAt,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isVerified: json['is_verified'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      profileImageUrl: json['profile_image_url']?.toString(),
    );
  }

  User copyWith({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      isVerified: isVerified,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
