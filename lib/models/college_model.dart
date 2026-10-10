class College {
  final String name;
  final double minGpa;
  final String category;
  final String description;

  College({
    required this.name,
    required this.minGpa,
    required this.category,
    this.description = '',
  });

  static double _parseGpa(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final s = val.toString().replaceAll('%', '').replaceAll(',', '.').trim();
    return double.tryParse(s) ?? 0.0;
  }

  factory College.fromMap(Map<String, dynamic> data) {
    return College(
      name: data['name']?.toString().trim() ??
          data['title']?.toString().trim() ??
          data['collegeName']?.toString().trim() ??
          '',
      minGpa: _parseGpa(
        data['minGpa'] ??
            data['min_gpa'] ??
            data['minAverage'] ??
            data['min_average'] ??
            data['average'] ??
            data['gpa'] ??
            data['rate'],
      ),
      category: data['category']?.toString().trim() ??
          data['track']?.toString().trim() ??
          data['branch']?.toString().trim() ??
          data['type']?.toString().trim() ??
          '',
      description: data['description']?.toString().trim() ??
          data['desc']?.toString().trim() ??
          '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'minGpa': minGpa,
      'category': category,
      'description': description,
    };
  }
}
