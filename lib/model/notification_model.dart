// lib/models/notification_model.dart

class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'job' | 'milestone' | 'payment' | 'chat' | 'system' | 'worker_approval'
  final String title;
  final String message;
  final String? referenceId;
  final String? referenceType; // 'job' | 'milestone' | 'transaction' | 'message' | 'worker_application'
  final bool read;
  final DateTime? readAt;
  final String? actionUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    required this.read,
    this.readAt,
    this.actionUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // แปลง JSON เป็น Object
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json['_id'] ?? '',
        userId: json['userId'] ?? '',
        type: json['type'] ?? 'system',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        referenceId: json['referenceId'],
        referenceType: json['referenceType'],
        read: json['read'] ?? false,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
        actionUrl: json['actionUrl'],
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing notification: $e');
      print('   JSON data: $json');
      rethrow;
    }
  }

  // แปลง Object เป็น JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'read': read,
      'readAt': readAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // สำหรับแสดงเวลาในรูปแบบที่อ่านง่าย
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  // ไอคอนตามประเภท
  String get iconType {
    switch (type) {
      case 'job':
        return '💼';
      case 'milestone':
        return '🎯';
      case 'payment':
        return '💰';
      case 'chat':
        return '💬';
      case 'worker_approval':
        return '✅';
      case 'system':
      default:
        return '🔔';
    }
  }

  // คัดลอกและแก้ไขค่า
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? referenceId,
    String? referenceType,
    bool? read,
    DateTime? readAt,
    String? actionUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}