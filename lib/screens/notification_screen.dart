import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../model/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    final unreadIds = provider.notifications
                        .where((n) => !n.read)
                        .map((n) => n.id)
                        .toList();
                    if (unreadIds.isNotEmpty) {
                      provider.markAsRead(unreadIds);
                    }
                  },
                  child: const Text('อ่านทั้งหมด'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotificationProvider>().loadNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ไม่มีการแจ้งเตือน', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () {
                    if (!notification.read) {
                      provider.markAsRead([notification.id]);
                    }
                    // นำทางไปหน้าที่เกี่ยวข้อง (ถ้ามี actionUrl)
                    if (notification.actionUrl != null) {
                      // TODO: นำทางตาม actionUrl
                    }
                  },
                  onDelete: () {
                    provider.deleteNotification(notification.id);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการแจ้งเตือนแล้ว')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withOpacity(0.2),
          child: Icon(_getIcon(), color: _getColor()),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.read
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        tileColor: notification.read ? null : Colors.blue.withOpacity(0.05),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}