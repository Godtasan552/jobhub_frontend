// lib/models/job_model.dart
class JobModel {
  final String id;
  final String title;
  final String description;
  final String type; // freelance, part-time, contract, full-time
  final String category;
  final double budget;
  final String duration;
  final DateTime? deadline;
  final String employerId;
  final String? workerId;
  final String status; // active, closed, in_progress, completed, cancelled
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

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'freelance',
      category: json['category'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      duration: json['duration'] ?? '',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      employerId: json['employerId'] ?? '',
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
      'employerId': employerId,
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