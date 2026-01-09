import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/message.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String vehicleId;
  final String vehicleTitle;
  final String vehicleImage;
  final String ownerId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.vehicleImage,
    required this.ownerId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında mesajları okundu yap
    _markAsRead();
  }

  void _markAsRead() {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      // KARŞI TARAFIN gönderdiği mesajları okundu yapıyoruz
      _firestoreService.markMessagesAsRead(widget.roomId, user.uid);
    }
  }

  void _sendMessage() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null || _messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestoreService.sendMessage(
        roomId: widget.roomId,
        vehicleId: widget.vehicleId,
        vehicleTitle: widget.vehicleTitle,
        vehicleImage: widget.vehicleImage,
        ownerId: widget.ownerId,
        customerId: user.uid == widget.ownerId ? widget.otherUserId : user.uid,
        senderId: user.uid,
        text: text,
      );
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getUserProfileStream(widget.otherUserId),
          builder: (context, snapshot) {
            final otherUserData = snapshot.data?.data();
            final photoURL = otherUserData?['photoURL'];
            final displayName = otherUserData?['displayName'] ?? 'Yükleniyor...';
            final isOnline = otherUserData?['isOnline'] ?? false;

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent.withAlpha(30),
                      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.blueAccent)) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E293B), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                        style: TextStyle(fontSize: 11, color: isOnline ? Colors.greenAccent : Colors.white.withAlpha(50)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // Ekran açıkken yeni mesaj gelirse onu da anında okundu yap
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withAlpha(10)),
                        const SizedBox(height: 12),
                        const Text('Sohbeti başlatın!', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    try {
                      final msg = Message.fromMap(messages[index]);
                      return _MessageBubble(message: msg, isMe: msg.senderId == user.uid);
                    } catch (e) { return const SizedBox(); }
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) _sendMessage();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe 
                ? const LinearGradient(colors: [Colors.blueAccent, Color(0xFF2563EB)]) 
                : null,
              color: isMe ? null : const Color(0xFF334155),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                ),
                if (isMe) ...[
                  const SizedBox(height: 2),
                  // TİKLERİN RENGİ VE ŞEKLİ WHATSAPP TARZI YAPILDI
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? Colors.lightBlueAccent : Colors.white.withAlpha(100),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
