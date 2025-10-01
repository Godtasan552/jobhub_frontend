// lib/screens/debug_notification.dart
// หน้านี้ใช้สำหรับ Debug เท่านั้น

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DebugNotificationScreen extends StatefulWidget {
  const DebugNotificationScreen({super.key});

  @override
  State<DebugNotificationScreen> createState() => _DebugNotificationScreenState();
}

class _DebugNotificationScreenState extends State<DebugNotificationScreen> {
  String _response = 'กดปุ่มเพื่อทดสอบ API';
  bool _loading = false;

  Future<void> testNotificationAPI() async {
    setState(() {
      _loading = true;
      _response = 'กำลังเรียก API...';
    });

    try {
      final storage = GetStorage();
      final token = storage.read('token');
      final user = storage.read('user'); // ✅ เพิ่มบรรทัดนี้
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
      
      print('🧪 Testing Notification API');
      print('   Base URL: $baseUrl');
      print('   Token: ${token != null ? "EXISTS" : "NULL"}');
      print('   User: $user'); // ✅ แสดง user info

      final url = Uri.parse('$baseUrl/api/v1/notifications');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('   Calling: $url');
      
      final response = await http.get(url, headers: headers);
      
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final data = json.decode(response.body);
      final prettyJson = JsonEncoder.withIndent('  ').convert(data);

      setState(() {
        _response = '''
📊 API Response Debug
━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Current User:
${user != null ? JsonEncoder.withIndent('  ').convert(user) : 'NULL'}

━━━━━━━━━━━━━━━━━━━━━━━━━━
Status Code: ${response.statusCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 JSON Response:
$prettyJson

━━━━━━━━━━━━━━━━━━━━━━━━━━
Count: ${data['data']?.length ?? 0} notifications
Total in DB: ${data['pagination']?['total'] ?? 0}
━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 วิธีแก้:
1. Copy userId ด้านบน
2. สร้าง notification ใน MongoDB
3. ใส่ userId ที่ copy มา
━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _response = '❌ Error:\n$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Debug Notification API'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _loading ? null : testNotificationAPI,
              icon: _loading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.bug_report),
              label: Text(_loading ? 'กำลังทดสอบ...' : 'ทดสอบ API'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _response,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}