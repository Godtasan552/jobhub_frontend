import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final storage = GetStorage();

  static final String BASE_URL =
      dotenv.env['BASE_URL'] ?? 'http://localhost:5000';
  static final String baseUrl = '$BASE_URL/api/v1';

  bool _isLoading = false;
  double _balance = 0.0;
  double _totalEarned = 0.0;
  double _totalSpent = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<String?> _getToken() async {
    return storage.read('token');
  }

  // ดึงข้อมูล Wallet
  // 1.// แก้ไขฟังก์ชัน _loadWalletData
  Future<void> _loadWalletData() async {
  setState(() => _isLoading = true);
  
  final token = await _getToken();
  if (token == null) {
    Get.snackbar('Error', 'กรุณาเข้าสู่ระบบ');
    setState(() => _isLoading = false);
    return;
  }

  try {
    final balanceResponse = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final transactionsResponse = await http.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (balanceResponse.statusCode == 200 && transactionsResponse.statusCode == 200) {
      final balanceData = json.decode(balanceResponse.body);
      final transactionsData = json.decode(transactionsResponse.body);
      
      final transactions = transactionsData['data'] ?? [];
      
      double calculatedEarned = 0.0;
      double calculatedSpent = 0.0;
      final userId = storage.read('userId');
      
      for (var transaction in transactions) {
        final amount = (transaction['amount'] ?? 0).toDouble();
        final type = transaction['type'] ?? '';
        final description = (transaction['description'] ?? '').toLowerCase();
        final from = transaction['from'];
        final to = transaction['to'];
        
        bool isIncome = false;
        
        // 1. เช็คจาก description ก่อน (สำหรับเติมเงิน/ถอนเงิน ที่ไม่มี from/to)
        if (description.contains('เติมเงิน') || 
            description.contains('top-up') || 
            description.contains('wallet top-up') ||
            description.contains('add fund') ||
            description.contains('deposit')) {
          isIncome = true;
          print('Found income (add-funds): $description, amount: $amount');
        } else if (description.contains('ถอนเงิน') || 
                   description.contains('withdraw')) {
          isIncome = false;
          print('Found expense (withdraw): $description, amount: $amount');
        }
        // 2. เช็คจาก from/to (สำหรับโอนเงิน)
        else if (userId != null && userId.toString().isNotEmpty) {
          if (to != null && to.toString() == userId.toString()) {
            isIncome = true; // เราเป็นผู้รับ
            print('Found income (received): $description, amount: $amount');
          } else if (from != null && from.toString() == userId.toString()) {
            isIncome = false; // เราเป็นผู้ส่ง
            print('Found expense (sent): $description, amount: $amount');
          }
        }
        // 3. เช็คจาก type
        else if (type == 'refund' || type == 'bonus') {
          isIncome = true;
        } else if (type == 'job_payment' || 
                   type == 'milestone_payment' || 
                   type == 'payroll') {
          isIncome = false;
        }
        
        // เพิ่มเข้ายอดรวม
        if (isIncome) {
          calculatedEarned += amount;
        } else {
          calculatedSpent += amount;
        }
      }

      setState(() {
        _balance = (balanceData['data']['balance'] ?? 0).toDouble();
        _totalEarned = calculatedEarned;
        _totalSpent = calculatedSpent;
        _transactions = transactions;
        _isLoading = false;
      });
      
      print('=== Summary ===');
      print('Balance: $_balance');
      print('Total Earned: $calculatedEarned');
      print('Total Spent: $calculatedSpent');
      print('Transactions: ${transactions.length}');
    }
  } catch (e) {
    print('Error loading wallet: $e');
    Get.snackbar('Error', 'ไม่สามารถโหลดข้อมูลได้');
    setState(() => _isLoading = false);
  }
}

  void _showAddFundsDialog() {
    final amountController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('เติมเงินเข้ากระเป๋า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (บาท)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ใช้บัตรจำลอง (mock_card)',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'กรุณากรอกจำนวนเงินที่ถูกต้อง');
                return;
              }
              Get.back();
              await _addFunds(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA3CFBB),
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFunds(double amount) async {
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/add-funds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount, 'paymentMethod': 'mock_card'}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        Get.snackbar(
          'สำเร็จ',
          'เติมเงิน $amount บาท เรียบร้อย',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );
        _loadWalletData();
      } else {
        Get.snackbar('Error', data['message'] ?? 'เติมเงินไม่สำเร็จ');
      }
    } catch (e) {
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  // 2. โอนเงิน
  void _showSendPaymentDialog() {
    final userIdController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('โอนเงินให้ผู้ใช้'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID ผู้รับ',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน (บาท)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุ (ไม่บังคับ)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              final amount = double.tryParse(amountController.text);

              if (userId.isEmpty) {
                Get.snackbar('Error', 'กรุณากรอก User ID');
                return;
              }
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'กรุณากรอกจำนวนเงินที่ถูกต้อง');
                return;
              }
              if (amount > _balance) {
                Get.snackbar('Error', 'ยอดเงินไม่เพียงพอ');
                return;
              }

              Get.back();
              await _sendPayment(
                userId,
                amount,
                descriptionController.text.trim().isEmpty
                    ? 'โอนเงิน'
                    : descriptionController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA3CFBB),
            ),
            child: const Text('โอนเงิน'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPayment(
    String toUserId,
    double amount,
    String description,
  ) async {
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/send-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'toUserId': toUserId,
          'amount': amount,
          'description': description,
          'type': 'bonus',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        Get.snackbar(
          'สำเร็จ',
          'โอนเงิน $amount บาท เรียบร้อย',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );
        _loadWalletData();
      } else {
        Get.snackbar('Error', data['message'] ?? 'โอนเงินไม่สำเร็จ');
      }
    } catch (e) {
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  // 3. ถอนเงิน
  void _showWithdrawDialog() {
    final amountController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('ถอนเงินจากกระเป๋า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (บาท)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ยอดคงเหลือ: ${_balance.toStringAsFixed(2)} บาท',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'กรุณากรอกจำนวนเงินที่ถูกต้อง');
                return;
              }
              if (amount > _balance) {
                Get.snackbar('Error', 'ยอดเงินไม่เพียงพอ');
                return;
              }
              Get.back();
              await _withdraw(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('ถอนเงิน'),
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw(double amount) async {
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/withdraw'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'bankAccountId': 'bank_01', // Mock
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        Get.snackbar(
          'สำเร็จ',
          'ถอนเงิน $amount บาท เรียบร้อย',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );
        _loadWalletData();
      } else {
        Get.snackbar('Error', data['message'] ?? 'ถอนเงินไม่สำเร็จ');
      }
    } catch (e) {
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('กระเป๋าเงิน'),
        backgroundColor: const Color(0xFFA3CFBB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3CFBB)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFA3CFBB), Color(0xFF8BC0A8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'ยอดเงินคงเหลือ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '฿${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                'รายรับ',
                                _totalEarned,
                                Icons.arrow_downward,
                                Colors.white70,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white30,
                              ),
                              _buildStatItem(
                                'รายจ่าย',
                                _totalSpent,
                                Icons.arrow_upward,
                                Colors.white70,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action Cards
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionCard(
                                    'เติมเงิน',
                                    Icons.add_circle_outline,
                                    Colors.green,
                                    _showAddFundsDialog,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionCard(
                                    'โอนเงิน',
                                    Icons.send,
                                    Colors.blue,
                                    _showSendPaymentDialog,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildActionCard(
                              'ถอนเงิน',
                              Icons.account_balance,
                              Colors.orange,
                              _showWithdrawDialog,
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Transactions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ประวัติธุรกรรม',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _transactions.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'ยังไม่มีธุรกรรม',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _transactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction = _transactions[index];
                                    return _buildTransactionItem(transaction);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '฿${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: fullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

Widget _buildTransactionItem(Map<String, dynamic> transaction) {
  final type = transaction['type'] ?? '';
  final amount = (transaction['amount'] ?? 0).toDouble();
  final description = transaction['description'] ?? type;
  final from = transaction['from'];
  final to = transaction['to'];
  
  final createdAt = transaction['createdAt'] != null
      ? DateTime.parse(transaction['createdAt'])
      : DateTime.now();
  
  final userId = storage.read('userId');
  
  bool isIncome = false;
  String displayDescription = description;
  
  // 1. เช็คจาก description (เติมเงิน/ถอนเงิน)
  final desc = description.toLowerCase();
  if (desc.contains('wallet top-up') || 
      desc.contains('เติมเงิน') || 
      desc.contains('deposit')) {
    isIncome = true;
    displayDescription = 'เติมเงินเข้า';
  } else if (desc.contains('wallet withdrawal') ||
             desc.contains('ถอนเงิน') || 
             desc.contains('withdraw')) {
    isIncome = false;
    displayDescription = 'ถอนเงิน';
  }
  // 2. เช็คจาก from/to (โอนเงิน)
  else if (from != null && to != null) {
    final fromId = from is Map ? from['id'] : from.toString();
    final toId = to is Map ? to['id'] : to.toString();
    
    if (userId != null) {
      final userIdStr = userId.toString();
      
      if (toId == userIdStr) {
        isIncome = true;
        displayDescription = 'ได้รับเงินโอน';
      } else if (fromId == userIdStr) {
        isIncome = false;
        displayDescription = 'โอนเงินออก';
      } else {
        // ถ้าไม่ใช่ทั้งผู้ส่งและผู้รับ (กรณีดูข้อมูลคนอื่น)
        displayDescription = 'การโอนเงิน';
      }
    } else {
      // ถ้า userId เป็น null ให้เช็คจาก type แทน
      if (type == 'bonus') {
        isIncome = true;
        displayDescription = 'โบนัส/รับเงิน';
      } else {
        isIncome = false;
        displayDescription = 'โอนเงิน';
      }
    }
  }
  // 3. เช็คจาก type อื่นๆ
  else if (type == 'refund') {
    isIncome = true;
    displayDescription = 'คืนเงิน';
  } else if (type == 'bonus') {
    isIncome = true;
    displayDescription = 'โบนัส';
  } else if (type == 'job_payment') {
    isIncome = false;
    displayDescription = 'จ่ายเงินค่างาน';
  }
  
  final color = isIncome ? Colors.green : Colors.red;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey[200]!),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        displayDescription,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}฿${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
}
