// lib/model/application_model.dart
class ApplicationModel {
  final String id;
  final String workerId;
  final String workerName;
  final String workerEmail;
  final String? workerProfilePic;
  final String coverLetter;
  final double proposedBudget;
  final String status;

  ApplicationModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.workerEmail,
    this.workerProfilePic,
    required this.coverLetter,
    required this.proposedBudget,
    required this.status,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing application: $json'); // เพิ่ม debug
    
    if (json['workerId'] != null && json['workerId'] is Map) {
      final worker = json['workerId'];
      return ApplicationModel(
        id: json['_id'] ?? '',
        workerId: worker['_id'] ?? worker['id'] ?? '',
        workerName: worker['name'] ?? 'ไม่ระบุชื่อ',
        workerEmail: worker['email'] ?? '',
        workerProfilePic: worker['profilePic'],
        coverLetter: json['coverLetter'] ?? 'ไม่มีข้อมูลจดหมายปะหน้า',
        proposedBudget: (json['proposedBudget'] ?? 0).toDouble(),
        status: json['status'] ?? 'pending',
      );
    } else {
      return ApplicationModel(
        id: json['_id'] ?? json['id'] ?? '',
        workerId: json['_id'] ?? json['id'] ?? '',
        workerName: json['name'] ?? 'ไม่ระบุชื่อ',
        workerEmail: json['email'] ?? '',
        workerProfilePic: json['profilePic'],
        coverLetter: 'ไม่มีข้อมูลจดหมายปะหน้า',
        proposedBudget: 0,
        status: 'pending',
      );
    }
  }
}