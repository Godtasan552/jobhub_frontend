import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/chat_controller.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final storage = GetStorage();
  final chatController = ChatController.instance;
  
  List conversations = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final token = storage.read('token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    chatController.onConversations = (data) {
      if (mounted) {
        setState(() {
          conversations = data;
          isLoading = false;
        });
      }
    };

    chatController.onUnreadCount = (count) {
      if (mounted) {
        setState(() => unreadCount = count);
      }
    };

    chatController.connect(token);
    await _loadConversations();
    await _loadUnreadCount();
  }

  Future<void> _loadConversations() async {
    try {
      await chatController.getConversations();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      await chatController.getUnreadCount();
    } catch (e) {}
  }

  @override
  void dispose() {
    chatController.onConversations = null;
    chatController.onUnreadCount = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "แชท",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF2D5F4C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => Icon(
              chatController.isConnected.value 
                  ? Icons.cloud_done_rounded 
                  : Icons.cloud_off_rounded,
              color: Colors.white,
              size: 20,
            )),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5F4C)),
                strokeWidth: 3,
              ),
            )
          : conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5F4C).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: Color(0xFF2D5F4C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "ยังไม่มีแชท",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "เริ่มสนทนากับผู้ใช้งานอื่นได้เลย",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2D5F4C),
                  onRefresh: () async {
                    await _loadConversations();
                    await _loadUnreadCount();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final chat = conversations[index];
                      final otherUser = chat["otherUser"] ?? {};
                      final lastMessage = chat["lastMessage"] ?? {};
                      final unread = chat["unreadCount"] ?? 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final otherUserId = otherUser["id"]?.toString() ?? 
                                                 otherUser["_id"]?.toString() ?? "";
                              
                              if (otherUserId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('ไม่พบข้อมูล User ID'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailPage(
                                    otherUserId: otherUserId,
                                    otherUserName: otherUser["name"] ?? "User",
                                  ),
                                ),
                              ).then((_) async {
                                await _loadConversations();
                                await _loadUnreadCount();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2D5F4C),
                                              Color(0xFF3A7D5C),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF2D5F4C).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (otherUser["name"] ?? "U")[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (unread > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                unread > 99 ? '99+' : '$unread',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                otherUser["name"] ?? "Unknown",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Color(0xFF2D3748),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (lastMessage["time"] != null || 
                                                lastMessage["createdAt"] != null)
                                              Text(
                                                _formatTime(lastMessage["time"] ?? 
                                                           lastMessage["createdAt"]),
                                                style: TextStyle(
                                                  color: unread > 0 
                                                      ? const Color(0xFF2D5F4C)
                                                      : Colors.grey[500],
                                                  fontSize: 12,
                                                  fontWeight: unread > 0 
                                                      ? FontWeight.w600 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lastMessage["content"] ?? 
                                                lastMessage["message"] ?? 
                                                "ไม่มีข้อความ",
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: unread > 0
                                                      ? const Color(0xFF2D3748)
                                                      : Colors.grey[600],
                                                  fontSize: 14,
                                                  fontWeight: unread > 0
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (unread > 0) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.circle,
                                                size: 8,
                                                color: Color(0xFF2D5F4C),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (diff.inDays == 1) {
        return 'เมื่อวาน';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} วัน';
      } else {
        return DateFormat('dd/MM').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}

class ChatDetailPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatDetailPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final storage = GetStorage();
  final chatController = ChatController.instance;
  
  List messages = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    String? userId = storage.read('userId');
    
    if (userId == null) {
      final token = storage.read('token');
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map<String, dynamic> payloadMap = jsonDecode(decoded);
            userId = payloadMap['userId']?.toString();
            
            if (userId != null) {
              storage.write('userId', userId);
              print('✅ Decoded userId: $userId');
            }
          }
        } catch (e) {
          print('❌ Error decoding token: $e');
        }
      }
    } else {
      print('✅ Found userId in storage: $userId');
    }
    
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }
      });
      
      setState(() {
        isLoading = false;
        errorMessage = 'ไม่พบข้อมูลผู้ใช้';
      });
      return;
    }

    chatController.onMessages = (data) {
      if (mounted) {
        setState(() {
          messages = List.from(data);
          
          if (messages.isNotEmpty) {
            try {
              final firstDate = DateTime.parse(messages.first['createdAt']);
              final lastDate = DateTime.parse(messages.last['createdAt']);
              
              if (firstDate.isAfter(lastDate)) {
                messages = messages.reversed.toList();
              }
            } catch (e) {}
          }
          
          isLoading = false;
        });
        
        _scrollToBottom();
        _markMessagesAsRead();
      }
    };

    chatController.onMessage = (data) {
      if (mounted) {
        setState(() {
          messages.add(data);
        });
        _scrollToBottom();
      }
    };

    chatController.joinChat(widget.otherUserId);
    _loadMessages();
  }

  void _markMessagesAsRead() {
    try {
      final userId = storage.read('userId')?.toString();
      if (userId == null) return;
      
      final unreadMessageIds = <String>[];
      
      for (var msg in messages) {
        String? fromUserId;
        if (msg["fromUserId"] is Map) {
          fromUserId = msg["fromUserId"]["_id"]?.toString() ?? 
                      msg["fromUserId"]["id"]?.toString();
        } else {
          fromUserId = msg["fromUserId"]?.toString();
        }
        
        final messageId = msg["_id"]?.toString() ?? msg["id"]?.toString();
        
        if (fromUserId != null && 
            fromUserId != userId && 
            msg["read"] == false &&
            messageId != null) {
          unreadMessageIds.add(messageId);
        }
      }
      
      if (unreadMessageIds.isNotEmpty) {
        chatController.markAsRead(widget.otherUserId, unreadMessageIds);
      }
    } catch (e) {}
  }

  Future<void> _loadMessages() async {
    try {
      await chatController.getMessages(widget.otherUserId);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อความ';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (messageController.text.trim().isEmpty) return;
    
    chatController.sendMessage(
      widget.otherUserId,
      messageController.text.trim(),
    );
    
    messageController.clear();
  }

  @override
  void dispose() {
    chatController.onMessages = null;
    chatController.onMessage = null;
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = storage.read('userId')?.toString();
    
    print('🎨 Building ChatDetailPage');
    print('🔑 My userId: $userId');
    print('👤 Other userId: ${widget.otherUserId}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D5F4C), Color(0xFF3A7D5C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D5F4C).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.otherUserName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() => Text(
                    chatController.isConnected.value ? 'ออนไลน์' : 'ออฟไลน์',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D5F4C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5F4C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2D5F4C),
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      : messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D5F4C).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 64,
                                      color: Color(0xFF2D5F4C),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "ยังไม่มีข้อความ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "เริ่มต้นการสนทนาได้เลย",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                
                                String? fromUserId;
                                if (msg["fromUserId"] is Map) {
                                  fromUserId = msg["fromUserId"]["_id"]?.toString() ?? 
                                              msg["fromUserId"]["id"]?.toString();
                                } else {
                                  fromUserId = msg["fromUserId"]?.toString();
                                }
                                
                                final isFromMe = fromUserId == userId;
                                final isRead = msg["read"] == true;
                                final readAt = msg["readAt"];
                                
                                // 🔍 Debug log
                                if (index == 0) {
                                  print('🔍 DEBUG MESSAGE:');
                                  print('   My userId: $userId');
                                  print('   From userId: $fromUserId');
                                  print('   isFromMe: $isFromMe');
                                  print('   Match: ${fromUserId == userId}');
                                }
                                
                                // ตรวจสอบว่าต้องแสดง date separator หรือไม่
                                bool showDateSeparator = false;
                                if (index == 0) {
                                  showDateSeparator = true;
                                } else {
                                  final prevMsg = messages[index - 1];
                                  if (msg["createdAt"] != null && prevMsg["createdAt"] != null) {
                                    final currentDate = DateTime.parse(msg["createdAt"]);
                                    final prevDate = DateTime.parse(prevMsg["createdAt"]);
                                    
                                    if (currentDate.day != prevDate.day ||
                                        currentDate.month != prevDate.month ||
                                        currentDate.year != prevDate.year) {
                                      showDateSeparator = true;
                                    }
                                  }
                                }

                                return Column(
                                  children: [
                                    if (showDateSeparator && msg["createdAt"] != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey[300],
                                                thickness: 1,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                _formatDateSeparator(msg["createdAt"]),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey[300],
                                                thickness: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Align(
                                      alignment: isFromMe
                                          ? Alignment.centerRight  // ข้อความของเรา - ขวา
                                          : Alignment.centerLeft,  // ข้อความคนอื่น - ซ้าย
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment: isFromMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: isFromMe
                                                    ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFF2D5F4C),
                                                          Color(0xFF3A7D5C),
                                                        ],
                                                      )
                                                    : null,
                                                color: isFromMe ? null : Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(20),
                                                  topRight: const Radius.circular(20),
                                                  bottomLeft: Radius.circular(isFromMe ? 20 : 4),
                                                  bottomRight: Radius.circular(isFromMe ? 4 : 20),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.08),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                msg["message"] ?? "",
                                                style: TextStyle(
                                                  color: isFromMe
                                                      ? Colors.white
                                                      : const Color(0xFF2D3748),
                                                  fontSize: 15,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: isFromMe ? 0 : 8,
                                                right: isFromMe ? 8 : 0,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (msg["createdAt"] != null)
                                                    Text(
                                                      DateFormat('HH:mm').format(
                                                        DateTime.parse(msg["createdAt"]),
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  if (isFromMe) ...[
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      isRead
                                                          ? Icons.done_all_rounded
                                                          : Icons.done_rounded,
                                                      size: 14,
                                                      color: isRead
                                                          ? const Color(0xFF4CAF50)
                                                          : Colors.grey[500],
                                                    ),
                                                    if (isRead && readAt != null) ...[
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatReadTime(readAt),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: "พิมพ์ข้อความ...",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2D3748),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D5F4C), Color(0xFF3A7D5C)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2D5F4C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatReadTime(String readAt) {
    try {
      final readTime = DateTime.parse(readAt);
      final now = DateTime.now();
      final diff = now.difference(readTime);

      if (diff.inSeconds < 60) {
        return 'เมื่อสักครู่';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} ชั่วโมงที่แล้ว';
      } else if (diff.inDays == 1) {
        return 'เมื่อวาน ${DateFormat('HH:mm').format(readTime)}';
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(readTime);
      }
    } catch (e) {
      return '';
    }
  }

  String _formatDateSeparator(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'วันนี้ ${DateFormat('HH:mm').format(date)}';
      } else if (diff.inDays == 1) {
        return 'เมื่อวาน ${DateFormat('HH:mm').format(date)}';
      } else if (diff.inDays < 7) {
        final weekday = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
        return '${weekday[date.weekday - 1]} ${DateFormat('HH:mm').format(date)}';
      } else {
        return DateFormat('dd MMMM yyyy HH:mm', 'th').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}