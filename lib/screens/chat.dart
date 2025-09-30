import 'package:flutter/material.dart';

class Chatsceen extends StatefulWidget {
  const Chatsceen({super.key});

  @override
  State<Chatsceen> createState() => _ChatsceenState();
}

class _ChatsceenState extends State<Chatsceen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("No new Chat"),
      ),
    );
  }
}