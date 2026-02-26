class Warehouse {
  final String id;
  final String name;
  final String location;

  Warehouse({
    required this.id,
    required this.name,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
    );
  }
}
