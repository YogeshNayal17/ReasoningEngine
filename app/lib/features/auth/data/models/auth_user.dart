class AuthUser {
  const AuthUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.isNerd,
  });

  final String token;
  final int userId;
  final String name;
  final String email;
  final bool isNerd;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        token: json['token'] as String,
        userId: json['user_id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        isNerd: json['is_nerd'] as bool,
      );
}

class UsageSummary {
  const UsageSummary({
    required this.analysesUsed,
    required this.analysesLimit,
    required this.questionsUsed,
    required this.questionsLimit,
    required this.isNerd,
  });

  final int analysesUsed;
  final int analysesLimit;
  final int questionsUsed;
  final int questionsLimit;
  final bool isNerd;

  factory UsageSummary.fromJson(Map<String, dynamic> json) => UsageSummary(
        analysesUsed: json['analyses_used'] as int,
        analysesLimit: json['analyses_limit'] as int,
        questionsUsed: json['questions_used'] as int,
        questionsLimit: json['questions_limit'] as int,
        isNerd: json['is_nerd'] as bool,
      );
}
