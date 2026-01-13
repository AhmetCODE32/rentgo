import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/core/notification_service.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: false,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getUserProfileStream(widget.otherUserId),
          builder: (context, snapshot) {
            final otherUserData = snapshot.data?.data();
            final photoURL = otherUserData?['photoURL'];
            final displayName = otherUserData?['displayName'] ?? '...';
            final isOnline = otherUserData?['isOnline'] ?? false;
            final bool isPremium = otherUserData?['isPremium'] ?? false;

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
          _buildQuickActions(user!.uid),
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
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: widget.vehicleImage, width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.vehicleTitle.toUpperCase(), 
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getUserProfileStream(uid),
      builder: (context, snapshot) {
        final isPremium = snapshot.data?.data()?['isPremium'] ?? false;
        if (!isPremium) return const SizedBox.shrink();

        final quickMessages = ['Hala kiralık mı?', 'İndirim olur mu?', 'Konum atar mısınız?'];

        return Container(
          height: 45,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: quickMessages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(quickMessages[index], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  backgroundColor: const Color(0xFF0A0A0A),
                  side: const BorderSide(color: Colors.white10),
                  onPressed: () => _sendMessage(quickMessages[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
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
              padding: const EdgeInsets.all(12),
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.white : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16),
              border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(color: isMe ? Colors.black : Colors.white70, fontSize: 14, fontWeight: isMe ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
