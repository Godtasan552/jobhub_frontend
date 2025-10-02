import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  static final String BASE_URL = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';
  final storage = GetStorage();
  static final String baseUrl = '$BASE_URL/api/v1/chat';
  
  List conversations = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    fetchConversations();
    fetchUnreadCount();
  }

  Future<String?> _getToken() async {
    return storage.read('token');
  }

  Future<void> fetchConversations() async {
    setState(() => isLoading = true);
    
    final token = await _getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/conversations");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('Conversations Response: ${response.statusCode}');
      print('Conversations Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          conversations = data["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetchConversations: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUnreadCount() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final url = Uri.parse("$baseUrl/unread-count");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unreadCount = data["data"]?["unreadCount"] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetchUnreadCount: $e");
    }
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
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
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
                    await fetchConversations();
                    await fetchUnreadCount();
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
                              lastMessage["message"] ?? "",
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
                              if (lastMessage["createdAt"] != null)
                                Text(
                                  _formatTime(lastMessage["createdAt"]),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  otherUserId: otherUser["id"] ?? "",
                                  otherUserName: otherUser["name"] ?? "User",
                                ),
                              ),
                            ).then((_) {
                              fetchConversations();
                              fetchUnreadCount();
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

// ============================================
// Chat Detail Page
// ============================================

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
  final String baseUrl = 'https://jobhubbackend-production-cc57.up.railway.app/api/v1/chat';
  
  List messages = [];
  bool isLoading = true;
  bool isSending = false;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return storage.read('token');
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);
    
    final token = await _getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/conversations/${widget.otherUserId}");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('Messages Response: ${response.statusCode}');
      print('Messages Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages = (data["data"] ?? []).reversed.toList();
          isLoading = false;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });

        // Mark as read
        markMessagesAsRead();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetchMessages: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final token = await _getToken();
    if (token == null) return;

    setState(() => isSending = true);

    try {
      final url = Uri.parse("$baseUrl/send");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode({
          "toUserId": widget.otherUserId,
          "message": messageController.text.trim(),
        }),
      );

      print('Send Message Response: ${response.statusCode}');
      print('Send Message Body: ${response.body}');

      if (response.statusCode == 200) {
        messageController.clear();
        await fetchMessages();
      }
    } catch (e) {
      print("Error sendMessage: $e");
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> markMessagesAsRead() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final url = Uri.parse("$baseUrl/mark-read");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode({
          "otherUserId": widget.otherUserId,
        }),
      );

      print('Mark Read Response: ${response.statusCode}');
    } catch (e) {
      print("Error markMessagesAsRead: $e");
    }
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3CFBB)),
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
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
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg["message"] ?? "",
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
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
                    onSubmitted: (_) => sendMessage(),
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
                    icon: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: isSending ? null : sendMessage,
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