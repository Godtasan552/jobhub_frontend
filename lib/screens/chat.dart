// chat.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../controllers/chat_controller.dart';

final String BASE_URL = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final storage = GetStorage();
  final ChatController _chatController = ChatController();

  List conversations = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    final token = storage.read('token');
    if (token != null) _chatController.connect(token);

    _chatController.onConversations = (data) {
      setState(() => conversations = data);
    };

    fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    final token = storage.read('token');
    print(token);
    if (token == null) return;

    try {
      final url = Uri.parse("$BASE_URL/api/v1/chat/unread-count");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });
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
  void dispose() {
    _chatController.disconnect();
    super.dispose();
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
      if (diff.inDays == 1) return 'เมื่อวาน';
      if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
      return DateFormat('dd/MM').format(date);
    } catch (e) {
      return '';
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
      body: RefreshIndicator(
        color: const Color(0xFFA3CFBB),
        onRefresh: () async {
          _chatController.getConversations();
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
                    (otherUser["firstName"] ?? "U")[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  "${otherUser["firstName"] ?? ""} ${otherUser["lastName"] ?? ""}",
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
                        otherUserId: otherUser["_id"] ?? "",
                        otherUserName:
                            "${otherUser["firstName"] ?? ""} ${otherUser["lastName"] ?? ""}",
                        chatController: _chatController,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ======================== Chat Detail Page ========================

class ChatDetailPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final ChatController chatController;

  const ChatDetailPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.chatController,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final storage = GetStorage();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List messages = [];

  bool isSending = false;

  @override
  void initState() {
    super.initState();

    widget.chatController.joinChat(widget.otherUserId);

    widget.chatController.onMessages = (data) {
      setState(() {
        messages = data;
      });
      scrollToBottom();
    };

    widget.chatController.onMessage = (msg) {
      setState(() {
        messages.add(msg);
      });
      scrollToBottom();
    };
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);
    widget.chatController.sendMessage(widget.otherUserId, text);
    messageController.clear();
    setState(() => isSending = false);
  }

  Future<void> markAsRead() async {
    final token = storage.read("token");
    if (token == null) return;

    final url = Uri.parse("$BASE_URL/api/v1/chat/mark-read");
    await http.post(url,
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        body: json.encode({"otherUserId": widget.otherUserId}));
  }

  @override
  void dispose() {
    markAsRead();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = storage.read("userId");

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
                style: const TextStyle(color: Color(0xFFA3CFBB), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.otherUserName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: const Color(0xFFA3CFBB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      "ยังไม่มีข้อความ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final fromUserId = msg["fromUserId"] is Map ? msg["fromUserId"]["id"] : msg["fromUserId"];
                      final isMe = fromUserId == userId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFA3CFBB) : Colors.white,
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
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                              ),
                              if (msg["createdAt"] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(DateTime.parse(msg["createdAt"])),
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey[500],
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFA3CFBB), Color(0xFF8BC0A8)]),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
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
