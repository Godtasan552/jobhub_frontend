import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 🔹 ตั้งค่า API และ Token (ใส่ token จริงของคุณ)
const String baseUrl = "http://your-api.com/api/v1/chat";
const String token = "<YOUR_REAL_TOKEN>";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List conversations = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    fetchConversations();
    fetchUnreadCount();
  }

  // 🔹 ดึงรายชื่อแชททั้งหมด
  Future<void> fetchConversations() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse("$baseUrl/conversations");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          conversations = data["data"] ?? []; // ตรวจสอบ response ของคุณ
          isLoading = false;
        });
      } else {
        debugPrint("❌ fetchConversations Error: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ fetchConversations Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🔹 ดึงจำนวนข้อความที่ยังไม่อ่าน
  Future<void> fetchUnreadCount() async {
    try {
      final url = Uri.parse("$baseUrl/unread-count");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unreadCount = data["unreadCount"] ?? 0;
        });
      } else {
        debugPrint("❌ fetchUnreadCount Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ fetchUnreadCount Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats ($unreadCount unread)"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? const Center(child: Text("No chats available"))
              : RefreshIndicator(
                  onRefresh: () async {
                    await fetchConversations();
                    await fetchUnreadCount();
                  },
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final chat = conversations[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(chat["otherUserName"] ?? "Unknown"),
                        subtitle: Text(chat["lastMessage"] ?? ""),
                        trailing: (chat["unreadCount"] ?? 0) > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Text(
                                  "${chat["unreadCount"]}",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
                                otherUserId: chat["otherUserId"],
                                otherUserName:
                                    chat["otherUserName"] ?? "User",
                              ),
                            ),
                          ).then((_) {
                            // โหลดใหม่หลังกลับมา
                            fetchConversations();
                            fetchUnreadCount();
                          });
                        },
                      );
                    },
                  ),
                ),
    );
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
  List messages = [];
  bool isLoading = true;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  // 🔹 ดึงข้อความในแชท
  Future<void> fetchMessages() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse("$baseUrl/conversations/${widget.otherUserId}");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages = data["data"] ?? []; // ปรับให้ตรง response
          isLoading = false;
        });

        // ทำเครื่องหมายว่าอ่านข้อความแล้ว
        markMessagesAsRead(data["data"] ?? []);
      } else {
        debugPrint("❌ fetchMessages Error: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ fetchMessages Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🔹 ส่งข้อความ
  Future<void> sendMessage() async {
    if (messageController.text.isEmpty) return;

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
          "jobId": null, // หรือใส่ jobId ถ้ามี
          "message": messageController.text,
          "messageType": "text"
        }),
      );

      if (response.statusCode == 200) {
        messageController.clear();
        fetchMessages(); // โหลดใหม่หลังส่ง
      } else {
        debugPrint("❌ sendMessage Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ sendMessage Exception: $e");
    }
  }

  // 🔹 Mark as Read
  Future<void> markMessagesAsRead(List<dynamic> data) async {
    final unreadIds = data
        .where((msg) => msg["isRead"] == false && msg["isMe"] == false)
        .map((msg) => msg["_id"])
        .toList();

    if (unreadIds.isEmpty) return;

    try {
      final url = Uri.parse("$baseUrl/mark-read");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode({"messageIds": unreadIds}),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ markMessagesAsRead Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ markMessagesAsRead Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text("No messages"))
                    : ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg["isMe"] ?? false;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg["message"] ?? "",
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
