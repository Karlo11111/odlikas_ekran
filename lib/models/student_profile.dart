class StudentProfile {
  final String name;
  final String email;

  StudentProfile({required this.name, required this.email});

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'],
      email: json['email'],
    );
  }
}
a