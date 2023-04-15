class User {
  String? id, createdAt, updatedAt, name, email;
  bool? emailVerification;

  User({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.email,
    this.emailVerification,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["\$id"],
        createdAt: json["\$createdAt"],
        updatedAt: json["\$updatedAt"],
        name: json["name"],
        email: json["email"],
        emailVerification: json["emailVerification"],
      );
}
