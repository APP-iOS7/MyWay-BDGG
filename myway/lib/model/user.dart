class UserModel {
  final String username;
  final String useremail;
  final String uid;

  UserModel({
    required this.username,
    required this.useremail,
    required this.uid,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': useremail, 'uid': uid};
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      useremail: json['email'],
      uid: json['uid'],
    );
  }
}
