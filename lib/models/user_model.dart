class UserModel {
  final int id;
  final String name;
  final String role;
  final String position;
  final List<CostCenter> costCenters;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.position,
    required this.costCenters,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var list = json['cost_centers'] as List;
    List<CostCenter> centers = list.map((e) => CostCenter.fromJson(e)).toList();
    return UserModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      position: json['position'],
      costCenters: centers,
    );
  }
}

class CostCenter {
  final int id;
  final String name;
  final String cost;

  CostCenter( {required this.id, required this.name, required this.cost,});

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(id: json['cost_center_id'], name: json['cost_center_name'], cost:json['regon']);
  }
}
