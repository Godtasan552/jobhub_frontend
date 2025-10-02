// lib/screens/notification_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการแจ้งเตือน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: เพิ่มฟีเจอร์แชร์
              Get.snackbar('แชร์', 'ฟีเจอร์กำลังพัฒนา');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getColor().withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: _getColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      size: 48,
                      color: _getColor(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTypeLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _formatFullDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status
                  Row(
                    children: [
                      Icon(
                        notification.read ? Icons.check_circle : Icons.circle,
                        size: 16,
                        color: notification.read ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.read ? 'อ่านแล้ว' : 'ยังไม่ได้อ่าน',
                        style: TextStyle(
                          fontSize: 14,
                          color: notification.read ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Message
                  const Text(
                    'รายละเอียด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  // Reference Info
                  if (notification.referenceId != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลอ้างอิง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('ประเภท', notification.referenceType ?? '-'),
                          const SizedBox(height: 4),
                          _buildInfoRow('ID', notification.referenceId ?? '-'),
                        ],
                      ),
                    ),
                  ],

                  // Read At Info
                  if (notification.read && notification.readAt != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'อ่านเมื่อ ${_formatFullDate(notification.readAt!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action Button
                  if (notification.actionUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _handleAction(notification.actionUrl!);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('ดูรายละเอียดเพิ่มเติม'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel() {
    switch (notification.type) {
      case 'job':
        return 'งาน';
      case 'milestone':
        return 'เหตุการณ์สำคัญ';
      case 'payment':
        return 'การเงิน';
      case 'chat':
        return 'แชท';
      case 'worker_approval':
        return 'อนุมัติผู้ทำงาน';
      case 'system':
        return 'ระบบ';
      default:
        return notification.type.toUpperCase();
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'job':
        return Icons.work;
      case 'milestone':
        return Icons.flag;
      case 'payment':
        return Icons.payment;
      case 'chat':
        return Icons.chat;
      case 'worker_approval':
        return Icons.person_add;
      case 'system':
      default:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'job':
        return Colors.blue;
      case 'milestone':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'chat':
        return Colors.purple;
      case 'worker_approval':
        return Colors.teal;
      case 'system':
      default:
        return Colors.grey;
    }
  }

  String _formatFullDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm น.').format(date);
  }

  void _handleAction(String actionUrl) {
    print('🔗 Navigating to: $actionUrl');
    
    // Parse actionUrl และนำทางไปหน้าที่เหมาะสม
    if (actionUrl.contains('/jobs/')) {
      // ตัวอย่าง: /jobs/68dd6749ca052c863cd84578/applications
      final jobId = actionUrl.split('/')[2];
      Get.snackbar(
        'นำทาง',
        'ไปที่งาน ID: $jobId',
        snackPosition: SnackPosition.BOTTOM,
      );
      // TODO: Get.toNamed('/job-detail', arguments: jobId);
    } else if (actionUrl.contains('/wallet')) {
      Get.snackbar(
        'นำทาง',
        'ไปที่กระเป๋าเงิน',
        snackPosition: SnackPosition.BOTTOM,
      );
      // TODO: Get.toNamed('/wallet');
    } else {
      Get.snackbar(
        'นำทาง',
        'ไปที่: $actionUrl',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}