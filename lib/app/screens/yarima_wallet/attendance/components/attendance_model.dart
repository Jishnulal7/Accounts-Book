class AttendanceCategory {
  String name;
  List<Subcategory> subcategories;

  AttendanceCategory(this.name, [List<Subcategory>? subcategories])
      : subcategories = subcategories ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'subcategories': subcategories.map((s) => s.toJson()).toList(),
      };

  factory AttendanceCategory.fromJson(Map<String, dynamic> json) {
    return AttendanceCategory(
      json['name'] as String,
      (json['subcategories'] as List<dynamic>)
          .map((s) => Subcategory.fromJson(s))
          .toList(),
    );
  }
}

class Subcategory {
  String name;
  double openingBalance;
  double wage;
  String position;

  Subcategory(this.name, this.openingBalance, this.wage, this.position);

  Map<String, dynamic> toJson() => {
        'name': name,
        'openingBalance': openingBalance,
        'wage': wage,
        'position': position
      };

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      json['name'] as String,
      json['openingBalance'] as double,
      json['wage'] as double,
      json['position'] as String,
    );
  }
}
