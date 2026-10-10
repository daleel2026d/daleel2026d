class AppUser {
  final String uid;
  final String name;
  final String email;
  final String academicYear;
  final double average;
  final String track;
  final String role;
  final List<String> favorites;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.academicYear,
    required this.average,
    required this.track,
    required this.role,
    required this.favorites,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      academicYear: data['academicYear'] ?? '',
      average: (data['average'] ?? 0).toDouble(),
      track: data['track'] ?? '',
      role: data['role'] ?? 'student',
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'academicYear': academicYear,
      'average': average,
      'track': track,
      'role': role,
      'favorites': favorites,
    };
  }
}
