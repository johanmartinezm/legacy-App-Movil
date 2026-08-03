class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String companyName;
  final String jobTitle;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.jobTitle,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      companyName: json['company_name'] ?? '',
      jobTitle: json['job_title'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}
