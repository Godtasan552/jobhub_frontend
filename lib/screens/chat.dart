import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/chat_controller.dart';
import 'package:intl/intl.dart';

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
    print('🚀 ChatScreen initState');
    _initChat();
  }

  Future<void> _initChat() async {
    print('🔄 Initializing chat...');
    
    final token = storage.read('token');
    if (token == null) {
      print('❌ No token');
      setState(() => isLoading = false);
      return;
    }

    // Setup callbacks
    chatController.onConversations = (data) {
      print('✅ Conversations callback: ${data.length} items');
      if (mounted) {
        setState(() {
          conversations = data;
          isLoading = false;
        });
      }
    };

    chatController.onUnreadCount = (count) {
      if (mounted) {
        setState(() {
          unreadCount = count;
        });
      }
    };

    // Connect socket for real-time
    chatController.connect(token);
    
    // Fetch initial data via HTTP
    await _loadConversations();
    await _loadUnreadCount();
  }

  Future<void> _loadConversations() async {
    try {
      await chatController.getConversations();
    } catch (e) {
      print('❌ Error loading conversations: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      await chatController.getUnreadCount();
    } catch (e) {
      print('❌ Error loading unread count: $e');
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Text("แชท"),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFFA3CFBB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => Icon(
            chatController.isConnected.value 
                ? Icons.wifi 
                : Icons.wifi_off,
            color: chatController.isConnected.value 
                ? Colors.white 
                : Colors.red,
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3CFBB)),
              ),
            )
          : conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, 
                        size: 64, 
                        color: Colors.grey[400]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ยังไม่มีแชท",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFA3CFBB),
                  onRefresh: () async {
                    await _loadConversations();
                    await _loadUnreadCount();
                  },
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final chat = conversations[index];
                      final otherUser = chat["otherUser"] ?? {};
                      final lastMessage = chat["lastMessage"] ?? {};
                      final unread = chat["unreadCount"] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFA3CFBB),
                            radius: 28,
                            child: Text(
                              (otherUser["name"] ?? "U")[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            otherUser["name"] ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              lastMessage["content"] ?? lastMessage["message"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (lastMessage["time"] != null || lastMessage["createdAt"] != null)
                                Text(
                                  _formatTime(lastMessage["time"] ?? lastMessage["createdAt"]),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$unread",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            final otherUserId = otherUser["id"]?.toString() ?? 
                                               otherUser["_id"]?.toString() ?? "";
                            
                            if (otherUserId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ไม่พบข้อมูล User ID')),
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
        return '${diff.inDays} วันที่แล้ว';
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
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    // Set up callbacks
    chatController.onMessages = (data) {
      if (mounted) {
        setState(() {
          messages = data.reversed.toList();
          isLoading = false;
        });
        _scrollToBottom();
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

    // Join chat
    chatController.joinChat(widget.otherUserId);
    chatController.markAsRead(widget.otherUserId);
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
    final userId = storage.read('userId');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFA3CFBB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFA3CFBB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFA3CFBB)
                      ),
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 64,
                              color: Colors.grey[400]
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "ยังไม่มีข้อความ",
                              style: TextStyle(color: Colors.grey[600]),
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
                          final fromUserId = msg["fromUserId"] is Map
                              ? msg["fromUserId"]["id"]
                              : msg["fromUserId"];
                          final isMe = fromUserId == userId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFA3CFBB)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMe ? 16 : 4),
                                  bottomRight:
                                      Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg["message"] ?? "",
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (msg["createdAt"] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(
                                        DateTime.parse(msg["createdAt"]),
                                      ),
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "พิมพ์ข้อความ...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFA3CFBB), Color(0xFF8BC0A8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ChatDetailPage ต่อในข้อความถัดไป...