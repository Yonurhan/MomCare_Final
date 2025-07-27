// lib/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String createdAt;
  
  // Added fields to match your backend and new UI needs
  final int? age;
  final int? height;
  final int? weight;
  final String? dueDate;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.age,
    this.height,
    this.weight,
    this.dueDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      createdAt: json['created_at'],
      age: json['age'],
      height: json['height'],
      weight: json['weight'],
      dueDate: json['due_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt,
      'age': age,
      'height': height,
      'weight': weight,
      'due_date': dueDate,
    };
  }
}