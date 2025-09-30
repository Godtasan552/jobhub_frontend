// lib/models/employer_model.dart
class EmployerModel {
  final String id;
  final String name;
  final String email;
  final String? profilePic;

  EmployerModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
  });

  factory EmployerModel.fromJson(Map<String, dynamic> json) {
    return EmployerModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePic': profilePic,
    };
  }
}

// lib/models/job_model.dart
class JobModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final double budget;
  final String duration;
  final DateTime? deadline;
  final dynamic employerId; // เปลี่ยนเป็น dynamic หรือ EmployerModel
  final String? workerId;
  final String status;
  final List<String>? requirements;
  final List<String>? attachments;
  final List<String> applicants;
  final List<String>? milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.budget,
    required this.duration,
    this.deadline,
    required this.employerId,
    this.workerId,
    required this.status,
    this.requirements,
    this.attachments,
    required this.applicants,
    this.milestones,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper method เพื่อดึง employer ID
  String get employerIdString {
    if (employerId is String) {
      return employerId;
    } else if (employerId is Map<String, dynamic>) {
      return employerId['id'] ?? employerId['_id'] ?? '';
    } else if (employerId is EmployerModel) {
      return employerId.id;
    }
    return '';
  }

  // Helper method เพื่อดึง employer object
  EmployerModel? get employer {
    if (employerId is Map<String, dynamic>) {
      return EmployerModel.fromJson(employerId);
    } else if (employerId is EmployerModel) {
      return employerId;
    }
    return null;
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // จัดการ employerId ที่อาจเป็น String หรือ Object
    dynamic employerIdValue;
    if (json['employerId'] is String) {
      employerIdValue = json['employerId'];
    } else if (json['employerId'] is Map<String, dynamic>) {
      employerIdValue = EmployerModel.fromJson(json['employerId']);
    } else {
      employerIdValue = '';
    }

    return JobModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'freelance',
      category: json['category'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      duration: json['duration'] ?? '',
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      employerId: employerIdValue,
      workerId: json['workerId'],
      status: json['status'] ?? 'active',
      requirements: json['requirements'] != null 
          ? List<String>.from(json['requirements']) 
          : null,
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) 
          : null,
      applicants: json['applicants'] != null 
          ? List<String>.from(json['applicants']) 
          : [],
      milestones: json['milestones'] != null 
          ? List<String>.from(json['milestones']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'budget': budget,
      'duration': duration,
      'deadline': deadline?.toIso8601String(),
      'employerId': employerIdString, // ใช้ helper method
      'workerId': workerId,
      'status': status,
      'requirements': requirements,
      'attachments': attachments,
      'applicants': applicants,
      'milestones': milestones,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}