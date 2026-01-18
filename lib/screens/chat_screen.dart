import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/core/notification_service.dart';
import 'package:rentgo/models/message.dart';
import 'package:intl/intl.dart';
import 'package:rentgo/screens/add_review_screen.dart';

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
    NotificationService.activeRoomId = widget.roomId;
    _markAsRead();
  }

  @override
  void dispose() {
    NotificationService.activeRoomId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _firestoreService.markMessagesAsRead(widget.roomId, user.uid);
    }
  }

  void _sendMessage([String? quickText]) async {
    final user = Provider.of<User?>(context, listen: false);
    final text = quickText ?? _messageController.text.trim();
    if (user == null || text.isEmpty) return;

    if (quickText == null) _messageController.clear();

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
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));

    return Scaffold(
      backgroundColor: Colors.black, // TAM SİYAH
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black, // TAM SİYAH
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getUserProfileStream(widget.otherUserId),
          builder: (context, snapshot) {
            final otherUserData = snapshot.data?.data();
            final photoURL = otherUserData?['photoURL'];
            final displayName = otherUserData?['displayName'] ?? '...';
            final isOnline = otherUserData?['isOnline'] ?? false;

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF111111),
                  backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white24)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(
                        isOnline ? 'ÇEVRİMİÇİ' : 'ÇEVRİMDAŞI',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isOnline ? Colors.greenAccent : Colors.white24, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddReviewScreen(
                    targetUserId: widget.otherUserId,
                    targetUserName: "Kullanıcı", 
                    vehicleTitle: widget.vehicleTitle,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star_border_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildVehicleSummary(),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white10));
                
                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = Message.fromMap(messages[index]);
                    return _MessageBubble(message: msg, isMe: msg.senderId == user.uid);
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

  Widget _buildVehicleSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: widget.vehicleImage, width: 44, height: 44, fit: BoxFit.cover, errorWidget: (c,u,e) => Container(color: Colors.white10, child: const Icon(Icons.directions_car, size: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicleTitle.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text('İLAN DETAYLARINI GÖR', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A), 
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(color: Colors.white.withOpacity(0.05))
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(color: Colors.white10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isMe ? Colors.white : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(color: isMe ? Colors.black : Colors.white70, fontSize: 14, fontWeight: isMe ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: const TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
